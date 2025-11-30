//
//  PresetEditorView.swift
//  tweny
//
//  Created by GitHub Copilot on 30/11/25.
//

import SwiftUI

struct PresetEditorView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var dataManager = DataManager.shared
    
    var presetToEdit: SessionPreset?
    
    @State private var name = ""
    @State private var sessionGoalHours = 4.0
    @State private var workIntervalMinutes = 20.0
    @State private var breakIntervalSeconds = 20.0
    @State private var selectedColor = Color.blue
    @State private var selectedIcon = "⏳"
    
    let availableColors: [Color] = [.blue, .purple, .pink, .red, .orange, .yellow, .green, .mint, .teal, .cyan, .indigo, .gray]
    let availableIcons = ["⏳", "⏱️", "🗓️", "📚", "👨🏻‍💻", "⚡️", "🧠", "🧘", "☕️", "🎯", "🔥", "💡"]
    
    init(preset: SessionPreset? = nil) {
        self.presetToEdit = preset
        _name = State(initialValue: preset?.name ?? "")
        _sessionGoalHours = State(initialValue: (preset?.sessionGoal ?? 14400) / 3600)
        _workIntervalMinutes = State(initialValue: (preset?.workInterval ?? 1200) / 60)
        _breakIntervalSeconds = State(initialValue: preset?.breakInterval ?? 20)
        _selectedIcon = State(initialValue: preset?.icon ?? "⏳")
        if let hex = preset?.colorHex {
            _selectedColor = State(initialValue: Color(hex: hex))
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Preview Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(selectedIcon)
                                .font(.system(size: 32))
                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                            Spacer()
                        }
                        Spacer()
                        Text(name.isEmpty ? "Preset Name" : name)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                        Text("\(Int(sessionGoalHours))h Goal • \(Int(workIntervalMinutes))m Focus")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(selectedColor.opacity(0.3), lineWidth: 2)
                    )
                    .shadow(color: selectedColor.opacity(0.1), radius: 15, x: 0, y: 8)
                    .padding(.horizontal)
                    
                    // Form Fields
                    VStack(spacing: 28) {
                        // Name Input
                        VStack(alignment: .leading, spacing: 10) {
                            Text("NAME")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            
                            TextField("e.g. Deep Work", text: $name)
                                .font(.system(size: 18, weight: .medium))
                                .padding()
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(12)
                        }
                        
                        // Icon Picker
                        VStack(alignment: .leading, spacing: 10) {
                            Text("ICON")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(availableIcons, id: \.self) { icon in
                                        Text(icon)
                                            .font(.system(size: 24))
                                            .frame(width: 50, height: 50)
                                            .background(selectedIcon == icon ? Color(UIColor.secondarySystemBackground) : Color.clear)
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(selectedIcon == icon ? selectedColor : Color.clear, lineWidth: 2)
                                            )
                                            .onTapGesture {
                                                withAnimation(.spring()) {
                                                    selectedIcon = icon
                                                }
                                            }
                                    }
                                }
                                .padding(.horizontal, 4)
                                .padding(.vertical, 8)
                            }
                        }
                        
                        // Color Picker
                        VStack(alignment: .leading, spacing: 10) {
                            Text("COLOR")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(availableColors, id: \.self) { color in
                                        Circle()
                                            .fill(color)
                                            .frame(width: 44, height: 44)
                                            .overlay(
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 16, weight: .bold))
                                                    .foregroundColor(.white)
                                                    .opacity(selectedColor == color ? 1 : 0)
                                            )
                                            .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
                                            .onTapGesture {
                                                withAnimation(.spring()) {
                                                    selectedColor = color
                                                }
                                            }
                                    }
                                }
                                .padding(.horizontal, 4)
                                .padding(.vertical, 8)
                            }
                        }
                        
                        // Sliders
                        CustomSlider(value: $sessionGoalHours, range: 1...12, step: 0.5, title: "SESSION GOAL", unit: "hours")
                        CustomSlider(value: $workIntervalMinutes, range: 5...60, step: 5, title: "WORK INTERVAL", unit: "min")
                        CustomSlider(value: $breakIntervalSeconds, range: 10...60, step: 5, title: "BREAK DURATION", unit: "sec")
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle(presetToEdit == nil ? "New Preset" : "Edit Preset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        savePreset()
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }
    
    private func savePreset() {
        let newPreset = SessionPreset(
            id: presetToEdit?.id ?? UUID(), // Keep ID if editing
            name: name.isEmpty ? "Custom Session" : name,
            sessionGoal: sessionGoalHours * 3600,
            workInterval: workIntervalMinutes * 60,
            breakInterval: breakIntervalSeconds,
            colorHex: selectedColor.toHex() ?? "#007AFF",
            icon: selectedIcon
        )
        dataManager.savePreset(newPreset)
        dismiss()
    }
}

struct CustomSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let title: String
    let unit: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(value)) \(unit)")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)
            }
            
            Slider(value: $value, in: range, step: step)
                .accentColor(.primary)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
}
