import UIKit
import Flutter
import AVFoundation
import CoreBluetooth
import MediaPlayer

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    
    private var audioManager: MultiBTAudioManager?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        let controller = window?.rootViewController as! FlutterViewController
        let channel = FlutterMethodChannel(
            name: "com.example.multi_bt_audio/audio",
            binaryMessenger: controller.binaryMessenger
        )
        
        audioManager = MultiBTAudioManager()
        
        channel.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else {
                result(FlutterError(code: "DEALLOCATED", message: "Manager deallocated", details: nil))
                return
            }
            
            switch call.method {
            case "isBluetoothEnabled":
                result(self.audioManager?.isBluetoothEnabled() ?? false)
                
            case "getPairedDevices":
                self.audioManager?.getConnectedAudioDevices { devices in
                    result(devices)
                }
                
            case "getConnectedAudioDevices":
                self.audioManager?.getConnectedAudioDevices { devices in
                    result(devices)
                }
                
            case "connectDevice":
                // iOS manages BT connections at system level
                // We handle audio routing instead
                result(true)
                
            case "disconnectDevice":
                result(true)
                
            case "startAudioRouting":
                self.audioManager?.startMultiDeviceRouting { success, error in
                    if let error = error {
                        result(FlutterError(
                            code: "CAPTURE_FAILED",
                            message: error.localizedDescription,
                            details: nil
                        ))
                    } else {
                        result(success)
                    }
                }
                
            case "stopAudioRouting":
                self.audioManager?.stopMultiDeviceRouting()
                result(true)
                
            case "isCapturing":
                result(self.audioManager?.isRouting ?? false)
                
            case "getMaxConnections":
                result(2)
                
            case "getCaptureInfo":
                let info: [String: Any] = [
                    "isRunning": self.audioManager?.isRouting ?? false,
                    "connectedDevices": self.audioManager?.connectedDeviceCount ?? 0,
                    "platform": "ios"
                ]
                result(info)
                
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}