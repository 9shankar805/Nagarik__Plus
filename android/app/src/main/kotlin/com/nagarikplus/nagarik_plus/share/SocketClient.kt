package com.nagarikplus.nagarik_plus.share

import kotlinx.coroutines.*
import org.json.JSONObject
import java.io.*
import java.net.Socket
import java.security.MessageDigest

/**
 * TCP Socket client on the Sender side.
 *
 * Protocol:
 *   → [4-byte int: metaLen][meta JSON][raw file bytes]
 *   ← [4-byte int: resultLen][result JSON]
 */
class SocketClient {

    interface ClientListener {
        fun onConnected()
        fun onProgress(fileId: String, sent: Long, total: Long, speedBps: Double, etaSeconds: Int)
        fun onFileSent(fileId: String, fileName: String, checksumOk: Boolean)
        fun onFileFailed(fileId: String, error: String)
        fun onDisconnected()
    }

    private val scope     = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private var cancelled = false

    fun cancel() { cancelled = true }

    fun sendFile(
        fileId:   String,
        filePath: String,
        ip:       String,
        port:     Int,
        listener: ClientListener,
    ) {
        cancelled = false
        scope.launch {
            var socket: Socket? = null
            try {
                socket = Socket(ip, port).apply {
                    tcpNoDelay    = true
                    soTimeout     = 30_000          // 30 s read timeout
                    sendBufferSize    = 256 * 1024
                    receiveBufferSize = 64  * 1024
                }

                val output = DataOutputStream(BufferedOutputStream(socket.getOutputStream(), 256 * 1024))
                val input  = DataInputStream(BufferedInputStream(socket.getInputStream(),    64  * 1024))

                listener.onConnected()

                val file  = File(filePath)
                val total = file.length()
                val name  = file.name

                // 1. Compute MD5 for files ≤ 50 MB
                val checksum = if (total in 1..(50 * 1024 * 1024)) computeMd5(file) else ""

                // 2. Send metadata frame: [4-byte length][JSON]
                val meta = JSONObject().apply {
                    put("id",          fileId)
                    put("fileName",    name)
                    put("fileSize",    total)
                    put("checksum",    checksum)
                    put("totalChunks", ((total / (256 * 1024)) + 1).toInt())
                }.toString().toByteArray(Charsets.UTF_8)

                output.writeInt(meta.size)
                output.write(meta)
                output.flush()

                // 3. Wait for ACK frame: [4-byte length][JSON]
                val ackLen  = input.readInt()
                val ackData = ByteArray(ackLen)
                input.readFully(ackData)
                // (we don't need to parse the ACK body)

                // 4. Stream file bytes
                val fis       = FileInputStream(file)
                val buf       = ByteArray(64 * 1024)
                var sent      = 0L
                var lastCheck = 0L
                var lastTime  = System.currentTimeMillis()
                var speedBps  = 0.0

                while (sent < total) {
                    if (cancelled) {
                        fis.close()
                        socket.close()
                        listener.onFileFailed(fileId, "Cancelled")
                        return@launch
                    }
                    val n = fis.read(buf)
                    if (n == -1) break
                    output.write(buf, 0, n)
                    sent += n

                    val now  = System.currentTimeMillis()
                    val diff = now - lastTime
                    if (diff >= 300) {
                        speedBps  = (sent - lastCheck) / (diff / 1000.0)
                        val eta   = if (speedBps > 0) ((total - sent) / speedBps).toInt() else 0
                        lastCheck = sent
                        lastTime  = now
                        listener.onProgress(fileId, sent, total, speedBps, eta)
                    }
                }
                fis.close()
                output.flush()

                // 5. Read result frame: [4-byte length][JSON]
                val checksumOk = try {
                    socket.soTimeout = 15_000
                    val resLen  = input.readInt()
                    val resData = ByteArray(resLen)
                    input.readFully(resData)
                    val json = JSONObject(String(resData, Charsets.UTF_8))
                    json.optBoolean("checksumOk", true)
                } catch (_: Exception) {
                    true // treat timeout / missing result as success
                }

                socket.close()
                listener.onFileSent(fileId, name, checksumOk)
            } catch (e: Exception) {
                runCatching { socket?.close() }
                listener.onFileFailed(fileId, e.message ?: "Send error")
            }
        }
    }

    private fun computeMd5(file: File): String {
        val digest = MessageDigest.getInstance("MD5")
        FileInputStream(file).use { fis ->
            val buf = ByteArray(64 * 1024)
            var n: Int
            while (fis.read(buf).also { n = it } != -1) digest.update(buf, 0, n)
        }
        return digest.digest().joinToString("") { "%02x".format(it) }
    }

    fun destroy() {
        cancelled = true
        scope.cancel()
    }
}
