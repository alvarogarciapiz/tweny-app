//
//  HomeViewModel.swift
//  tweny
//
//  Created by GitHub Copilot on 29/11/25.
//

import SwiftUI
import Combine

class HomeViewModel: ObservableObject {
    @ObservedObject var timerManager: TimerManager
    private var cancellables = Set<AnyCancellable>()
    
    init(timerManager: TimerManager) {
        self.timerManager = timerManager
        
        // Forward updates from TimerManager to HomeViewModel
        timerManager.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    var timerText: String {
        TimeFormatter.format(timeInterval: timerManager.timeRemaining)
    }
    
    var progress: Double {
        timerManager.progress
    }
    
    var isWorking: Bool {
        timerManager.phase == .work
    }
    
    var isBreak: Bool {
        timerManager.phase == .breakTime
    }
    
    var isIdle: Bool {
        timerManager.phase == .idle
    }
    
    var statusText: String {
        switch timerManager.phase {
        case .idle: return "Start Session"
        case .work: return "Focus"
        case .breakTime: return "Rest"
        case .paused: return "Paused"
        }
    }
    
    var sessionGoalHours: Double {
        get { timerManager.sessionGoal / 3600 }
        set { timerManager.sessionGoal = newValue * 3600 }
    }
    
    var sessionProgress: Double {
        guard timerManager.sessionGoal > 0 else { return 0 }
        return timerManager.sessionElapsed / timerManager.sessionGoal
    }
    
    func start(with preset: SessionPreset? = nil) {
        timerManager.startSession(with: preset)
    }
    
    func stop() {
        timerManager.stopSession()
    }
    
    func pause() {
        timerManager.pauseSession()
    }
}
