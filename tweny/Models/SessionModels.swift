//
//  SessionPreset.swift
//  tweny
//
//  Created by GitHub Copilot on 29/11/25.
//

import Foundation

struct SessionPreset: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var sessionGoal: TimeInterval // Total duration (e.g., 4 hours)
    var workInterval: TimeInterval // Focus duration (e.g., 20 mins)
    var breakInterval: TimeInterval // Break duration (e.g., 20 secs)
    var colorHex: String // For UI customization
    var icon: String = "⏳" // Emoji icon
    
    static let defaults: [SessionPreset] = [
        SessionPreset(name: "Standard 20-20-20", sessionGoal: 4 * 3600, workInterval: 20 * 60, breakInterval: 20, colorHex: "#007AFF", icon: "👁️"),
        SessionPreset(name: "Deep Work", sessionGoal: 2 * 3600, workInterval: 50 * 60, breakInterval: 10 * 60, colorHex: "#5856D6", icon: "🧠"),
        SessionPreset(name: "Quick Focus", sessionGoal: 1 * 3600, workInterval: 25 * 60, breakInterval: 5 * 60, colorHex: "#FF9500", icon: "⚡️")
    ]
}

