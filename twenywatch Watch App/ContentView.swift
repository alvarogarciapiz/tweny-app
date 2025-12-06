//
//  ContentView.swift
//  twenywatch Watch App
//
//  Main view showing preset cards and timer when active
//

import SwiftUI

struct ContentView: View {
    @StateObject private var sessionManager = WatchSessionManager.shared
    
    var body: some View {
        Group {
            if sessionManager.isSessionActive {
                WatchTimerView(sessionManager: sessionManager)
            } else {
                PresetListView(sessionManager: sessionManager)
            }
        }
        .onAppear {
            sessionManager.requestState()
        }
    }
}

struct PresetListView: View {
    @ObservedObject var sessionManager: WatchSessionManager
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if sessionManager.presets.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "iphone.and.arrow.forward")
                            .font(.system(size: 32))
                            .foregroundStyle(.secondary)
                        
                        Text("Open Tweny on iPhone")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        
                        if !sessionManager.isConnected {
                            Text("Not connected")
                                .font(.system(size: 12))
                                .foregroundStyle(.red)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(sessionManager.presets) { preset in
                            WatchPresetCard(preset: preset) {
                                sessionManager.startSession(with: preset)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            .navigationTitle("Tweny")
        }
    }
}

#Preview {
    ContentView()
}
