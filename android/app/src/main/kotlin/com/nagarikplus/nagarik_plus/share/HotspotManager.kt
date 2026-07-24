package com.nagarikplus.nagarik_plus.share

import android.content.Context
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import java.lang.reflect.Method
import java.net.InetAddress
import java.net.NetworkInterface

/**
 * Fallback hotspot manager when Wi-Fi Direct is unavailable.
 * On Android 8+: uses WifiManager.LocalOnlyHotspotReservation.
 * On older Android: uses reflection on setWifiApEnabled.
 */
class HotspotManager(private val context: Context) {

    interface HotspotListener {
        fun onHotspotStarted(ssid: String, password: String, gatewayIp: String)
        fun onHotspotFailed(reason: String)
        fun onHotspotStopped()
    }

    private val wifiManager: WifiManager by lazy {
        context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
    }
    private val handler = Handler(Looper.getMainLooper())

    // Android 8+ reservation
    private var hotspotReservation: WifiManager.LocalOnlyHotspotReservation? = null

    fun startHotspot(listener: HotspotListener) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startLocalOnlyHotspot(listener)
        } else {
            startLegacyHotspot(listener)
        }
    }

    private fun startLocalOnlyHotspot(listener: HotspotListener) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        try {
            wifiManager.startLocalOnlyHotspot(object : WifiManager.LocalOnlyHotspotCallback() {
                override fun onStarted(reservation: WifiManager.LocalOnlyHotspotReservation) {
                    hotspotReservation = reservation

                    // Android 10+ uses softApConfiguration; earlier uses wifiConfiguration
                    val ssid: String
                    val pass: String
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        val sac = reservation.softApConfiguration
                        ssid = sac?.ssid ?: "NagarikShare"
                        pass = sac?.passphrase ?: ""
                    } else {
                        @Suppress("DEPRECATION")
                        val cfg = reservation.wifiConfiguration
                        ssid = cfg?.SSID?.replace("\"", "") ?: "NagarikShare"
                        pass = cfg?.preSharedKey?.replace("\"", "") ?: ""
                    }

                    val ip = getHotspotGatewayIp() ?: "192.168.43.1"
                    listener.onHotspotStarted(ssid, pass, ip)
                }

                override fun onFailed(reason: Int) {
                    listener.onHotspotFailed("LocalOnlyHotspot failed: $reason")
                }

                override fun onStopped() {
                    hotspotReservation = null
                    listener.onHotspotStopped()
                }
            }, handler)
        } catch (e: Exception) {
            listener.onHotspotFailed("LocalOnlyHotspot exception: ${e.message}")
        }
    }

    @Suppress("DEPRECATION")
    private fun startLegacyHotspot(listener: HotspotListener) {
        try {
            val config = android.net.wifi.WifiConfiguration().apply {
                SSID = "NagarikShare"
                preSharedKey = "nagarikplus123"
                allowedAuthAlgorithms.set(android.net.wifi.WifiConfiguration.AuthAlgorithm.SHARED)
                allowedProtocols.set(android.net.wifi.WifiConfiguration.Protocol.RSN)
                allowedKeyManagement.set(android.net.wifi.WifiConfiguration.KeyMgmt.WPA_PSK)
            }
            val method: Method = wifiManager.javaClass.getMethod(
                "setWifiApEnabled",
                android.net.wifi.WifiConfiguration::class.java,
                Boolean::class.java
            )
            val result = method.invoke(wifiManager, config, true) as Boolean
            if (result) {
                handler.postDelayed({
                    listener.onHotspotStarted("NagarikShare", "nagarikplus123", "192.168.43.1")
                }, 2000)
            } else {
                listener.onHotspotFailed("Legacy hotspot enable returned false")
            }
        } catch (e: Exception) {
            listener.onHotspotFailed("Legacy hotspot error: ${e.message}")
        }
    }

    fun stopHotspot() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            hotspotReservation?.close()
            hotspotReservation = null
        } else {
            try {
                @Suppress("DEPRECATION")
                val method: Method = wifiManager.javaClass.getMethod(
                    "setWifiApEnabled",
                    android.net.wifi.WifiConfiguration::class.java,
                    Boolean::class.java
                )
                method.invoke(wifiManager, null, false)
            } catch (_: Exception) {}
        }
    }

    /**
     * Resolve the hotspot gateway IP (the AP's own address, typically 192.168.43.1).
     */
    fun getHotspotGatewayIp(): String? {
        return try {
            // Try to get IP from known hotspot-related interfaces
            val interfaces = NetworkInterface.getNetworkInterfaces()?.toList() ?: return null
            for (iface in interfaces) {
                val name = iface.name.lowercase()
                if (name.contains("ap") || name.contains("swlan") || name.contains("wlan")) {
                    for (addr in iface.inetAddresses.toList()) {
                        if (!addr.isLoopbackAddress && addr is InetAddress &&
                            addr.hostAddress?.contains(':') == false) {
                            return addr.hostAddress
                        }
                    }
                }
            }
            // Fallback: use DhcpInfo
            @Suppress("DEPRECATION")
            val dhcp = wifiManager.dhcpInfo
            if (dhcp != null) {
                val ip = dhcp.gateway
                if (ip != 0) {
                    return intToIp(ip)
                }
            }
            null
        } catch (_: Exception) { null }
    }

    private fun intToIp(ip: Int): String {
        return "${ip and 0xFF}.${(ip shr 8) and 0xFF}.${(ip shr 16) and 0xFF}.${(ip shr 24) and 0xFF}"
    }

    /** Check if a local hotspot is currently active */
    fun isHotspotActive(): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                hotspotReservation != null
            } else {
                val method = wifiManager.javaClass.getMethod("getWifiApState")
                val state  = method.invoke(wifiManager) as Int
                state == 13 // WIFI_AP_STATE_ENABLED
            }
        } catch (_: Exception) { false }
    }

    /** Connect device to a Wi-Fi hotspot given SSID and password */
    fun connectToWifi(ssid: String, password: String, onComplete: (Boolean, String?) -> Unit) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            try {
                val specifier = android.net.wifi.WifiNetworkSpecifier.Builder()
                    .setSsid(ssid)
                    .apply {
                        if (password.isNotEmpty()) setWpa2Passphrase(password)
                    }
                    .build()

                val request = android.net.NetworkRequest.Builder()
                    .addTransportType(android.net.NetworkCapabilities.TRANSPORT_WIFI)
                    .removeCapability(android.net.NetworkCapabilities.NET_CAPABILITY_INTERNET)
                    .setNetworkSpecifier(specifier)
                    .build()

                val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as android.net.ConnectivityManager
                cm.requestNetwork(request, object : android.net.ConnectivityManager.NetworkCallback() {
                    override fun onAvailable(network: android.net.Network) {
                        cm.bindProcessToNetwork(network)
                        onComplete(true, null)
                    }

                    override fun onUnavailable() {
                        onComplete(false, "Wi-Fi network unavailable or connection rejected")
                    }
                })
            } catch (e: Exception) {
                onComplete(false, e.message)
            }
        } else {
            @Suppress("DEPRECATION")
            try {
                val wifiConfig = android.net.wifi.WifiConfiguration().apply {
                    SSID = "\"$ssid\""
                    if (password.isNotEmpty()) preSharedKey = "\"$password\""
                    else allowedKeyManagement.set(android.net.wifi.WifiConfiguration.KeyMgmt.NONE)
                }
                val netId = wifiManager.addNetwork(wifiConfig)
                if (netId != -1) {
                    wifiManager.disconnect()
                    wifiManager.enableNetwork(netId, true)
                    wifiManager.reconnect()
                    onComplete(true, null)
                } else {
                    onComplete(false, "Failed to add Wi-Fi configuration")
                }
            } catch (e: Exception) {
                onComplete(false, e.message)
            }
        }
    }
}

