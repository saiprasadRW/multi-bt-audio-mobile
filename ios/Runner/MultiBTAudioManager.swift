import Foundation
import AVFoundation
import CoreBluetooth
import MediaPlayer

class MultiBTAudioManager: NSObject {
    
    private var audioSession: AVAudioSession = AVAudioSession.sharedInstance()
    private var audioEngine: AVAudioEngine?
    private var centralManager: CBCentralManager?
    private var isRoutingActive = false
    private var connectedOutputs: [AVAudioSessionPortDescription] = []
    
    // Error types
    enum AudioError: LocalizedError {
        case bluetoothUnavailable
        case noOutputDevices
        case audioSessionFailed(String)
        case routingFailed(String)
        case notEnoughDevices
        
        var errorDescription: String? {
            switch self {
            case .bluetoothUnavailable:
                return "Bluetooth is not available on this device"
            case .noOutputDevices:
                return "No Bluetooth audio output devices found"
            case .audioSessionFailed(let msg):
                return "Audio session error: \(msg)"
            case .routingFailed(let msg):
                return "Audio routing error: \(msg)"
            case .notEnoughDevices:
                return "Connect at least 2 Bluetooth devices"
            }
        }
    }
    
    var isRouting: Bool { return isRoutingActive }
    
    var connectedDeviceCount: Int {
        return getBluetoothOutputs().count
    }
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: nil, queue: nil)
        setupAudioSessionNotifications()
    }
    
    // MARK: - Bluetooth State
    
    func isBluetoothEnabled() -> Bool {
        return centralManager?.state == .poweredOn
    }
    
    // MARK: - Device Discovery
    
    func getConnectedAudioDevices(completion: @escaping ([[String: Any]]) -> Void) {
        let outputs = getBluetoothOutputs()
        
        let devices: [[String: Any]] = outputs.map { port in
            return [
                "name": port.portName,
                "address": port.uid,
                "isConnected": true,
                "isAudio": true
            ]
        }
        
        // Also check for available inputs (some BT devices show here)
        let inputs = getBluetoothInputs()
        var allDevices = devices
        
        for input in inputs {
            if !allDevices.contains(where: { ($0["address"] as? String) == input.uid }) {
                allDevices.append([
                    "name": input.portName,
                    "address": input.uid,
                    "isConnected": true,
                    "isAudio": true
                ])
            }
        }
        
        completion(allDevices)
    }
    
    private func getBluetoothOutputs() -> [AVAudioSessionPortDescription] {
        let currentRoute = audioSession.currentRoute
        let btOutputs = currentRoute.outputs.filter { port in
            return port.portType == .bluetoothA2DP ||
                   port.portType == .bluetoothLE ||
                   port.portType == .bluetoothHFP
        }
        return btOutputs
    }
    
    private func getBluetoothInputs() -> [AVAudioSessionPortDescription] {
        guard let inputs = audioSession.availableInputs else { return [] }
        return inputs.filter { port in
            return port.portType == .bluetoothHFP ||
                   port.portType == .bluetoothLE
        }
    }
    
    // MARK: - Multi-Device Audio Routing
    
    func startMultiDeviceRouting(completion: @escaping (Bool, Error?) -> Void) {
        do {
            // Configure audio session for multi-route
            try configureMultiRouteSession()
            
            // Start audio engine for routing
            try startAudioEngine()
            
            isRoutingActive = true
            
            print("[MultiBTAudio] Multi-device routing started")
            print("[MultiBTAudio] Connected outputs: \(connectedDeviceCount)")
            
            completion(true, nil)
            
        } catch {
            print("[MultiBTAudio] Failed to start routing: \(error)")
            isRoutingActive = false
            completion(false, error)
        }
    }
    
    func stopMultiDeviceRouting() {
        audioEngine?.stop()
        audioEngine = nil
        isRoutingActive = false
        
        // Reset audio session
        do {
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("[MultiBTAudio] Error deactivating session: \(error)")
        }
        
        print("[MultiBTAudio] Multi-device routing stopped")
    }
    
    // MARK: - Audio Session Configuration
    
    private func configureMultiRouteSession() throws {
        /*
         iOS Audio Routing Strategy:
         
         Method 1: AVAudioSessionCategoryMultiRoute
         - Allows output to multiple ports simultaneously
         - Supported since iOS 6
         - Works with BT + Speaker, BT + Wired, etc.
         
         Method 2: AVAudioSessionCategoryPlayback with mixWithOthers
         - More compatible
         - Allows our app's audio to mix with others
         
         Method 3: kAudioSessionProperty_OverrideAudioRoute (deprecated but functional)
         
         We use Method 1 as primary, Method 2 as fallback
        */
        
        // Try MultiRoute first (allows simultaneous outputs)
        do {
            try audioSession.setCategory(
                .multiRoute,
                mode: .default,
                options: [.allowBluetooth, .allowBluetoothA2DP]
            )
            try audioSession.setActive(true)
            print("[MultiBTAudio] MultiRoute category set successfully")
            return
        } catch {
            print("[MultiBTAudio] MultiRoute failed, trying fallback: \(error)")
        }
        
        // Fallback: Use playback category with bluetooth options
        do {
            try audioSession.setCategory(
                .playback,
                mode: .default,
                options: [
                    .allowBluetooth,
                    .allowBluetoothA2DP,
                    .mixWithOthers,
                    .duckOthers
                ]
            )
            try audioSession.setActive(true)
            print("[MultiBTAudio] Playback category set as fallback")
        } catch {
            throw AudioError.audioSessionFailed(error.localizedDescription)
        }
    }
    
    private func startAudioEngine() throws {
        audioEngine = AVAudioEngine()
        
        guard let engine = audioEngine else {
            throw AudioError.routingFailed("Failed to create audio engine")
        }
        
        let mainMixer = engine.mainMixerNode
        let output = engine.outputNode
        
        let format = output.inputFormat(forBus: 0)
        
        // Install tap on main mixer to capture and re-route audio
        mainMixer.installTap(
            onBus: 0,
            bufferSize: 4096,
            format: format
        ) { [weak self] (buffer, time) in
            // Audio data flows through here
            // With MultiRoute category, iOS handles routing to multiple outputs
            self?.processAudioBuffer(buffer: buffer, time: time)
        }
        
        engine.prepare()
        try engine.start()
        
        print("[MultiBTAudio] Audio engine started")
    }
    
    private func processAudioBuffer(buffer: AVAudioPCMBuffer, time: AVAudioTime) {
        // The audio buffer is being processed
        // With MultiRoute category, iOS automatically routes to all available outputs
        // Additional processing can be done here if needed
    }
    
    // MARK: - Route Change Notifications
    
    private func setupAudioSessionNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }
    
    @objc private func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue)
        else { return }
        
        switch reason {
        case .newDeviceAvailable:
            print("[MultiBTAudio] New audio device connected")
            refreshConnectedDevices()
            
        case .oldDeviceUnavailable:
            print("[MultiBTAudio] Audio device disconnected")
            refreshConnectedDevices()
            
            // If no more BT devices, stop routing
            if connectedDeviceCount == 0 && isRoutingActive {
                print("[MultiBTAudio] All devices disconnected, stopping routing")
                stopMultiDeviceRouting()
            }
            
        case .categoryChange:
            print("[MultiBTAudio] Audio category changed")
            
        case .override:
            print("[MultiBTAudio] Audio route override")
            
        default:
            print("[MultiBTAudio] Route change: \(reason.rawValue)")
        }
    }
    
    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else { return }
        
        switch type {
        case .began:
            print("[MultiBTAudio] Audio interruption began (phone call, etc.)")
            // Pause routing but don't stop
            audioEngine?.pause()
            
        case .ended:
            print("[MultiBTAudio] Audio interruption ended")
            if isRoutingActive {
                do {
                    try audioEngine?.start()
                    print("[MultiBTAudio] Audio engine resumed after interruption")
                } catch {
                    print("[MultiBTAudio] Failed to resume: \(error)")
                }
            }
            
        @unknown default:
            break
        }
    }
    
    private func refreshConnectedDevices() {
        connectedOutputs = getBluetoothOutputs()
        print("[MultiBTAudio] Connected BT outputs: \(connectedOutputs.count)")
        for output in connectedOutputs {
            print("[MultiBTAudio]   - \(output.portName) (\(output.portType.rawValue))")
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        stopMultiDeviceRouting()
    }
}