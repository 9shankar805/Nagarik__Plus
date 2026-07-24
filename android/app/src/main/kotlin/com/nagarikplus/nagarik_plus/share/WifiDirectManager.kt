package com.nagarikplus.nagarik_plus.share

import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.NetworkInfo
import android.net.wifi.p2p.*
import android.os.Build
import android.os.Handler
import android.os.Looper

/**
 * Manages Wi-Fi Direct (WifiP2pManager) for:
 *  - Peer discovery
 *  - Group creation / joining
 *  - IP address negotiation
 */
class WifiDirectManager(
    private val context: Context,
    private val listener: WifiDirectListener,
) {
    interface WifiDirectListener {
        fun onPeerFound(deviceId: String, deviceName: String)
        fun onPeerLost(deviceId: String)
        fun onConnected(groupOwnerIp: String, isGroupOwner: Boolean)
        fun onConnectionFailed(reason: String)
        fun onDisconnected()
        fun onWifiDirectUnavailable()
    }

    private val manager: WifiP2pManager? by lazy {
        context.getSystemService(Context.WIFI_P2P_SERVICE) as? WifiP2pManager
    }
    private var channel: WifiP2pManager.Channel? = null
    private var receiver: BroadcastReceiver? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    private var isDiscovering   = false
    private var currentGroupOwnerIp: String? = null

    val isAvailable: Boolean get() = manager != null

    fun initialize() {
        try {
            val mgr = manager ?: run {
                listener.onWifiDirectUnavailable()
                return
            }
            channel = mgr.initialize(context, Looper.getMainLooper(), null)
            registerReceiver()
        } catch (_: Exception) {
            listener.onWifiDirectUnavailable()
        }
    }

    fun startDiscovery() {
        try {
            val mgr = manager ?: return
            val ch  = channel ?: return
            if (isDiscovering) return
            isDiscovering = true

            mgr.discoverPeers(ch, object : WifiP2pManager.ActionListener {
                override fun onSuccess()   { /* discovery started */ }
                override fun onFailure(r: Int) {
                    isDiscovering = false
                    listener.onWifiDirectUnavailable()
                }
            })
        } catch (_: Exception) {
            isDiscovering = false
            listener.onWifiDirectUnavailable()
        }
    }

    fun stopDiscovery() {
        try {
            val mgr = manager ?: return
            val ch  = channel ?: return
            isDiscovering = false
            mgr.stopPeerDiscovery(ch, null)
        } catch (_: Exception) {}
    }

    fun connectToPeer(deviceAddress: String) {
        try {
            val mgr = manager ?: return
            val ch  = channel ?: return

            val config = WifiP2pConfig().apply {
                this.deviceAddress = deviceAddress
                wps.setup = android.net.wifi.WpsInfo.PBC
            }

            mgr.connect(ch, config, object : WifiP2pManager.ActionListener {
                override fun onSuccess() { /* waiting for WIFI_P2P_CONNECTION_CHANGED_ACTION */ }
                override fun onFailure(reason: Int) {
                    listener.onConnectionFailed("P2P connect failed: $reason")
                }
            })
        } catch (e: Exception) {
            listener.onConnectionFailed("P2P connect exception: ${e.message}")
        }
    }

    fun requestConnectionInfo() {
        try {
            val mgr = manager ?: return
            val ch  = channel ?: return

            mgr.requestConnectionInfo(ch) { info ->
                if (info != null && info.groupFormed) {
                    val ownerIp = info.groupOwnerAddress?.hostAddress ?: return@requestConnectionInfo
                    currentGroupOwnerIp = ownerIp
                    listener.onConnected(ownerIp, info.isGroupOwner)
                }
            }
        } catch (_: Exception) {
            listener.onConnectionFailed("Failed to request connection info")
        }
    }

    fun disconnect() {
        try {
            val mgr = manager ?: return
            val ch  = channel ?: return

            mgr.removeGroup(ch, object : WifiP2pManager.ActionListener {
                override fun onSuccess()        { listener.onDisconnected() }
                override fun onFailure(r: Int)  { listener.onDisconnected() }
            })
        } catch (_: Exception) {
            listener.onDisconnected()
        }
        isDiscovering = false
    }

    fun requestPeerList() {
        try {
            val mgr = manager ?: return
            val ch  = channel ?: return

            mgr.requestPeers(ch) { peers ->
                if (peers != null && peers.deviceList != null) {
                    for (device in peers.deviceList) {
                        val name = device.deviceName?.ifBlank { "Unknown Device" } ?: "Unknown Device"
                        val addr = device.deviceAddress ?: ""
                        if (addr.isNotEmpty()) {
                            listener.onPeerFound(deviceId = addr, deviceName = name)
                        }
                    }
                }
            }
        } catch (_: Exception) {
            listener.onWifiDirectUnavailable()
        }
    }

    private fun registerReceiver() {
        try {
            val filter = IntentFilter().apply {
                addAction(WifiP2pManager.WIFI_P2P_STATE_CHANGED_ACTION)
                addAction(WifiP2pManager.WIFI_P2P_PEERS_CHANGED_ACTION)
                addAction(WifiP2pManager.WIFI_P2P_CONNECTION_CHANGED_ACTION)
                addAction(WifiP2pManager.WIFI_P2P_THIS_DEVICE_CHANGED_ACTION)
            }
            receiver = object : BroadcastReceiver() {
                override fun onReceive(ctx: Context, intent: Intent) {
                    try {
                        when (intent.action) {
                            WifiP2pManager.WIFI_P2P_STATE_CHANGED_ACTION -> {
                                val state = intent.getIntExtra(WifiP2pManager.EXTRA_WIFI_STATE, -1)
                                if (state != WifiP2pManager.WIFI_P2P_STATE_ENABLED) {
                                    listener.onWifiDirectUnavailable()
                                }
                            }
                            WifiP2pManager.WIFI_P2P_PEERS_CHANGED_ACTION -> {
                                requestPeerList()
                            }
                            WifiP2pManager.WIFI_P2P_CONNECTION_CHANGED_ACTION -> {
                                val networkInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                                    intent.getParcelableExtra(WifiP2pManager.EXTRA_NETWORK_INFO, NetworkInfo::class.java)
                                } else {
                                    @Suppress("DEPRECATION")
                                    intent.getParcelableExtra(WifiP2pManager.EXTRA_NETWORK_INFO) as? NetworkInfo
                                }
                                if (networkInfo?.isConnected == true) {
                                    requestConnectionInfo()
                                } else {
                                    listener.onDisconnected()
                                }
                            }
                        }
                    } catch (_: Exception) {}
                }
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                context.registerReceiver(receiver, filter, Context.RECEIVER_EXPORTED)
            } else {
                context.registerReceiver(receiver, filter)
            }
        } catch (_: Exception) {
            listener.onWifiDirectUnavailable()
        }
    }

    fun unregisterReceiver() {
        try {
            receiver?.let { context.unregisterReceiver(it) }
        } catch (_: Exception) {}
        receiver = null
    }

    fun destroy() {
        stopDiscovery()
        unregisterReceiver()
        channel = null
    }
}
