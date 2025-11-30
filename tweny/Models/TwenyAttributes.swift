//
//  TwenyAttributes.swift
//  tweny
//
//  Created by GitHub Copilot on 29/11/25.
//

import ActivityKit
import Foundation

struct TwenyAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var timeRemaining: TimeInterval
        var progress: Double
        var phase: String // "Work" or "Break"
        var statusMessage: String
        var sessionElapsed: TimeInterval
        var targetTime: Date? // For robust countdown
        var sessionStartTime: Date? // For live session progress
        var sessionEndTime: Date? // For live session progress
    }

    // Fixed non-changing properties about your activity go here!
    var sessionName: String
    var intervalDuration: TimeInterval
    var sessionGoal: TimeInterval
}
