package com.example.multi_bt_audio

import android.app.Activity
import android.bluetooth.*
import android.content.Context
import android.content.Intent
import android.media.projection.MediaProjectionManager
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
                            requestMediaProjection()
                        }

                        "stopSystemAudioCapture" -> {
                            val intent = Intent(this, AudioCaptureService::class.java).apply {
                                action = AudioCaptureService.ACTION_STOP
                            }
                            startService(intent)
                            result.success(true)
                        }

                        "isCapturing" -> {
                            result.success(AudioCaptureService.isRunning)
                        }

                        "getMaxConnections" -> {
                            result.success(5)
                        }

                        "getCaptureInfo" -> {
                            result.success(mapOf(
                                "isRunning" to AudioCaptureService.isRunning,
                                "connectedDevices" to AudioCaptureService.connectedDeviceCount,
                                "platform" to "android"
                            ))
                        }

                        else -> result.notImplemented()
                    }
                } catch (e: SecurityException) {
                    result.error("PERMISSION", "Bluetooth permission required: ${e.message}", null)
                } catch (e: Exception) {
                    result.error("ERROR", "Unexpected error: ${e.message}", null)
                }
            }
    }

    private fun requestMediaProjection() {
        val manager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        startActivityForResult(manager.createScreenCaptureIntent(), MEDIA_PROJECTION_REQUEST_CODE)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == MEDIA_PROJECTION_REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                val serviceIntent = Intent(this, AudioCaptureService::class.java).apply {
                    action = AudioCaptureService.ACTION_START
                    putExtra(AudioCaptureService.EXTRA_RESULT_CODE, resultCode)
                    putExtra(AudioCaptureService.EXTRA_RESULT_DATA, data)
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

    override fun onDestroy() {
        if (a2dpProxy != null) {
            bluetoothAdapter?.closeProfileProxy(BluetoothProfile.A2DP, a2dpProxy)
        }
        super.onDestroy()
    }
}