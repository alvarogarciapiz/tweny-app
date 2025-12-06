//
//  WatchSessionManager.swift
//  twenywatch Watch App
//
//  Watch-side session manager for syncing with iPhone
//

import Foundation
import WatchConnectivity
import Combine

// Local copy of SessionPreset for Watch
struct WatchPreset: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var sessionGoal: TimeInterval
    var workInterval: TimeInterval
    var breakInterval: TimeInterval
    var colorHex: String
    var icon: String
}

enum WatchTimerPhase: String {
    case idle, work, breakTime, paused
}

class WatchSessionManager: NSObject, ObservableObject {
    static let shared = WatchSessionManager()
    
    // Presets from iPhone
    @Published var presets: [WatchPreset] = []
    
    // Timer state
    @Published var phase: WatchTimerPhase = .idle
    @Published var timeRemaining: TimeInterval = 0
    @Published var totalDuration: TimeInterval = 0
    @Published var progress: Double = 0
    @Published var sessionElapsed: TimeInterval = 0
    @Published var sessionGoal: TimeInterval = 0
    @Published var currentPresetName: String = ""
    @Published var currentPresetIcon: String = "⏳"
    @Published var currentPresetColorHex: String = "#007AFF"
    
    @Published var isConnected = false
    
    private var session: WCSession?
    
    private override init() {
        super.init()
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }
    
    var isSessionActive: Bool {
        phase != .idle
    }
    
    var isBreak: Bool {
        phase == .breakTime
    }
    
    // MARK: - Commands to iPhone
    
    func startSession(with preset: WatchPreset) {
        guard let session = session, session.isReachable else { return }
        
        let presetData: [String: Any] = [
            "id": preset.id.uuidString,
            "name": preset.name,
            "sessionGoal": preset.sessionGoal,
            "workInterval": preset.workInterval,
            "breakInterval": preset.breakInterval,
            "colorHex": preset.colorHex,
            "icon": preset.icon
        ]
        
        session.sendMessage(["type": "startSession", "preset": presetData], replyHandler: nil)
    }
    
    func togglePauseResume() {
        guard let session = session, session.isReachable else { return }
        session.sendMessage(["type": "pauseResume"], replyHandler: nil)
    }
    
    func stopSession() {
        guard let session = session, session.isReachable else { return }
        session.sendMessage(["type": "stop"], replyHandler: nil)
    }
    
    func requestState() {
        guard let session = session, session.isReachable else { return }
        session.sendMessage(["type": "requestState"], replyHandler: nil)
    }
}

// MARK: - WCSessionDelegate

extension WatchSessionManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isConnected = session.isReachable
            // Load presets from context if available
            if let presets = session.receivedApplicationContext["presets"] as? [[String: Any]] {
                self.updatePresets(from: presets)
            }
            self.requestState()
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isConnected = session.isReachable
            if session.isReachable {
                self.requestState()
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        DispatchQueue.main.async {
            if let presets = applicationContext["presets"] as? [[String: Any]] {
                self.updatePresets(from: presets)
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            self.handleMessage(message)
        }
    }
    
    private func handleMessage(_ message: [String: Any]) {
        if let type = message["type"] as? String {
            switch type {
            case "presets":
                if let data = message["data"] as? [[String: Any]] {
                    updatePresets(from: data)
                }
            case "timerState":
                updateTimerState(from: message)
            default:
                break
            }
        } else {
            // Direct timer state update
            updateTimerState(from: message)
        }
    }
    
    private func updatePresets(from data: [[String: Any]]) {
        presets = data.compactMap { dict -> WatchPreset? in
            guard let idString = dict["id"] as? String,
                  let id = UUID(uuidString: idString),
                  let name = dict["name"] as? String,
                  let sessionGoal = dict["sessionGoal"] as? TimeInterval,
                  let workInterval = dict["workInterval"] as? TimeInterval,
                  let breakInterval = dict["breakInterval"] as? TimeInterval,
                  let colorHex = dict["colorHex"] as? String,
                  let icon = dict["icon"] as? String else {
                return nil
            }
            return WatchPreset(
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
    
    private func updateTimerState(from message: [String: Any]) {
        if let phaseRaw = message["phase"] as? String {
            switch phaseRaw {
            case "work": phase = .work
            case "breakTime": phase = .breakTime
            case "paused": phase = .paused
            default: phase = .idle
            }
        }
        
        if let tr = message["timeRemaining"] as? TimeInterval { timeRemaining = tr }
        if let td = message["totalDuration"] as? TimeInterval { totalDuration = td }
        if let p = message["progress"] as? Double { progress = p }
        if let se = message["sessionElapsed"] as? TimeInterval { sessionElapsed = se }
        if let sg = message["sessionGoal"] as? TimeInterval { sessionGoal = sg }
        if let pn = message["presetName"] as? String { currentPresetName = pn }
        if let pi = message["presetIcon"] as? String { currentPresetIcon = pi }
        if let pc = message["presetColorHex"] as? String { currentPresetColorHex = pc }
    }
}
