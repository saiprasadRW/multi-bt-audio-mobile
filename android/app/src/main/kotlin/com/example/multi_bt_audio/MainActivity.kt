package com.example.multi_bt_audio

import android.app.Activity
import android.bluetooth.*
import android.content.Context
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.lang.reflect.Method

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.example.multi_bt_audio/audio"
    private val MEDIA_PROJECTION_REQUEST_CODE = 1001

    private var bluetoothAdapter: BluetoothAdapter? = null
    private var a2dpProxy: BluetoothA2dp? = null
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val bluetoothManager = getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        bluetoothAdapter = bluetoothManager.adapter

        bluetoothAdapter?.getProfileProxy(this, object : BluetoothProfile.ServiceListener {
            override fun onServiceConnected(profile: Int, proxy: BluetoothProfile?) {
                if (profile == BluetoothProfile.A2DP) a2dpProxy = proxy as BluetoothA2dp
            }
            override fun onServiceDisconnected(profile: Int) {
                if (profile == BluetoothProfile.A2DP) a2dpProxy = null
            }
        }, BluetoothProfile.A2DP)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "isBluetoothEnabled" -> {
                            result.success(bluetoothAdapter?.isEnabled ?: false)
                        }

                        "getPairedDevices" -> {
                            val devices = bluetoothAdapter?.bondedDevices?.map { device ->
                                mapOf(
                                    "name" to (device.name ?: "Unknown"),
                                    "address" to device.address,
                                    "isConnected" to isDeviceConnected(device),
                                    "isAudio" to isAudioDevice(device)
                                )
                            }?.filter { it["isAudio"] == true } ?: emptyList()
                            result.success(devices)
                        }

                        "getConnectedAudioDevices" -> {
                            val devices = a2dpProxy?.connectedDevices?.map { device ->
                                mapOf(
                                    "name" to (device.name ?: "Unknown"),
                                    "address" to device.address,
                                    "isConnected" to true,
                                    "isAudio" to true
                                )
                            } ?: emptyList()
                            result.success(devices)
                        }

                        "connectDevice" -> {
                            val address = call.argument<String>("address")
                            if (address != null) {
                                connectA2dp(address, result)
                            } else {
                                result.error("INVALID", "No address provided", null)
                            }
                        }

                        "disconnectDevice" -> {
                            val address = call.argument<String>("address")
                            if (address != null) {
                                disconnectA2dp(address, result)
                            } else {
                                result.error("INVALID", "No address provided", null)
                            }
                        }

                        "startSystemAudioCapture" -> {
                            pendingResult = result
                            requestMediaProjection(ServiceType.BLUETOOTH)
                        }

                        "startWiFiAudioStream" -> {
                            pendingResult = result
                            requestMediaProjection(ServiceType.WIFI)
                        }

                        "stopSystemAudioCapture" -> {
                            stopService(AudioCaptureService::class.java, AudioCaptureService.ACTION_STOP)
                            result.success(true)
                        }

                        "stopWiFiAudioStream" -> {
                            stopService(WiFiAudioStreamingService::class.java, WiFiAudioStreamingService.ACTION_STOP)
                            result.success(true)
                        }

                        "isCapturing" -> {
                            val btCapturing = AudioCaptureService.isRunning
                            val wifiCapturing = WiFiAudioStreamingService.isRunning
                            result.success(btCapturing || wifiCapturing)
                        }

                        "getMaxConnections" -> {
                            result.success(5)
                        }

                        "getCaptureInfo" -> {
                            val info = if (AudioCaptureService.isRunning) {
                                mapOf(
                                    "isRunning" to true,
                                    "connectedDevices" to AudioCaptureService.connectedDeviceCount,
                                    "platform" to "android",
                                    "mode" to "bluetooth"
                                )
                            } else if (WiFiAudioStreamingService.isRunning) {
                                mapOf(
                                    "isRunning" to true,
                                    "clientCount" to WiFiAudioStreamingService.clientCount,
                                    "platform" to "android",
                                    "mode" to "wifi"
                                )
                            } else {
                                mapOf(
                                    "isRunning" to false,
                                    "platform" to "android"
                                )
                            }
                            result.success(info)
                        }

                        "getWiFiStreamUrl" -> {
                            if (WiFiAudioStreamingService.isRunning) {
                                val ipAddress = getWifiIpAddress()
                                val url = "rtsp://$ipAddress:${WiFiAudioStreamingService.BROADCAST_PORT}"
                                result.success(url)
                            } else {
                                result.success(null)
                            }
                        }

                        "switchToNextDevice" -> {
                            // This would require modifications to AudioCaptureService
                            // to expose a method for manual device switching
                            result.success(false)
                        }

                        "isWiFiConnected" -> {
                            result.success(isWiFiConnected())
                        }

                        else -> result.notImplemented()
                    }
                } catch (e: SecurityException) {
                    result.error("PERMISSION", "Permission required: ${e.message}", null)
                } catch (e: Exception) {
                    result.error("ERROR", "Unexpected error: ${e.message}", null)
                }
            }
    }

    private enum class ServiceType {
        BLUETOOTH, WIFI
    }

    private var pendingServiceType: ServiceType = ServiceType.BLUETOOTH

    private fun requestMediaProjection(serviceType: ServiceType) {
        pendingServiceType = serviceType
        val manager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        startActivityForResult(manager.createScreenCaptureIntent(), MEDIA_PROJECTION_REQUEST_CODE)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == MEDIA_PROJECTION_REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                val serviceIntent = when (pendingServiceType) {
                    ServiceType.BLUETOOTH -> {
                        Intent(this, AudioCaptureService::class.java).apply {
                            action = AudioCaptureService.ACTION_START
                            putExtra(AudioCaptureService.EXTRA_RESULT_CODE, resultCode)
                            putExtra(AudioCaptureService.EXTRA_RESULT_DATA, data)
                        }
                    }
                    ServiceType.WIFI -> {
                        Intent(this, WiFiAudioStreamingService::class.java).apply {
                            action = WiFiAudioStreamingService.ACTION_START
                            putExtra(WiFiAudioStreamingService.EXTRA_RESULT_CODE, resultCode)
                            putExtra(WiFiAudioStreamingService.EXTRA_RESULT_DATA, data)
                        }
                    }
                }

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    startForegroundService(serviceIntent)
                } else {
                    startService(serviceIntent)
                }
                pendingResult?.success(true)
            } else {
                pendingResult?.error("CAPTURE_DENIED", "Audio capture permission denied", null)
            }
            pendingResult = null
        }
    }

    private fun stopService(serviceClass: Class<*>, action: String) {
        val intent = Intent(this, serviceClass).apply {
            this.action = action
        }
        startService(intent)
    }

    private fun isDeviceConnected(device: BluetoothDevice): Boolean {
        return try {
            val method: Method = device.javaClass.getMethod("isConnected")
            method.invoke(device) as Boolean
        } catch (e: Exception) { false }
    }

    private fun isAudioDevice(device: BluetoothDevice): Boolean {
        return try {
            val majorClass = device.bluetoothClass?.majorDeviceClass
            majorClass == 0x0400 || majorClass == 0x0200
        } catch (e: Exception) { true }
    }

    private fun connectA2dp(address: String, result: MethodChannel.Result) {
        try {
            val device = bluetoothAdapter?.getRemoteDevice(address)
            if (device != null && a2dpProxy != null) {
                val method = a2dpProxy!!.javaClass.getMethod("connect", BluetoothDevice::class.java)
                val success = method.invoke(a2dpProxy, device) as Boolean
                Handler(Looper.getMainLooper()).postDelayed({
                    result.success(success)
                }, 2500)
            } else {
                result.error("CONNECT_FAILED", "Device or A2DP proxy not available", null)
            }
        } catch (e: Exception) {
            result.error("CONNECT_FAILED", "Connection failed: ${e.message}", null)
        }
    }

    private fun disconnectA2dp(address: String, result: MethodChannel.Result) {
        try {
            val device = bluetoothAdapter?.getRemoteDevice(address)
            if (device != null && a2dpProxy != null) {
                val method = a2dpProxy!!.javaClass.getMethod("disconnect", BluetoothDevice::class.java)
                val success = method.invoke(a2dpProxy, device) as Boolean
                result.success(success)
            } else {
                result.error("ERROR", "Device not found", null)
            }
        } catch (e: Exception) {
            result.error("ERROR", "Disconnect failed: ${e.message}", null)
        }
    }

    private fun getWifiIpAddress(): String {
        val connectivityManager = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val network = connectivityManager.activeNetwork ?: return "0.0.0.0"
            val networkCapabilities = connectivityManager.getNetworkCapabilities(network) ?: return "0.0.0.0"
            
            if (networkCapabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)) {
                val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as android.net.wifi.WifiManager
                val ipInt = wifiManager.connectionInfo.ipAddress
                return String.format(
                    "%d.%d.%d.%d",
                    ipInt and 0xff,
                    ipInt shr 8 and 0xff,
                    ipInt shr 16 and 0xff,
                    ipInt shr 24 and 0xff
                )
            }
        }
        return "0.0.0.0"
    }

    private fun isWiFiConnected(): Boolean {
        val connectivityManager = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val network = connectivityManager.activeNetwork ?: return false
            val networkCapabilities = connectivityManager.getNetworkCapabilities(network) ?: return false
            return networkCapabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)
        }
        return false
    }

    override fun onDestroy() {
        if (a2dpProxy != null) {
            bluetoothAdapter?.closeProfileProxy(BluetoothProfile.A2DP, a2dpProxy)
        }
        super.onDestroy()
    }
}