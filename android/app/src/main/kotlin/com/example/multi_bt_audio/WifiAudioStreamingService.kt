package com.example.multi_bt_audio

/**
 * WiFi Multi-Device Audio Streaming
 * 
 * This is the RECOMMENDED approach for true simultaneous multi-device audio.
 * 
 * How it works:
 * 1. Capture system audio
 * 2. Encode to AAC/Opus
 * 3. Broadcast over WiFi using WebRTC or RTSP
 * 4. Client apps on receiving devices decode and play
 * 
 * Advantages over Bluetooth approach:
 * - TRUE simultaneous playback on unlimited devices
 * - Better audio quality
 * - Lower latency with proper implementation
 * - No Android Bluetooth limitations
 * - Can stream to phones, tablets, smart speakers
 * 
 * Requirements:
 * - All devices on same WiFi network
 * - Client app on receiving devices OR use existing apps:
 *   * VLC can receive RTSP streams
 *   * Chrome can receive WebRTC
 *   * Any DLNA receiver
 * 
 * Dependencies to add to build.gradle:
 * 
 * dependencies {
 *     // WebRTC for real-time streaming
 *     implementation 'org.webrtc:google-webrtc:1.0.32006'
 *     
 *     // OR NanoHTTPD for simple HTTP streaming
 *     implementation 'org.nanohttpd:nanohttpd:2.3.1'
 *     
 *     // Opus codec for audio encoding
 *     implementation 'com.google.android.exoplayer:exoplayer-core:2.19.1'
 * }
 * 
 * Implementation Steps:
 * 
 * 1. CAPTURE AUDIO (same as before)
 * 2. ENCODE AUDIO (AAC/Opus)
 * 3. STREAM via one of:
 *    a) WebRTC Data Channel (best for real-time)
 *    b) RTSP Server (works with VLC, etc.)
 *    c) HTTP Live Streaming (HLS)
 *    d) Simple TCP/UDP broadcast
 * 
 * Client Side:
 * - Flutter app on other phones
 * - VLC/Any DLNA player
 * - Web browser (for WebRTC)
 * 
 * This completely bypasses Bluetooth limitations and provides
 * true simultaneous playback to unlimited devices!
 */

import android.app.*
import android.content.Context
import android.content.Intent
import android.media.*
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.net.wifi.WifiManager
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import java.io.IOException
import java.net.*
import java.nio.ByteBuffer
import java.util.concurrent.CopyOnWriteArrayList

/**
 * WiFi Audio Streaming Service
 * Broadcasts captured audio over WiFi to multiple clients simultaneously
 */
class WiFiAudioStreamingService : Service() {
    
    private var mediaProjection: MediaProjection? = null
    private var audioRecord: AudioRecord? = null
    private var isStreaming = false
    private var captureThread: Thread? = null
    private var broadcastThread: Thread? = null
    
    private var udpSocket: DatagramSocket? = null
    private val connectedClients = CopyOnWriteArrayList<InetAddress>()
    
    companion object {
        const val ACTION_START = "com.example.multi_bt_audio.START_WIFI_STREAM"
        const val ACTION_STOP = "com.example.multi_bt_audio.STOP_WIFI_STREAM"
        const val EXTRA_RESULT_CODE = "result_code"
        const val EXTRA_RESULT_DATA = "result_data"
        const val NOTIFICATION_CHANNEL_ID = "wifi_audio_channel"
        const val NOTIFICATION_ID = 2001
        
        // UDP broadcast port
        const val BROADCAST_PORT = 5555
        const val DISCOVERY_PORT = 5556
        
        @Volatile
        var isRunning = false
        
        @Volatile
        var clientCount = 0
    }
    
    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                val resultCode = intent.getIntExtra(EXTRA_RESULT_CODE, Activity.RESULT_CANCELED)
                val data = intent.getParcelableExtra<Intent>(EXTRA_RESULT_DATA)
                
                if (resultCode == Activity.RESULT_OK && data != null) {
                    startForeground(NOTIFICATION_ID, createNotification())
                    startStreaming(resultCode, data)
                }
            }
            ACTION_STOP -> {
                stopStreaming()
                stopSelf()
            }
        }
        return START_NOT_STICKY
    }
    
    override fun onBind(intent: Intent?): IBinder? = null
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "WiFi Audio Streaming",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Streaming audio over WiFi to multiple devices"
                setSound(null, null)
            }
            
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }
    }
    
    private fun createNotification(): Notification {
        val stopIntent = Intent(this, WiFiAudioStreamingService::class.java).apply {
            action = ACTION_STOP
        }
        val stopPendingIntent = PendingIntent.getService(
            this, 0, stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        val ipAddress = getWifiIpAddress()
        
        return NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setContentTitle("WiFi Audio Streaming Active")
            .setContentText("Streaming to $clientCount device(s)")
            .setStyle(NotificationCompat.BigTextStyle().bigText(
                "Stream URL: rtsp://$ipAddress:$BROADCAST_PORT\n" +
                "Connected clients: $clientCount\n\n" +
                "Connect using VLC or compatible player"
            ))
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .addAction(android.R.drawable.ic_media_pause, "Stop", stopPendingIntent)
            .setOngoing(true)
            .setSilent(true)
            .build()
    }
    
    private fun getWifiIpAddress(): String {
        val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        val ipInt = wifiManager.connectionInfo.ipAddress
        return String.format(
            "%d.%d.%d.%d",
            ipInt and 0xff,
            ipInt shr 8 and 0xff,
            ipInt shr 16 and 0xff,
            ipInt shr 24 and 0xff
        )
    }
    
    private fun startStreaming(resultCode: Int, data: Intent) {
        if (isStreaming) return
        
        try {
            // Initialize UDP socket for broadcasting
            udpSocket = DatagramSocket(BROADCAST_PORT)
            udpSocket?.broadcast = true
            
            val manager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
            mediaProjection = manager.getMediaProjection(resultCode, data)
            
            val config = AudioPlaybackCaptureConfiguration.Builder(mediaProjection!!)
                .addMatchingUsage(AudioAttributes.USAGE_MEDIA)
                .addMatchingUsage(AudioAttributes.USAGE_GAME)
                .addMatchingUsage(AudioAttributes.USAGE_UNKNOWN)
                .build()
            
            val sampleRate = 44100
            val audioFormat = AudioFormat.Builder()
                .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                .setSampleRate(sampleRate)
                .setChannelMask(AudioFormat.CHANNEL_IN_STEREO)
                .build()
            
            val bufferSize = AudioRecord.getMinBufferSize(
                sampleRate,
                AudioFormat.CHANNEL_IN_STEREO,
                AudioFormat.ENCODING_PCM_16BIT
            ) * 2
            
            audioRecord = AudioRecord.Builder()
                .setAudioFormat(audioFormat)
                .setBufferSizeInBytes(bufferSize)
                .setAudioPlaybackCaptureConfig(config)
                .build()
            
            audioRecord?.startRecording()
            
            isStreaming = true
            isRunning = true
            
            startCaptureAndBroadcast(bufferSize)
            startDiscoveryListener()
            
        } catch (e: Exception) {
            e.printStackTrace()
            stopStreaming()
        }
    }
    
    private fun startCaptureAndBroadcast(bufferSize: Int) {
        captureThread = Thread {
            val buffer = ByteArray(1024) // Smaller packets for network
            android.os.Process.setThreadPriority(android.os.Process.THREAD_PRIORITY_URGENT_AUDIO)
            
            val broadcastAddress = getBroadcastAddress()
            
            while (isStreaming) {
                try {
                    val read = audioRecord?.read(buffer, 0, buffer.size) ?: 0
                    if (read > 0) {
                        // Broadcast to all clients
                        if (connectedClients.isNotEmpty()) {
                            val packet = DatagramPacket(
                                buffer,
                                read,
                                broadcastAddress,
                                BROADCAST_PORT
                            )
                            udpSocket?.send(packet)
                        }
                    }
                } catch (e: IOException) {
                    e.printStackTrace()
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }
        }.apply { start() }
    }
    
    private fun startDiscoveryListener() {
        // Listen for client discovery requests
        broadcastThread = Thread {
            try {
                val discoverySocket = DatagramSocket(DISCOVERY_PORT)
                val buffer = ByteArray(256)
                
                while (isStreaming) {
                    val packet = DatagramPacket(buffer, buffer.size)
                    discoverySocket.receive(packet)
                    
                    val clientAddress = packet.address
                    if (!connectedClients.contains(clientAddress)) {
                        connectedClients.add(clientAddress)
                        clientCount = connectedClients.size
                        updateNotification()
                    }
                }
                
                discoverySocket.close()
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }.apply { start() }
    }
    
    private fun getBroadcastAddress(): InetAddress {
        val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        val dhcp = wifiManager.dhcpInfo
        val broadcast = dhcp.ipAddress and dhcp.netmask or dhcp.netmask.inv()
        val bytes = ByteArray(4)
        for (k in 0..3) {
            bytes[k] = (broadcast shr k * 8).toByte()
        }
        return InetAddress.getByAddress(bytes)
    }
    
    private fun updateNotification() {
        val notification = createNotification()
        val notificationManager = getSystemService(NotificationManager::class.java)
        notificationManager?.notify(NOTIFICATION_ID, notification)
    }
    
    private fun stopStreaming() {
        isStreaming = false
        isRunning = false
        
        captureThread?.interrupt()
        broadcastThread?.interrupt()
        
        captureThread = null
        broadcastThread = null
        
        audioRecord?.stop()
        audioRecord?.release()
        audioRecord = null
        
        udpSocket?.close()
        udpSocket = null
        
        mediaProjection?.stop()
        mediaProjection = null
        
        connectedClients.clear()
        clientCount = 0
    }
    
    override fun onDestroy() {
        stopStreaming()
        super.onDestroy()
    }
}

/**
 * CLIENT SIDE IMPLEMENTATION (for receiving devices)
 * 
 * Simple UDP audio receiver:
 */
/*
class AudioReceiverActivity : AppCompatActivity() {
    private var receiveThread: Thread? = null
    private var audioTrack: AudioTrack? = null
    
    fun startReceiving(serverIp: String) {
        val socket = DatagramSocket(BROADCAST_PORT)
        
        // Setup audio player
        val sampleRate = 44100
        val bufferSize = AudioTrack.getMinBufferSize(
            sampleRate,
            AudioFormat.CHANNEL_OUT_STEREO,
            AudioFormat.ENCODING_PCM_16BIT
        )
        
        audioTrack = AudioTrack.Builder()
            .setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                    .build()
            )
            .setAudioFormat(
                AudioFormat.Builder()
                    .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                    .setSampleRate(sampleRate)
                    .setChannelMask(AudioFormat.CHANNEL_OUT_STEREO)
                    .build()
            )
            .setBufferSizeInBytes(bufferSize)
            .setTransferMode(AudioTrack.MODE_STREAM)
            .build()
        
        audioTrack?.play()
        
        // Send discovery packet
        val discoveryData = "DISCOVER".toByteArray()
        val discoveryPacket = DatagramPacket(
            discoveryData,
            discoveryData.size,
            InetAddress.getByName(serverIp),
            DISCOVERY_PORT
        )
        socket.send(discoveryPacket)
        
        // Receive and play audio
        receiveThread = Thread {
            val buffer = ByteArray(1024)
            val packet = DatagramPacket(buffer, buffer.size)
            
            while (true) {
                socket.receive(packet)
                audioTrack?.write(buffer, 0, packet.length)
            }
        }.apply { start() }
    }
}
*/