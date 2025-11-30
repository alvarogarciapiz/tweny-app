//
//  TimerManager.swift
//  tweny
//
//  Created by GitHub Copilot on 29/11/25.
//

import SwiftUI
import Combine
import ActivityKit
import CoreData

class TimerManager: ObservableObject {
    static let shared = TimerManager()
    
    @Published var phase: TimerPhase = .idle
    @Published var timeRemaining: TimeInterval = 20 * 60
    @Published var totalDuration: TimeInterval = 20 * 60
    @Published var progress: Double = 0.0
    @Published var sessionStartTime: Date?
    
    // Session Goal Management
    @Published var sessionGoal: TimeInterval = 4 * 60 * 60 // Default 4 hours
    @Published var sessionElapsed: TimeInterval = 0
    @Published var currentPresetIcon: String = "⏳"
    @Published var currentPresetName: String = "Focus Session"
    
    private var timer: AnyCancellable?
    private var configuration = TimerConfiguration()
    private var prePausePhase: TimerPhase = .work
    private var sessionTargetDate: Date?
    
    // Debug Mode
    static let isDebugMode = true // Set to true to speed up time for testing
    
    // Live Activity
    private var currentActivity: Activity<TwenyAttributes>?
    
    init() {
        // Register defaults
        UserDefaults.standard.register(defaults: [
            "dailyGoalHours": 4.0,
            "workDuration": 20.0,
            "breakDuration": 20.0,
            "isSoundEnabled": true,
            "isHapticsEnabled": true
        ])
        
        // Load configuration
        let goalHours = UserDefaults.standard.double(forKey: "dailyGoalHours")
        sessionGoal = goalHours * 3600
        
        let workMinutes = UserDefaults.standard.double(forKey: "workDuration")
        configuration.workDuration = workMinutes * 60
        
        let breakSeconds = UserDefaults.standard.double(forKey: "breakDuration")
        configuration.breakDuration = breakSeconds
        
        configuration.isSoundEnabled = UserDefaults.standard.bool(forKey: "isSoundEnabled")
        configuration.isHapticsEnabled = UserDefaults.standard.bool(forKey: "isHapticsEnabled")
    }
    
    func startSession(with preset: SessionPreset? = nil) {
        // Ensure any existing activity is ended before starting a new one
        endLiveActivity()
        
        if let preset = preset {
            sessionGoal = preset.sessionGoal
            configuration.workDuration = preset.workInterval
            configuration.breakDuration = preset.breakInterval
            currentPresetIcon = preset.icon
            currentPresetName = preset.name
        } else {
            currentPresetIcon = "⏳"
            currentPresetName = "Quick Session"
        }
        
        phase = .work
        sessionElapsed = 0
        
        // In debug mode, use short intervals. In normal mode, use 20 min.
        totalDuration = TimerManager.isDebugMode ? 10 : configuration.workDuration
        timeRemaining = totalDuration
        
        sessionStartTime = Date()
        sessionTargetDate = Date().addingTimeInterval(totalDuration)
        startTimer()
        scheduleNotificationForBreak()
        startLiveActivity()
    }
    
    func pauseSession() {
        if phase != .paused {
            prePausePhase = phase
        }
        phase = .paused
        sessionTargetDate = nil
        timer?.cancel()
        NotificationManager.shared.cancelAllNotifications()
        updateLiveActivity()
    }
    
    func resumeSession() {
        if timeRemaining > 0 {
            phase = prePausePhase
            sessionTargetDate = Date().addingTimeInterval(timeRemaining)
            startTimer()
            if phase == .work {
                scheduleNotificationForBreak()
            }
            updateLiveActivity()
        }
    }
    
    func stopSession() {
        phase = .idle
        timer?.cancel()
        timeRemaining = configuration.workDuration
        progress = 0.0
        sessionElapsed = 0
        NotificationManager.shared.cancelAllNotifications()
        endLiveActivity()
        
        // Save session to CoreData
        saveSession()
    }
    
    private func startTimer() {
        timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            self?.tick()
        }
    }
    
    private func tick() {
        guard phase != .idle && phase != .paused else { return }
        
        sessionElapsed += 1
        
        if sessionElapsed >= sessionGoal {
            // Session Goal Reached
            stopSession()
            // Ideally show a "Goal Reached" modal or notification here
            NotificationManager.shared.scheduleNotification(title: "Goal Reached!", body: "You've completed your session goal.", timeInterval: 1)
            return
        }
        
        if timeRemaining > 0 {
            timeRemaining -= 1
            progress = 1.0 - (timeRemaining / totalDuration)
            updateLiveActivity()
        } else {
            handlePhaseCompletion()
        }
    }
    
    private func handlePhaseCompletion() {
        if phase == .work {
            startBreak()
        } else if phase == .breakTime {
            startWork()
        }
    }
    
    private func startBreak() {
        phase = .breakTime
        // Randomized break duration: 20-25 seconds
        let randomBreak = TimerManager.isDebugMode ? 5 : Double.random(in: 20...25)
        totalDuration = randomBreak
        timeRemaining = totalDuration
        progress = 0.0
        sessionTargetDate = Date().addingTimeInterval(totalDuration)
        
        if configuration.isSoundEnabled {
            // Play sound
        }
        if configuration.isHapticsEnabled {
            HapticsManager.shared.playSuccess()
        }
        
        NotificationManager.shared.scheduleNotification(title: "Break Over!", body: "Time to focus again.", timeInterval: totalDuration, soundName: "ping.aiff")
        updateLiveActivity()
    }
    
    private func startWork() {
        phase = .work
        totalDuration = TimerManager.isDebugMode ? 10 : configuration.workDuration
        timeRemaining = totalDuration
        progress = 0.0
        sessionTargetDate = Date().addingTimeInterval(totalDuration)
        
        if configuration.isHapticsEnabled {
            HapticsManager.shared.playLightImpact()
        }
        
        scheduleNotificationForBreak()
        updateLiveActivity()
    }
    
    private func scheduleNotificationForBreak() {
        NotificationManager.shared.scheduleNotification(title: "Time for a break!", body: "Look away for 20 seconds.", timeInterval: timeRemaining, soundName: "ping.aiff")
    }
    
    private func saveSession() {
        guard let start = sessionStartTime else { return }
        let end = Date()
        let duration = end.timeIntervalSince(start)
        
        // CoreData saving logic will be handled by a DataManager or directly here if we import CoreData
        // For separation of concerns, let's use a delegate or closure, or just access PersistenceController
        let context = PersistenceController.shared.container.viewContext
        let session = SessionLog(context: context)
        session.id = UUID()
        session.startTime = start
        session.endTime = end
        session.duration = duration
        // session.breaksTaken = ... // We need to track this
        
        do {
            try context.save()
        } catch {
            print("Failed to save session: \(error)")
        }
    }
    
    func updateConfiguration(workMinutes: Double, breakSeconds: Double) {
        configuration.workDuration = workMinutes * 60
        configuration.breakDuration = breakSeconds
    }
    
    // MARK: - Live Activity
    
    private func startLiveActivity() {
        let attributes = TwenyAttributes(
            sessionName: "Eye Care Session",
            intervalDuration: totalDuration,
            sessionGoal: sessionGoal
        )
        
        let sessionEnd = sessionStartTime?.addingTimeInterval(sessionGoal)
        
        let initialState = TwenyAttributes.ContentState(
            timeRemaining: timeRemaining,
            progress: progress,
            phase: phase == .work ? "Focus" : "Break",
            statusMessage: phase == .work ? "Keep focusing" : "Look away!",
            sessionElapsed: sessionElapsed,
            targetTime: sessionTargetDate,
            sessionStartTime: sessionStartTime,
            sessionEndTime: sessionEnd
        )
        
        do {
            currentActivity = try Activity.request(attributes: attributes, content: ActivityContent(state: initialState, staleDate: nil))
        } catch {
            print("Error starting live activity: \(error)")
        }
    }
    
    private func updateLiveActivity() {
        let statusMessage: String
        if phase == .work {
            statusMessage = "Focus time"
        } else if phase == .paused {
            statusMessage = "Session Paused"
        } else {
            statusMessage = "Look 20m away!"
        }
        
        let sessionEnd = sessionStartTime?.addingTimeInterval(sessionGoal)
        
        let updatedState = TwenyAttributes.ContentState(
            timeRemaining: timeRemaining,
            progress: progress,
            phase: phase == .work ? "Focus" : (phase == .paused ? "Paused" : "Break"),
            statusMessage: statusMessage,
            sessionElapsed: sessionElapsed,
            targetTime: sessionTargetDate,
            sessionStartTime: sessionStartTime,
            sessionEndTime: sessionEnd
        )
        
        Task {
            await currentActivity?.update(ActivityContent(state: updatedState, staleDate: nil))
        }
    }
    
    private func endLiveActivity() {
        guard let activity = currentActivity else { return }
        // Clear currentActivity immediately to prevent race conditions with startSession
        // where the new activity might be ended by this task if captured later.
        currentActivity = nil
        
        let finalState = TwenyAttributes.ContentState(
            timeRemaining: 0,
            progress: 1.0,
            phase: "Done",
            statusMessage: "Session Completed",
            sessionElapsed: sessionElapsed,
            targetTime: nil,
            sessionStartTime: sessionStartTime,
            sessionEndTime: Date()
        )
        
        Task {
            await activity.end(ActivityContent(state: finalState, staleDate: nil), dismissalPolicy: .immediate)
        }
    }
}
