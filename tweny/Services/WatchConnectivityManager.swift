//
//  WatchConnectivityManager.swift
//  tweny
//
//  iPhone-side WatchConnectivity manager for syncing with Apple Watch
//

import Foundation
import WatchConnectivity
import Combine

class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()
    
    @Published var isReachable = false
    
    private var session: WCSession?
    private var timerManager: TimerManager { TimerManager.shared }
    private var dataManager: DataManager { DataManager.shared }
    
    private override init() {
        super.init()
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }
    
    // MARK: - Send Data to Watch
    
    func sendPresetsToWatch() {
        guard let session = session, session.isReachable else { return }
        
        let presets = dataManager.presets.map { preset -> [String: Any] in
            return [
                "id": preset.id.uuidString,
                "name": preset.name,
                "sessionGoal": preset.sessionGoal,
                "workInterval": preset.workInterval,
                "breakInterval": preset.breakInterval,
                "colorHex": preset.colorHex,
                "icon": preset.icon
            ]
        }
        
        session.sendMessage(["type": "presets", "data": presets], replyHandler: nil)
    }
    
    func sendTimerStateToWatch() {
        guard let session = session, session.isReachable else { return }
        
        let state: [String: Any] = [
            "type": "timerState",
            "phase": timerManager.phase.rawValue,
            "timeRemaining": timerManager.timeRemaining,
            "totalDuration": timerManager.totalDuration,
            "progress": timerManager.progress,
            "sessionElapsed": timerManager.sessionElapsed,
            "sessionGoal": timerManager.sessionGoal,
            "presetName": timerManager.currentPresetName,
            "presetIcon": timerManager.currentPresetIcon,
            "presetColorHex": timerManager.currentPresetColorHex
        ]
        
        session.sendMessage(state, replyHandler: nil)
    }
    
    func updateContextForWatch() {
        guard let session = session, session.activationState == .activated else { return }
        
        let presets = dataManager.presets.map { preset -> [String: Any] in
            return [
                "id": preset.id.uuidString,
                "name": preset.name,
                "sessionGoal": preset.sessionGoal,
                "workInterval": preset.workInterval,
                "breakInterval": preset.breakInterval,
                "colorHex": preset.colorHex,
                "icon": preset.icon
            ]
        }
        
        do {
            try session.updateApplicationContext(["presets": presets])
        } catch {
            print("Error updating context: \(error)")
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
            if activationState == .activated {
                self.updateContextForWatch()
            }
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {}
    
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
            if session.isReachable {
                self.sendPresetsToWatch()
                self.sendTimerStateToWatch()
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            self.handleMessage(message)
        }
    }
    
    private func handleMessage(_ message: [String: Any]) {
        guard let type = message["type"] as? String else { return }
        
        switch type {
        case "startSession":
            if let presetData = message["preset"] as? [String: Any],
               let preset = decodePreset(from: presetData) {
                timerManager.startSession(with: preset)
            }
        case "pauseResume":
            if timerManager.phase == .paused {
                timerManager.resumeSession()
            } else {
                timerManager.pauseSession()
            }
        case "stop":
            timerManager.stopSession()
        case "requestState":
            sendTimerStateToWatch()
            sendPresetsToWatch()
        default:
            break
        }
    }
    
    private func decodePreset(from data: [String: Any]) -> SessionPreset? {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let name = data["name"] as? String,
              let sessionGoal = data["sessionGoal"] as? TimeInterval,
              let workInterval = data["workInterval"] as? TimeInterval,
              let breakInterval = data["breakInterval"] as? TimeInterval,
              let colorHex = data["colorHex"] as? String,
              let icon = data["icon"] as? String else {
            return nil
        }
        
        return SessionPreset(
            id: id,
            name: name,
            sessionGoal: sessionGoal,
            workInterval: workInterval,
            breakInterval: breakInterval,
            colorHex: colorHex,
            icon: icon
        )
    }
}
