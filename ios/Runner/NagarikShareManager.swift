import Flutter
import UIKit
import MultipeerConnectivity
import Network

class NagarikShareManager: NSObject, FlutterPlugin, FlutterStreamHandler {
    static let METHOD_CHANNEL = "nagarik.share.connection"
    static let EVENT_CHANNEL = "nagarik.share.events"
    
    private var methodChannel: FlutterMethodChannel?
    private var eventChannel: FlutterEventChannel?
    private var eventSink: FlutterEventSink?
    
    // MultipeerConnectivity
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    private var myPeerId: MCPeerID!
    
    // TCP Server/Client for file transfer
    private var serverSocket: ListenerSocket?
    private var serverPort: Int = 8888
    private var activeTransfer: FileTransfer?
    
    // State
    private var connectedPeers: [MCPeerID] = []
    private var isReceiving = false
    
    private static var instance: NagarikShareManager?
    
    override init() {
        super.init()
        let deviceName = UIDevice.current.name
        myPeerId = MCPeerID(displayName: deviceName)
    }
    
    static func register(with registrar: FlutterPluginRegistrar) {
        guard self.instance == nil else { return }

        let instance = NagarikShareManager()
        self.instance = instance
        
        instance.methodChannel = FlutterMethodChannel(
            name: METHOD_CHANNEL,
            binaryMessenger: registrar.messenger()
        )
        instance.eventChannel = FlutterEventChannel(
            name: EVENT_CHANNEL,
            binaryMessenger: registrar.messenger()
        )
        
        registrar.addMethodCallDelegate(instance, channel: instance.methodChannel!)
        instance.eventChannel?.setStreamHandler(instance)
    }
    
    // MARK: - Flutter Method Channel
    
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            initialize(result: result)
        case "discoverDevices":
            discoverDevices(result: result)
        case "stopDiscovery":
            stopDiscovery(result: result)
        case "connectDevice":
            if let deviceId = call.arguments as? String {
                connectDevice(deviceId: deviceId, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "deviceId required", details: nil))
            }
        case "createHotspot":
            // iOS doesn't support programmatic hotspot creation
            // Return info for manual hotspot setup
            result([
                "ssid": "NagarikShare",
                "password": "nagarik123",
                "gatewayIp": "192.168.43.1",
                "port": serverPort
            ])
        case "connectToWifi":
            // iOS doesn't support programmatic Wi-Fi connection
            result(false)
        case "startReceiving":
            startReceiving(result: result)
        case "sendFile":
            if let args = call.arguments as? [String: Any],
               let fileId = args["fileId"] as? String,
               let filePath = args["filePath"] as? String,
               let receiverIp = args["receiverIp"] as? String {
                let port = args["port"] as? Int ?? 8888
                sendFile(fileId: fileId, filePath: filePath, receiverIp: receiverIp, port: port, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing required arguments", details: nil))
            }
        case "cancelTransfer":
            cancelTransfer(result: result)
        case "disconnect":
            disconnect(result: result)
        case "getConnectionInfo":
            getConnectionInfo(result: result)
        case "checkHardwareState":
            checkHardwareState(result: result)
        case "requestSharePermissions":
            // iOS permissions handled via Info.plist
            result(true)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - Flutter Event Channel
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
    
    // MARK: - Implementation
    
    private func initialize(result: @escaping FlutterResult) {
        session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .none)
        session?.delegate = self
        result(nil)
    }
    
    private func discoverDevices(result: @escaping FlutterResult) {
        emit("searching", [:])
        
        // Start advertising
        advertiser = MCNearbyServiceAdvertiser(
            peer: myPeerId,
            discoveryInfo: ["service": "nagarikshare"],
            serviceType: "nagarikshare"
        )
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        
        // Start browsing
        browser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: "nagarikshare")
        browser?.delegate = self
        browser?.startBrowsingForPeers()
        
        result(nil)
    }
    
    private func stopDiscovery(result: @escaping FlutterResult) {
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        advertiser = nil
        browser = nil
        result(nil)
    }
    
    private func connectDevice(deviceId: String, result: @escaping FlutterResult) {
        emit("connecting", ["deviceId": deviceId])
        
        // Find peer by ID
        if let peer = session?.connectedPeers.first(where: { $0.displayName == deviceId }) {
            // Already connected
            emit("deviceConnected", [
                "deviceId": deviceId,
                "ipAddress": getLocalIPAddress(),
                "port": serverPort
            ])
            result(nil)
            return
        }
        
        // Try to connect via browser if we found this peer
        // For now, we'll emit connected if we have any connected peers
        if let firstPeer = session?.connectedPeers.first {
            emit("deviceConnected", [
                "deviceId": firstPeer.displayName,
                "ipAddress": getLocalIPAddress(),
                "port": serverPort
            ])
        }
        result(nil)
    }
    
    private func startReceiving(result: @escaping FlutterResult) {
        isReceiving = true
        serverSocket = ListenerSocket()
        serverSocket?.startListening(onPort: serverPort) { [weak self] port in
            self?.serverPort = port
            self?.emit("serverStarted", ["port": port])
        }
        // Return immediately with the port
        result(["port": serverPort])
    }
    
    private func sendFile(fileId: String, filePath: String, receiverIp: String, port: Int, result: @escaping FlutterResult) {
        let fileUrl = URL(fileURLWithPath: filePath)
        
        activeTransfer = FileTransfer(fileId: fileId, fileUrl: fileUrl, receiverIp: receiverIp, port: port)
        activeTransfer?.delegate = self
        activeTransfer?.start()
        
        result(nil)
    }
    
    private func cancelTransfer(result: @escaping FlutterResult) {
        activeTransfer?.cancel()
        serverSocket?.stop()
        isReceiving = false
        result(nil)
    }
    
    private func disconnect(result: @escaping FlutterResult) {
        cancelTransfer(result: { _ in })
        session?.disconnect()
        stopDiscovery(result: { _ in })
        connectedPeers.removeAll()
        emit("disconnected", [:])
        result(nil)
    }
    
    private func getConnectionInfo(result: @escaping FlutterResult) {
        result([
            "ipAddress": getLocalIPAddress(),
            "port": serverPort,
            "isHotspot": false,
            "serverPort": serverPort
        ])
    }
    
    private func checkHardwareState(result: @escaping FlutterResult) {
        result([
            "isWifiEnabled": true,
            "isHotspotEnabled": false,
            "isBluetoothEnabled": true,
            "isLocationEnabled": true,
            "hasPermissions": true
        ])
    }
    
    // MARK: - Helpers
    
    private func emit(_ type: String, _ data: [String: Any?]) {
        DispatchQueue.main.async {
            var payload = data
            payload["type"] = type
            self.eventSink?(payload)
        }
    }
    
    private func getLocalIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        guard let firstAddr = ifaddr else { return nil }
        
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family
            
            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                if name == "en0" { // Wi-Fi interface
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                              &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
        }
        
        freeifaddrs(ifaddr)
        return address
    }
}

// MARK: - MCSessionDelegate

extension NagarikShareManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:
            connectedPeers.append(peerID)
            emit("deviceConnected", [
                "deviceId": peerID.displayName,
                "ipAddress": getLocalIPAddress(),
                "port": serverPort
            ])
        case .notConnected:
            connectedPeers.removeAll { $0 == peerID }
            emit("deviceLost", ["deviceId": peerID.displayName])
        case .connecting:
            break
        @unknown default:
            break
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        // Handle data received from peer
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // Handle stream received from peer
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        // Handle resource receiving
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        // Handle resource received
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension NagarikShareManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // Auto-accept invitations for demo purposes
        invitationHandler(true, session)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        emit("connectionFailed", ["reason": error.localizedDescription])
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension NagarikShareManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        emit("deviceFound", [
            "deviceId": peerID.displayName,
            "deviceName": peerID.displayName,
            "connectionType": "Multipeer",
            "ipAddress": nil
        ])
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        emit("deviceLost", ["deviceId": peerID.displayName])
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        emit("connectionFailed", ["reason": error.localizedDescription])
    }
}

// MARK: - File Transfer

protocol FileTransferDelegate: AnyObject {
    func transferDidStart()
    func transferDidProgress(progress: Double, speedBps: Double)
    func transferDidComplete(success: Bool)
    func transferDidFail(error: String)
}

class FileTransfer {
    let fileId: String
    private let fileUrl: URL
    private let receiverIp: String
    private let port: Int
    private var connection: NWConnection?
    weak var delegate: FileTransferDelegate?
    
    init(fileId: String, fileUrl: URL, receiverIp: String, port: Int) {
        self.fileId = fileId
        self.fileUrl = fileUrl
        self.receiverIp = receiverIp
        self.port = port
    }
    
    func start() {
        let host = NWEndpoint.Host(receiverIp)
        let port = NWEndpoint.Port(rawValue: UInt16(port))!
        
        connection = NWConnection(host: host, port: port, using: .tcp)
        connection?.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                self?.sendFile()
            case .failed(let error):
                self?.delegate?.transferDidFail(error: error.localizedDescription)
            case .cancelled:
                self?.delegate?.transferDidFail(error: "Cancelled")
            default:
                break
            }
        }
        
        connection?.start(queue: .global())
    }
    
    private func sendFile() {
        delegate?.transferDidStart()
        
        guard let data = try? Data(contentsOf: fileUrl) else {
            delegate?.transferDidFail(error: "Failed to read file")
            return
        }
        
        // Send metadata
        let metadata: [String: Any] = [
            "id": fileId,
            "fileName": fileUrl.lastPathComponent,
            "fileSize": data.count,
            "category": "other"
        ]
        
        if let metaJson = try? JSONSerialization.data(withJSONObject: metadata),
           let metaString = String(data: metaJson, encoding: .utf8) {
            let metaBytes = metaString.data(using: .utf8)!
            let lengthBytes = withUnsafeBytes(of: Int32(metaBytes.count).bigEndian) { Data($0) }
            
            connection?.send(content: lengthBytes, completion: .contentProcessed({ _ in }))
            connection?.send(content: metaBytes, completion: .contentProcessed({ [weak self] _ in
                self?.sendFileData(data)
            }))
        }
    }
    
    private func sendFileData(_ data: Data) {
        let chunkSize = 64 * 1024
        var offset = 0
        let total = data.count
        let startTime = Date()
        
        func sendChunk() {
            guard offset < total else {
                delegate?.transferDidComplete(success: true)
                return
            }
            
            let end = min(offset + chunkSize, total)
            let chunk = data[offset..<end]
            
            connection?.send(content: chunk, completion: .contentProcessed({ _ in
                offset = end
                let progress = Double(offset) / Double(total)
                let elapsed = Date().timeIntervalSince(startTime)
                let speed = elapsed > 0 ? Double(offset) / elapsed : 0
                self.delegate?.transferDidProgress(progress: progress, speedBps: speed)
                sendChunk()
            }))
        }
        
        sendChunk()
    }
    
    func cancel() {
        connection?.cancel()
    }
}

// MARK: - Listener Socket

class ListenerSocket {
    private var listener: NWListener?
    private var connections: [NWConnection] = []
    private var onPortCallback: ((Int) -> Void)?
    
    func startListening(onPort port: Int, callback: @escaping (Int) -> Void) {
        onPortCallback = callback
        
        let nwPort = NWEndpoint.Port(rawValue: UInt16(port))!
        listener = try? NWListener(using: .tcp, on: nwPort)
        
        listener?.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                if let port = self?.listener?.port?.rawValue {
                    self?.onPortCallback?(Int(port))
                }
                self?.acceptNewConnection()
            case .failed(let error):
                print("Listener failed: \(error)")
            default:
                break
            }
        }
        
        listener?.start(queue: .global())
    }
    
    private func acceptNewConnection() {
        listener?.newConnectionHandler = { [weak self] connection in
            self?.connections.append(connection)
            connection.start(queue: .global())
            self?.handleConnection(connection)
            self?.acceptNewConnection()
        }
    }
    
    private func handleConnection(_ connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 4, maximumLength: 4) { [weak self] data, _, isComplete, error in
            guard let self = self, let data = data, error == nil else { return }
            
            let length = data.withUnsafeBytes { $0.load(as: Int32.self).bigEndian }
            
            connection.receive(minimumIncompleteLength: Int(length), maximumLength: Int(length)) { data, _, _, error in
                guard let data = data, error == nil else { return }
                
                if let jsonString = String(data: data, encoding: .utf8),
                   let metadata = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("Received metadata: \(metadata)")
                    // Handle file transfer here
                }
            }
        }
    }
    
    func stop() {
        listener?.cancel()
        connections.forEach { $0.cancel() }
        connections.removeAll()
    }
}

// MARK: - FileTransferDelegate Implementation

extension NagarikShareManager: FileTransferDelegate {
    func transferDidStart() {
        emit("transferStarted", ["fileId": activeTransfer?.fileId ?? ""])
    }
    
    func transferDidProgress(progress: Double, speedBps: Double) {
        emit("transferProgress", [
            "fileId": activeTransfer?.fileId ?? "",
            "progressPct": Int(progress * 100),
            "speedBps": speedBps
        ])
    }
    
    func transferDidComplete(success: Bool) {
        emit("transferCompleted", [
            "fileId": activeTransfer?.fileId ?? "",
            "checksumOk": success,
            "direction": "sent"
        ])
        activeTransfer = nil
    }
    
    func transferDidFail(error: String) {
        emit("transferFailed", [
            "fileId": activeTransfer?.fileId ?? "",
            "error": error
        ])
        activeTransfer = nil
    }
}
