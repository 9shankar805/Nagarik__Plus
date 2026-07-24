package com.nagarikplus.nagarik_plus.share

import io.flutter.plugin.common.EventChannel
import kotlinx.coroutines.*
import org.json.JSONObject
import java.io.File

/**
 * Orchestrates the complete share session:
 *  - Coordinates Wi-Fi Direct / Hotspot / LAN connection
 *  - Runs SocketServer (receiver) or SocketClient (sender)
 *  - Emits events to Flutter via [EventChannel.EventSink]
 */
class TransferManager(
    private val socketServer: SocketServer,
    private val socketClient: SocketClient,
) {
    private var eventSink: EventChannel.EventSink? = null
    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    fun setEventSink(sink: EventChannel.EventSink?) {
        eventSink = sink
    }

    // ── Server (Receiver) ─────────────────────────────────────────────────────

    fun startReceiving(port: Int = 8888) {
        socketServer.start(port, object : SocketServer.ServerListener {
            override fun onFileStarted(fileName: String, totalBytes: Long) {
                emit("transferStarted", mapOf(
                    "fileName"   to fileName,
                    "totalBytes" to totalBytes,
                ))
            }

            override fun onProgress(fileName: String, received: Long, total: Long, speedBps: Double) {
                val pct = if (total > 0) (received.toDouble() / total * 100).toInt() else 0
                emit("transferProgress", mapOf(
                    "fileName"    to fileName,
                    "received"    to received,
                    "total"       to total,
                    "progressPct" to pct,
                    "speedBps"    to speedBps,
                ))
            }

            override fun onFileCompleted(fileName: String, savedPath: String, checksumOk: Boolean) {
                emit("transferCompleted", mapOf(
                    "fileName"       to fileName,
                    "savedPath"      to savedPath,
                    "checksumOk"     to checksumOk,
                    "direction"      to "received",
                ))
            }

            override fun onFileFailed(fileName: String, error: String) {
                emit("transferFailed", mapOf(
                    "fileName" to fileName,
                    "error"    to error,
                ))
            }
        })

        emit("serverStarted", mapOf("port" to socketServer.port))
    }

    fun stopReceiving() = socketServer.stop()

    // ── Client (Sender) ───────────────────────────────────────────────────────

    fun sendFile(
        fileId:      String,
        filePath:    String,
        receiverIp:  String,
        receiverPort: Int,
    ) {
        if (!File(filePath).exists()) {
            emit("transferFailed", mapOf("fileId" to fileId, "error" to "File not found"))
            return
        }

        socketClient.sendFile(
            fileId   = fileId,
            filePath = filePath,
            ip       = receiverIp,
            port     = receiverPort,
            listener = object : SocketClient.ClientListener {
                override fun onConnected() {
                    emit("transferStarted", mapOf("fileId" to fileId))
                }

                override fun onProgress(fileId: String, sent: Long, total: Long, speedBps: Double, etaSeconds: Int) {
                    val pct = if (total > 0) (sent.toDouble() / total * 100).toInt() else 0
                    emit("transferProgress", mapOf(
                        "fileId"      to fileId,
                        "sent"        to sent,
                        "total"       to total,
                        "progressPct" to pct,
                        "speedBps"    to speedBps,
                        "eta"         to etaSeconds,
                    ))
                }

                override fun onFileSent(fileId: String, fileName: String, checksumOk: Boolean) {
                    emit("transferCompleted", mapOf(
                        "fileId"     to fileId,
                        "fileName"   to fileName,
                        "checksumOk" to checksumOk,
                        "direction"  to "sent",
                    ))
                }

                override fun onFileFailed(fileId: String, error: String) {
                    emit("transferFailed", mapOf(
                        "fileId" to fileId,
                        "error"  to error,
                    ))
                }

                override fun onDisconnected() {
                    emit("disconnected", emptyMap<String, Any>())
                }
            }
        )
    }

    fun cancelAll() {
        socketClient.cancel()
        socketServer.stop()
    }

    // ── Event emitter ─────────────────────────────────────────────────────────

    private fun emit(type: String, data: Map<String, Any?>) {
        scope.launch(Dispatchers.Main) {
            val payload = HashMap<String, Any?>(data).also { it["type"] = type }
            eventSink?.success(payload)
        }
    }

    fun destroy() {
        cancelAll()
        scope.cancel()
    }
}
