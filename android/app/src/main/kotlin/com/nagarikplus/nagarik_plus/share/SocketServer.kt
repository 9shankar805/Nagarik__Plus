package com.nagarikplus.nagarik_plus.share

import android.content.Context
import android.media.MediaScannerConnection
import android.os.Environment
import kotlinx.coroutines.*
import org.json.JSONObject
import java.io.*
import java.net.ServerSocket
import java.net.Socket
import java.security.MessageDigest

/**
 * TCP ServerSocket on the Receiver side.
 *
 * Protocol:
 *   ← [4-byte int: metaLen][meta JSON][raw file bytes (exactly fileSize bytes)]
 *   → [4-byte int: resultLen][result JSON]
 */
class SocketServer(private val context: Context? = null) {

    interface ServerListener {
        fun onFileStarted(fileName: String, totalBytes: Long)
        fun onProgress(fileName: String, received: Long, total: Long, speedBps: Double)
        fun onFileCompleted(fileName: String, savedPath: String, checksumOk: Boolean)
        fun onFileFailed(fileName: String, error: String)
    }

    private val scope        = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private var serverSocket: ServerSocket? = null
    private var isRunning    = false
    val port: Int get() = serverSocket?.localPort ?: 0

    fun start(preferredPort: Int = 8888, listener: ServerListener) {
        if (isRunning) stop()
        isRunning = true

        scope.launch {
            try {
                serverSocket = try {
                    ServerSocket(preferredPort)
                } catch (_: Exception) {
                    ServerSocket(0)
                }

                while (isRunning) {
                    try {
                        val client = serverSocket?.accept() ?: break
                        launch { handleClient(client, listener) }
                    } catch (_: Exception) {
                        if (!isRunning) break
                    }
                }
            } catch (_: Exception) {
                isRunning = false
            }
        }
    }

    private fun handleClient(socket: Socket, listener: ServerListener) {
        try {
            socket.apply {
                tcpNoDelay    = true
                soTimeout     = 60_000           // 60 s read timeout
                receiveBufferSize = 256 * 1024
                sendBufferSize    = 64  * 1024
            }

            // Use a single DataInputStream that wraps the raw socket stream.
            // Never mix DataInputStream with raw socket.inputStream reads.
            val input  = DataInputStream(BufferedInputStream(socket.inputStream,  256 * 1024))
            val output = DataOutputStream(BufferedOutputStream(socket.outputStream, 64 * 1024))

            // 1. Read metadata frame
            val metaLen   = input.readInt()
            if (metaLen <= 0 || metaLen > 1_048_576) {
                socket.close(); return
            }
            val metaBytes = ByteArray(metaLen)
            input.readFully(metaBytes)
            val meta      = JSONObject(String(metaBytes, Charsets.UTF_8))

            val fileName   = meta.getString("fileName")
            val totalBytes = meta.getLong("fileSize")
            val checksum   = meta.optString("checksum", "")

            listener.onFileStarted(fileName, totalBytes)

            // 2. Send ACK frame
            val ack = """{"ack":true}""".toByteArray(Charsets.UTF_8)
            output.writeInt(ack.size)
            output.write(ack)
            output.flush()

            // 3. Determine save path
            val destDir = getDestinationDir()
            var destFile = File(destDir, sanitizeFileName(fileName))
            if (destFile.exists()) {
                val stem = fileName.substringBeforeLast('.')
                val ext  = if ('.' in fileName) ".${fileName.substringAfterLast('.')}" else ""
                destFile = File(destDir, "${stem}_${System.currentTimeMillis()}$ext")
            }

            // 4. Read exactly [totalBytes] from the stream (after the metadata frame)
            val fileOut   = FileOutputStream(destFile)
            val buf       = ByteArray(64 * 1024)
            var received  = 0L
            var lastCheck = 0L
            var lastTime  = System.currentTimeMillis()
            var speedBps  = 0.0

            while (received < totalBytes) {
                val want = minOf(buf.size.toLong(), totalBytes - received).toInt()
                val n    = input.read(buf, 0, want)
                if (n == -1) break
                fileOut.write(buf, 0, n)
                received += n

                val now  = System.currentTimeMillis()
                val diff = now - lastTime
                if (diff >= 300) {
                    speedBps  = (received - lastCheck) / (diff / 1000.0)
                    lastCheck = received
                    lastTime  = now
                    listener.onProgress(fileName, received, totalBytes, speedBps)
                }
            }
            fileOut.flush()
            fileOut.close()

            // 5. Verify checksum
            val checksumOk = if (checksum.isNotEmpty()) {
                computeMd5(destFile).equals(checksum, ignoreCase = true)
            } else true

            // 6. Send result frame
            val result = """{"success":true,"checksumOk":$checksumOk}""".toByteArray(Charsets.UTF_8)
            output.writeInt(result.size)
            output.write(result)
            output.flush()

            // 7. Close
            runCatching { socket.close() }

            // 8. Trigger media scan
            context?.let { ctx ->
                MediaScannerConnection.scanFile(ctx, arrayOf(destFile.absolutePath), null, null)
            }

            listener.onFileCompleted(fileName, destFile.absolutePath, checksumOk)
        } catch (e: Exception) {
            runCatching { socket.close() }
            listener.onFileFailed("unknown", e.message ?: "Transfer error")
        }
    }

    private fun getDestinationDir(): File {
        val base = try {
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        } catch (_: Exception) {
            context?.getExternalFilesDir(null) ?: File("/sdcard")
        }
        return File(base, "NagarikShare").also { it.mkdirs() }
    }

    private fun sanitizeFileName(name: String): String =
        name.replace(Regex("[/\\\\:*?\"<>|]"), "_").take(200)

    private fun computeMd5(file: File): String {
        val digest = MessageDigest.getInstance("MD5")
        FileInputStream(file).use { fis ->
            val buf = ByteArray(64 * 1024)
            var n: Int
            while (fis.read(buf).also { n = it } != -1) digest.update(buf, 0, n)
        }
        return digest.digest().joinToString("") { "%02x".format(it) }
    }

    fun stop() {
        isRunning = false
        runCatching { serverSocket?.close() }
        serverSocket = null
        scope.coroutineContext.cancelChildren()
    }

    fun destroy() {
        stop()
        scope.cancel()
    }
}
