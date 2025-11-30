//
//  TimerState.swift
//  tweny
//
//  Created by GitHub Copilot on 29/11/25.
//

import Foundation

enum TimerPhase: String, CaseIterable {
    case idle
    case work
    case breakTime
    case paused
}

struct TimerConfiguration {
    var workDuration: TimeInterval = 20 * 60 // 20 minutes
    var breakDuration: TimeInterval = 20 // 20 seconds
    var isSoundEnabled: Bool = true
    var isHapticsEnabled: Bool = true
}
