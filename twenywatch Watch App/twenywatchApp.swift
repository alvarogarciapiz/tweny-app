//
//  twenywatchApp.swift
//  twenywatch Watch App
//
//  Entry point for Apple Watch app
//

import SwiftUI

@main
struct twenywatch_Watch_AppApp: App {
    // Initialize WatchSessionManager on app launch
    @StateObject private var sessionManager = WatchSessionManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sessionManager)
        }
    }
}
