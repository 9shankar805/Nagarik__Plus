package com.nagarikplus.nagarik_plus.share

import android.content.Context
import android.net.nsd.NsdManager
import android.net.nsd.NsdServiceInfo
import android.os.Build
import java.net.*
import java.util.concurrent.ConcurrentHashMap
import kotlinx.coroutines.*

/**
 * Multi-method device discovery:
 *  1. mDNS / NSD (Network Service Discovery)
 *  2. UDP broadcast beacon
 *
 * Used as fallback when Wi-Fi Direct peers list is empty
 * or as supplementary discovery on the LAN.
 */
class NetworkDiscovery(private val context: Context) {

    interface DiscoveryListener {
        fun onDeviceFound(deviceId: String, deviceName: String,
                          ipAddress: String, connectionType: String)
        fun onDeviceLost(deviceId: String)
    }

    private val SERVICE_TYPE = "_nagarikshare._tcp."
    private val SERVICE_PORT = 8888
    private val UDP_PORT     = 9876
    private val BEACON_INTERVAL_MS = 3000L
    private val DEVICE_NAME  by lazy { Build.MODEL ?: "Android Device" }

    private var nsdManager: NsdManager? = null
    private var registrationListener: NsdManager.RegistrationListener? = null
    private var discoveryListener:    NsdManager.DiscoveryListener?    = null

    private var udpSocket:  DatagramSocket? = null
    private val scope       = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private val foundDevices = ConcurrentHashMap<String, String>() // id → name

    private var deviceListener: DiscoveryListener? = null

    fun startDiscovery(listener: DiscoveryListener) {
        deviceListener = listener
        startNsd()
        startUdpDiscovery()
        broadcastPresence()
    }

    fun stopDiscovery() {
        stopNsd()
        stopUdp()
        scope.coroutineContext.cancelChildren()
    }

    // ── NSD (mDNS) ──────────────────────────────────────────────────────────

    private fun startNsd() {
        try {
            nsdManager = context.getSystemService(Context.NSD_SERVICE) as NsdManager

            // Register ourselves
            val info = NsdServiceInfo().apply {
                serviceName = "NagarikShare_$DEVICE_NAME"
                serviceType = SERVICE_TYPE
                port        = SERVICE_PORT
            }
            registrationListener = object : NsdManager.RegistrationListener {
                override fun onServiceRegistered(info: NsdServiceInfo) {}
                override fun onRegistrationFailed(info: NsdServiceInfo, error: Int) {}
                override fun onServiceUnregistered(info: NsdServiceInfo) {}
                override fun onUnregistrationFailed(info: NsdServiceInfo, error: Int) {}
            }
            nsdManager?.registerService(info, NsdManager.PROTOCOL_DNS_SD, registrationListener)

            // Discover others
            discoveryListener = object : NsdManager.DiscoveryListener {
                override fun onDiscoveryStarted(type: String) {}
                override fun onDiscoveryStopped(type: String) {}
                override fun onStartDiscoveryFailed(type: String, error: Int) {}
                override fun onStopDiscoveryFailed(type: String, error: Int) {}

                override fun onServiceFound(service: NsdServiceInfo) {
                    if (service.serviceType.contains("nagarikshare", ignoreCase = true)) {
                        nsdManager?.resolveService(service, object : NsdManager.ResolveListener {
                            override fun onResolveFailed(info: NsdServiceInfo, error: Int) {}
                            override fun onServiceResolved(info: NsdServiceInfo) {
                                val ip   = info.host?.hostAddress ?: return
                                val name = info.serviceName.removePrefix("NagarikShare_")
                                val id   = ip
                                if (!foundDevices.containsKey(id)) {
                                    foundDevices[id] = name
                                    deviceListener?.onDeviceFound(id, name, ip, "LAN / mDNS")
                                }
                            }
                        })
                    }
                }

                override fun onServiceLost(service: NsdServiceInfo) {
                    val ip = service.host?.hostAddress ?: return
                    foundDevices.remove(ip)
                    deviceListener?.onDeviceLost(ip)
                }
            }
            nsdManager?.discoverServices(SERVICE_TYPE, NsdManager.PROTOCOL_DNS_SD, discoveryListener)
        } catch (_: Exception) {}
    }

    private fun stopNsd() {
        try {
            discoveryListener?.let { nsdManager?.stopServiceDiscovery(it) }
        } catch (_: Exception) {}
        try {
            registrationListener?.let { nsdManager?.unregisterService(it) }
        } catch (_: Exception) {}
        discoveryListener    = null
        registrationListener = null
    }

    // ── UDP Broadcast ────────────────────────────────────────────────────────

    private fun startUdpDiscovery() {
        scope.launch {
            try {
                udpSocket = DatagramSocket(UDP_PORT, InetAddress.getByName("0.0.0.0")).apply {
                    broadcast = true
                    soTimeout = 500
                }
                val buf = ByteArray(1024)
                while (isActive) {
                    try {
                        val packet = DatagramPacket(buf, buf.size)
                        udpSocket?.receive(packet)
                        val msg    = String(packet.data, 0, packet.length)
                        val senderIp = packet.address.hostAddress ?: continue
                        if (msg.startsWith("NAGARIK_SHARE:")) {
                            val name = msg.removePrefix("NAGARIK_SHARE:")
                            val id   = senderIp
                            if (!foundDevices.containsKey(id)) {
                                foundDevices[id] = name
                                deviceListener?.onDeviceFound(id, name, senderIp, "Local Hotspot")
                            }
                        }
                    } catch (_: SocketTimeoutException) {}
                }
            } catch (_: Exception) {}
        }
    }

    private fun broadcastPresence() {
        scope.launch {
            try {
                val sendSocket = DatagramSocket().apply { broadcast = true }
                val beacon     = "NAGARIK_SHARE:$DEVICE_NAME".toByteArray()
                val broadcastAddr = InetAddress.getByName("255.255.255.255")
                while (isActive) {
                    try {
                        val packet = DatagramPacket(beacon, beacon.size, broadcastAddr, UDP_PORT)
                        sendSocket.send(packet)
                    } catch (_: Exception) {}
                    delay(BEACON_INTERVAL_MS)
                }
                sendSocket.close()
            } catch (_: Exception) {}
        }
    }

    private fun stopUdp() {
        try { udpSocket?.close() } catch (_: Exception) {}
        udpSocket = null
    }

    fun destroy() {
        stopDiscovery()
        scope.cancel()
    }
}
