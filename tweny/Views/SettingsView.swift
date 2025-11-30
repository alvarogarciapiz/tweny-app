//
//  SettingsView.swift
//  tweny
//
//  Created by GitHub Copilot on 29/11/25.
//

import SwiftUI
import CoreData

struct SettingsView: View {
    // MARK: - App Storage
    @AppStorage("dailyGoalHours") private var dailyGoalHours: Double = 4.0
    @AppStorage("workDuration") private var workDuration: Double = 20
    @AppStorage("breakDuration") private var breakDuration: Double = 20
    @AppStorage("isSoundEnabled") private var isSoundEnabled: Bool = true
    @AppStorage("isHapticsEnabled") private var isHapticsEnabled: Bool = true
    @AppStorage("keepScreenOn") private var keepScreenOn: Bool = true
    
    // MARK: - State
    @State private var showResetAlert = false
    
    var body: some View {
        NavigationView {
            List {
                // MARK: - Focus Goals
                Section {
                    SettingsRow(icon: "target", color: .blue, title: "Daily Goal") {
                        CustomStepper(value: $dailyGoalHours, range: 1...12, step: 1, unit: "hrs")
                    }
                } header: {
                    Text("Goals")
                } footer: {
                    Text("Set your daily focus target. This affects your progress rings and streaks.")
                }
                
                // MARK: - Default Timer
                Section {
                    SettingsRow(icon: "timer", color: .orange, title: "Work Interval") {
                        CustomStepper(value: $workDuration, range: 5...60, step: 5, unit: "min")
                    }
                    
                    SettingsRow(icon: "cup.and.saucer.fill", color: .green, title: "Break Duration") {
                        CustomStepper(value: $breakDuration, range: 10...60, step: 5, unit: "sec")
                    }
                } header: {
                    Text("Quick Session Defaults")
                } footer: {
                    Text("These settings apply when you start a 'Quick Session' without selecting a specific preset.")
                }
                
                // MARK: - Sensory & Feedback
                Section {
                    SettingsRow(icon: "speaker.wave.2.fill", color: .red, title: "Sound Effects") {
                        Toggle("", isOn: $isSoundEnabled)
                            .labelsHidden()
                    }
                    
                    SettingsRow(icon: "iphone.gen3", color: .purple, title: "Haptic Feedback") {
                        Toggle("", isOn: $isHapticsEnabled)
                            .labelsHidden()
                    }
                    
                    SettingsRow(icon: "sun.max.fill", color: .yellow, title: "Keep Screen On") {
                        Toggle("", isOn: $keepScreenOn)
                            .labelsHidden()
                    }
                } header: {
                    Text("Experience")
                }
                
                // MARK: - Data Management
                Section {
                    Button(action: { showResetAlert = true }) {
                        HStack {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.red)
                                .frame(width: 28, height: 28)
                            Text("Reset All Data")
                                .foregroundColor(.red)
                        }
                    }
                } header: {
                    Text("Data")
                }
                
                // MARK: - About
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0 (Build 1)")
                            .foregroundColor(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://twitter.com/lvrpiz")!) {
                        HStack {
                            Text("Follow us on X")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("About")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .alert("Reset Data", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    resetData()
                }
            } message: {
                Text("Are you sure? This will delete all your session history, badges, and streaks. This action cannot be undone.")
            }
            .onAppear {
                // Sync with TimerManager if needed
                TimerManager.shared.sessionGoal = dailyGoalHours * 3600
            }
            .onChange(of: dailyGoalHours) { _, newValue in
                TimerManager.shared.sessionGoal = newValue * 3600
            }
        }
    }
    
    private func resetData() {
        // Reset UserDefaults
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        
        // Reset CoreData (Simple implementation)
        let context = PersistenceController.shared.container.viewContext
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = SessionLog.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(deleteRequest)
            try context.save()
            
            // Reset in-memory state
            DataManager.shared.loadPresets() // Reload defaults
            DataManager.shared.userName = "Focus User"
            
            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        } catch {
            print("Error resetting data: \(error)")
        }
    }
}

// MARK: - Helper Views

struct SettingsRow<Content: View>: View {
    let icon: String
    let color: Color
    let title: String
    let content: Content
    
    init(icon: String, color: Color, title: String, @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.color = color
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(width: 32, height: 32)
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
            
            content
        }
        .padding(.vertical, 6)
    }
}

struct CustomStepper: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let unit: String
    
    var body: some View {
        HStack(spacing: 0) {
            // Decrement
            Button(action: {
                if value > range.lowerBound {
                    triggerHaptic()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        value -= step
                    }
                }
            }) {
                Image(systemName: "minus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(value > range.lowerBound ? .primary : Color(UIColor.tertiaryLabel))
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(value <= range.lowerBound)
            
            // Value
            HStack(spacing: 2) {
                Text("\(Int(value))")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .contentTransition(.numericText(countsDown: true))
                Text(unit)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
            .frame(width: 64)
            
            // Increment
            Button(action: {
                if value < range.upperBound {
                    triggerHaptic()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        value += step
                    }
                }
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(value < range.upperBound ? .primary : Color(UIColor.tertiaryLabel))
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(value >= range.upperBound)
        }
        .padding(4)
        .background(Color(UIColor.secondarySystemFill))
        .clipShape(Capsule())
    }
    
    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}
