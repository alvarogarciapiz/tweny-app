//
//  TwenyShortcuts.swift
//  tweny
//
//  Created by GitHub Copilot on 29/11/25.
//

import AppIntents
import SwiftUI

@available(iOS 16.0, *)
struct TwenyShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartSessionIntent(),
            phrases: [
                "Start a session in \(.applicationName)",
                "Start focus in \(.applicationName)",
                "Start \(.applicationName)"
            ],
            shortTitle: "Start Session",
            systemImageName: "play.circle.fill"
        )
        
        AppShortcut(
            intent: StopSessionIntent(),
            phrases: [
                "Stop session in \(.applicationName)",
                "End focus in \(.applicationName)",
                "Stop \(.applicationName)"
            ],
            shortTitle: "Stop Session",
            systemImageName: "stop.circle.fill"
        )
    }
}

@available(iOS 16.0, *)
struct StartSessionIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Session"
    static var description = IntentDescription("Starts a new 20-20-20 focus session.")
    
    func perform() async throws -> some IntentResult {
        // Dispatch to main thread as TimerManager updates UI
        await MainActor.run {
            TimerManager.shared.startSession()
        }
        return .result(dialog: "Session started. Focus now!")
    }
}

@available(iOS 16.0, *)
struct StopSessionIntent: AppIntent {
    static var title: LocalizedStringResource = "Stop Session"
    static var description = IntentDescription("Stops the current focus session.")
    
    func perform() async throws -> some IntentResult {
        await MainActor.run {
            TimerManager.shared.stopSession()
        }
        return .result(dialog: "Session stopped. Great work!")
    }
}
