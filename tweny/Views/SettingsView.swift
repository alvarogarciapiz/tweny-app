//
//  SettingsView.swift
//  tweny
//
//  Created by GitHub Copilot on 29/11/25.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("workDuration") private var workDuration: Double = 20
    @AppStorage("breakDuration") private var breakDuration: Double = 20
    @AppStorage("isSoundEnabled") private var isSoundEnabled: Bool = true
    @AppStorage("isHapticsEnabled") private var isHapticsEnabled: Bool = true
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Durations")) {
                    VStack(alignment: .leading) {
                        Text("Work Interval: \(Int(workDuration)) min")
                        Slider(value: $workDuration, in: 5...60, step: 5)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Break Duration: \(Int(breakDuration)) sec")
                        Slider(value: $breakDuration, in: 10...60, step: 5)
                    }
                }
                
                Section(header: Text("Feedback")) {
                    Toggle("Sound", isOn: $isSoundEnabled)
                    Toggle("Haptics", isOn: $isHapticsEnabled)
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
