package com.nagarikplus.nagarik_plus

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.LocationManager
import android.media.MediaScannerConnection
import android.net.Uri
import android.net.wifi.WifiManager
import android.os.Build
import android.provider.Settings
import android.view.WindowManager
import android.webkit.MimeTypeMap
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.net.NetworkInterface

import com.nagarikplus.nagarik_plus.share.*

class MainActivity : FlutterActivity() {

    // ─── Existing channels ─────────────────────────────────────────────────
    private val SECURITY_CHANNEL      = "com.nagarikplus.scanner/security"
    private val MEDIA_SCANNER_CHANNEL = "com.nagarikplus.nagarik_plus/media_scanner"
    private val FILE_VIEWER_CHANNEL   = "com.nagarikplus.nagarik_plus/open_file"

    // ─── NagarikShare channels ────────────────────────────────────────────
    private val SHARE_METHOD_CHANNEL  = "nagarik.share.connection"
    private val SHARE_EVENT_CHANNEL   = "nagarik.share.events"

    // ─── NagarikShare components ──────────────────────────────────────────
    private lateinit var wifiDirectManager: WifiDirectManager
    private lateinit var hotspotManager:    HotspotManager
    private lateinit var networkDiscovery:  NetworkDiscovery
    private lateinit var socketServer:      SocketServer
    private lateinit var socketClient:      SocketClient
    private lateinit var transferManager:   TransferManager

    private var eventSink:     EventChannel.EventSink? = null
    private var isInitialized: Boolean = false
    private var connectedIp:   String? = null
    private var transferPort:  Int     = 8888

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── Initialize share components ────────────────────────────────────
        socketServer  = SocketServer(this)
        socketClient  = SocketClient()
        transferManager = TransferManager(socketServer, socketClient)

        hotspotManager   = HotspotManager(this)
        networkDiscovery = NetworkDiscovery(this)

        wifiDirectManager = WifiDirectManager(this, object : WifiDirectManager.WifiDirectListener {
            override fun onPeerFound(deviceId: String, deviceName: String) {
                emit("deviceFound", mapOf(
                    "deviceId"       to deviceId,
                    "deviceName"     to deviceName,
                    "connectionType" to "Wi-Fi Direct",
                ))
            }
            override fun onPeerLost(deviceId: String) {
                emit("deviceLost", mapOf("deviceId" to deviceId))
            }
            override fun onConnected(groupOwnerIp: String, isGroupOwner: Boolean) {
                connectedIp  = groupOwnerIp
                transferPort = socketServer.port.takeIf { it > 0 } ?: 8888
                emit("deviceConnected", mapOf(
                    "ipAddress"    to groupOwnerIp,
                    "isGroupOwner" to isGroupOwner,
                    "port"         to transferPort,
                ))
            }
            override fun onConnectionFailed(reason: String) {
                emit("connectionFailed", mapOf("reason" to reason))
            }
            override fun onDisconnected() {
                connectedIp = null
                emit("disconnected", emptyMap<String, Any>())
            }
            override fun onWifiDirectUnavailable() {
                emit("wifiDirectUnavailable", emptyMap<String, Any>())
            }
        })

        // ── Event channel ────────────────────────────────────────────────
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, SHARE_EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(args: Any?, sink: EventChannel.EventSink) {
                    eventSink = sink
                    transferManager.setEventSink(sink)
                }
                override fun onCancel(args: Any?) {
                    eventSink = null
                    transferManager.setEventSink(null)
                }
            })

        // ── Method channel ────────────────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SHARE_METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    "initialize" -> {
                        if (!isInitialized) {
                            wifiDirectManager.initialize()
                            isInitialized = true
                        }
                        result.success(null)
                    }

                    "discoverDevices" -> {
                        emit("searching", emptyMap<String, Any>())
                        try {
                            wifiDirectManager.startDiscovery()
                        } catch (e: SecurityException) {
                            // Permission denied for Wi-Fi Direct → fall back to hotspot
                            emit("wifiDirectUnavailable", emptyMap<String, Any>())
                        }
                        // Also start NSD / UDP discovery in parallel
                        networkDiscovery.startDiscovery(object : NetworkDiscovery.DiscoveryListener {
                            override fun onDeviceFound(deviceId: String, deviceName: String,
                                                       ipAddress: String, connectionType: String) {
                                emit("deviceFound", mapOf(
                                    "deviceId"       to deviceId,
                                    "deviceName"     to deviceName,
                                    "ipAddress"      to ipAddress,
                                    "connectionType" to connectionType,
                                ))
                            }
                            override fun onDeviceLost(deviceId: String) {
                                emit("deviceLost", mapOf("deviceId" to deviceId))
                            }
                        })
                        result.success(null)
                    }

                    "stopDiscovery" -> {
                        wifiDirectManager.stopDiscovery()
                        networkDiscovery.stopDiscovery()
                        result.success(null)
                    }

                    "connectDevice" -> {
                        val deviceId = call.argument<String>("deviceId") ?: run {
                            result.error("INVALID_ARGS", "deviceId required", null)
                            return@setMethodCallHandler
                        }
                        emit("connecting", mapOf("deviceId" to deviceId))
                        // If it looks like an IP, use it directly (LAN / hotspot device)
                        if (deviceId.matches(Regex("""\d+\.\d+\.\d+\.\d+"""))) {
                            connectedIp  = deviceId
                            transferPort = 8888
                            emit("deviceConnected", mapOf(
                                "deviceId"  to deviceId,
                                "ipAddress" to deviceId,
                                "port"      to transferPort,
                            ))
                        } else {
                            // Wi-Fi Direct MAC address
                            try { wifiDirectManager.connectToPeer(deviceId) }
                            catch (e: SecurityException) {
                                result.error("PERMISSION", "Location permission required for Wi-Fi Direct", null)
                                return@setMethodCallHandler
                            }
                        }
                        result.success(null)
                    }

                    "createHotspot" -> {
                        hotspotManager.startHotspot(object : HotspotManager.HotspotListener {
                            override fun onHotspotStarted(ssid: String, password: String, gatewayIp: String) {
                                connectedIp  = gatewayIp
                                transferPort = socketServer.port.takeIf { it > 0 } ?: 8888
                                result.success(mapOf(
                                    "ssid"      to ssid,
                                    "password"  to password,
                                    "gatewayIp" to gatewayIp,
                                    "port"      to transferPort,
                                ))
                                emit("hotspotCreated", mapOf(
                                    "ssid"      to ssid,
                                    "gatewayIp" to gatewayIp,
                                    "port"      to transferPort,
                                ))
                            }
                            override fun onHotspotFailed(reason: String) {
                                result.error("HOTSPOT_FAILED", reason, null)
                            }
                            override fun onHotspotStopped() {}
                        })
                    }

                    "stopHotspot" -> {
                        hotspotManager.stopHotspot()
                        result.success(null)
                    }

                    "connectToWifi" -> {
                        val ssid     = call.argument<String>("ssid") ?: ""
                        val password = call.argument<String>("password") ?: ""
                        hotspotManager.connectToWifi(ssid, password) { success, err ->
                            if (success) {
                                result.success(true)
                            } else {
                                result.error("CONNECT_WIFI_FAILED", err ?: "Failed to connect to Wi-Fi", null)
                            }
                        }
                    }

                    "startReceiving" -> {
                        val port = call.argument<Int>("port") ?: 8888
                        transferManager.startReceiving(port)
                        result.success(mapOf("port" to socketServer.port))
                    }

                    "sendFile" -> {
                        val fileId   = call.argument<String>("fileId")   ?: ""
                        val filePath = call.argument<String>("filePath") ?: run {
                            result.error("INVALID_ARGS", "filePath required", null)
                            return@setMethodCallHandler
                        }
                        val ip   = call.argument<String>("receiverIp") ?: connectedIp ?: run {
                            result.error("NOT_CONNECTED", "No connected IP", null)
                            return@setMethodCallHandler
                        }
                        val port = call.argument<Int>("port") ?: transferPort
                        transferManager.sendFile(fileId, filePath, ip, port)
                        result.success(null)
                    }

                    "cancelTransfer" -> {
                        transferManager.cancelAll()
                        result.success(null)
                    }

                    "disconnect" -> {
                        transferManager.cancelAll()
                        wifiDirectManager.disconnect()
                        networkDiscovery.stopDiscovery()
                        hotspotManager.stopHotspot()
                        connectedIp = null
                        result.success(null)
                    }

                    "getConnectionInfo" -> {
                        val ip    = connectedIp ?: getLocalIp()
                        val port  = socketServer.port.takeIf { it > 0 } ?: transferPort
                        result.success(mapOf(
                            "ipAddress"  to ip,
                            "port"       to port,
                            "isHotspot"  to hotspotManager.isHotspotActive(),
                            "serverPort" to socketServer.port,
                        ))
                    }

                    "getLocalIp" -> {
                        result.success(getLocalIp())
                    }

                    "getApkPath" -> {
                        val pkgName = call.argument<String>("packageName")
                        if (pkgName != null) {
                            try {
                                val appInfo = packageManager.getApplicationInfo(pkgName, 0)
                                result.success(appInfo.sourceDir)
                            } catch (e: Exception) {
                                result.error("NOT_FOUND", e.message, null)
                            }
                        } else {
                            result.error("INVALID_ARGS", "packageName required", null)
                        }
                    }

                    "checkHardwareState" -> {
                        val wifiMgr = applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager
                        val btMgr   = applicationContext.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
                        val locMgr  = applicationContext.getSystemService(Context.LOCATION_SERVICE) as? LocationManager

                        val isWifiOn    = wifiMgr?.isWifiEnabled == true
                        val isHotspotOn = hotspotManager.isHotspotActive()
                        val isBtOn      = btMgr?.adapter?.isEnabled == true
                        val isLocOn     = (locMgr?.isProviderEnabled(LocationManager.GPS_PROVIDER) == true) ||
                                          (locMgr?.isProviderEnabled(LocationManager.NETWORK_PROVIDER) == true)
                        val hasPerms    = checkAllSharePermissions()

                        result.success(mapOf(
                            "isWifiEnabled"      to isWifiOn,
                            "isHotspotEnabled"   to isHotspotOn,
                            "isBluetoothEnabled" to isBtOn,
                            "isLocationEnabled"  to isLocOn,
                            "hasPermissions"     to hasPerms,
                        ))
                    }

                    "enableWifi" -> {
                        try {
                            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
                                val wifiMgr = applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager
                                @Suppress("DEPRECATION")
                                wifiMgr?.isWifiEnabled = true
                                result.success(true)
                            } else {
                                val intent = Intent(Settings.Panel.ACTION_WIFI)
                                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                startActivity(intent)
                                result.success(true)
                            }
                        } catch (_: Exception) {
                            val intent = Intent(Settings.ACTION_WIFI_SETTINGS)
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                            result.success(true)
                        }
                    }

                    "enableBluetooth" -> {
                        try {
                            val btMgr = applicationContext.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
                            val adapter = btMgr?.adapter
                            if (adapter != null && !adapter.isEnabled) {
                                @Suppress("DEPRECATION")
                                adapter.enable()
                            }
                            result.success(true)
                        } catch (e: Exception) {
                            val intent = Intent(Settings.ACTION_BLUETOOTH_SETTINGS)
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                            result.success(true)
                        }
                    }

                    "enableLocation" -> {
                        try {
                            val intent = Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS)
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("LOC_ENABLE_FAILED", e.message, null)
                        }
                    }

                    "requestSharePermissions" -> {
                        val missing = getMissingPermissions()
                        if (missing.isEmpty()) {
                            result.success(true)
                        } else {
                            permissionResultCallback = result
                            ActivityCompat.requestPermissions(this, missing.toTypedArray(), PERMISSION_REQUEST_CODE)
                        }
                    }

                    else -> result.notImplemented()
                }
            }

        // ── Security channel ─────────────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SECURITY_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setSecureScreen" -> {
                        val secure = call.argument<Boolean>("secure") ?: false
                        if (secure) window.setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE)
                        else        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        // ── Media scanner channel ─────────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MEDIA_SCANNER_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "scanFile") {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        try { MediaScannerConnection.scanFile(this, arrayOf(path), null, null) }
                        catch (_: Exception) {}
                    }
                    result.success(true)
                } else result.notImplemented()
            }

        // ── File viewer channel ───────────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FILE_VIEWER_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "openFile") {
                    val path = call.argument<String>("path")
                    if (path != null) {
                        try {
                            val file = File(path)
                            if (file.exists()) {
                                val ext  = MimeTypeMap.getFileExtensionFromUrl(path)
                                val mime = if (ext.isNullOrEmpty()) "*/*"
                                           else MimeTypeMap.getSingleton().getMimeTypeFromExtension(ext.lowercase()) ?: "*/*"
                                val uri: Uri = FileProvider.getUriForFile(this, "${packageName}.fileprovider", file)
                                val intent   = Intent(Intent.ACTION_VIEW).apply {
                                    setDataAndType(uri, mime)
                                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                }
                                startActivity(intent)
                                result.success(true)
                            } else result.error("NOT_FOUND", "File does not exist", null)
                        } catch (e: Exception) { result.error("ERROR", e.message, null) }
                    } else result.error("INVALID_PATH", "Path is null", null)
                } else result.notImplemented()
            }
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    private fun emit(type: String, data: Map<String, Any?>) {
        runOnUiThread {
            val payload = HashMap<String, Any?>(data).also { it["type"] = type }
            eventSink?.success(payload)
        }
    }

    private fun getLocalIp(): String? {
        return try {
            val ifaces = NetworkInterface.getNetworkInterfaces()?.toList() ?: return null
            for (iface in ifaces) {
                val name = iface.name.lowercase()
                if (name.contains("wlan") || name.contains("p2p") || name.contains("ap")) {
                    for (addr in iface.inetAddresses.toList()) {
                        if (!addr.isLoopbackAddress && !addr.hostAddress.isNullOrEmpty()
                            && !addr.hostAddress!!.contains(':')) {
                            return addr.hostAddress
                        }
                    }
                }
            }
            null
        } catch (_: Exception) { null }
    }

    private val PERMISSION_REQUEST_CODE = 9999
    private var permissionResultCallback: MethodChannel.Result? = null

    private fun getMissingPermissions(): List<String> {
        val list = mutableListOf<String>()
        list.add(Manifest.permission.ACCESS_FINE_LOCATION)
        list.add(Manifest.permission.ACCESS_COARSE_LOCATION)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            list.add(Manifest.permission.NEARBY_WIFI_DEVICES)
            list.add(Manifest.permission.READ_MEDIA_IMAGES)
            list.add(Manifest.permission.READ_MEDIA_VIDEO)
            list.add(Manifest.permission.READ_MEDIA_AUDIO)
        } else {
            list.add(Manifest.permission.READ_EXTERNAL_STORAGE)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            list.add(Manifest.permission.BLUETOOTH_SCAN)
            list.add(Manifest.permission.BLUETOOTH_CONNECT)
            list.add(Manifest.permission.BLUETOOTH_ADVERTISE)
        }

        return list.filter {
            ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
        }
    }

    private fun checkAllSharePermissions(): Boolean {
        return getMissingPermissions().isEmpty()
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_REQUEST_CODE) {
            val allGranted = grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }
            permissionResultCallback?.success(allGranted)
            permissionResultCallback = null
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        if (isInitialized) {
            wifiDirectManager.destroy()
            networkDiscovery.destroy()
            transferManager.destroy()
            socketClient.destroy()
        }
    }
}
