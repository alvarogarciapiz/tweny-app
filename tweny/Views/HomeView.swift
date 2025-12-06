//
//  HomeView.swift
//  tweny
//
//  Created by GitHub Copilot on 29/11/25.
//

import SwiftUI
import CoreData

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel
    @StateObject private var dataManager = DataManager.shared
    @State private var selectedHours: Double = 4
    @State private var showingPresetEditor = false
    @State private var presetToEdit: SessionPreset?
    
    var body: some View {
        ZStack {
            // Background - Clean, minimal
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
            
            // IDLE STATE: Bold Presets Grid
            ScrollView {
                VStack(spacing: 24) {
                    // Header & Greeting
                    VStack(alignment: .leading, spacing: 8) {
                        Text(greeting)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        
                        Text("Hi, \(dataManager.userName)")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    
                    // Daily Progress Card (More Prominent)
                    DailyProgressSummary()
                        .frame(height: 140) // Taller
                        .padding(.horizontal, 24)
                    
                    // Quick Session Button
                    if viewModel.isIdle {
                        Button(action: {
                            withAnimation {
                                viewModel.start(with: nil) // Uses default settings
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.primary)
                                
                                Text("Start Quick Session")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.primary)
                                
                                Spacer()
                                
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .clipShape(.rect(cornerRadius: 16))
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    // Presets Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(dataManager.presets) { preset in
                            Button(action: {
                                if viewModel.isIdle {
                                    withAnimation {
                                        viewModel.start(with: preset)
                                    }
                                }
                            }) {
                                PresetCard(preset: preset)
                                    .opacity(viewModel.isIdle ? 1.0 : (viewModel.timerManager.currentPresetName == preset.name ? 1.0 : 0.3))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 24)
                                            .stroke(Color.blue, lineWidth: (!viewModel.isIdle && viewModel.timerManager.currentPresetName == preset.name) ? 3 : 0)
                                    )
                            }
                            .disabled(!viewModel.isIdle)
                            .contextMenu {
                                Button {
                                    presetToEdit = preset
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                
                                Button(role: .destructive) {
                                    if let index = dataManager.presets.firstIndex(where: { $0.id == preset.id }) {
                                        dataManager.deletePreset(at: IndexSet(integer: index))
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                        
                        // Add New Preset Card (Dashed)
                        if dataManager.presets.count < 20 {
                            Button(action: {
                                presetToEdit = nil // New preset
                                showingPresetEditor = true
                            }) {
                                VStack(spacing: 12) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 30, weight: .light))
                                        .foregroundColor(.secondary)
                                    Text("New Preset")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 170)
                                .background(Color(UIColor.secondarySystemGroupedBackground).opacity(0.5))
                                .cornerRadius(24)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(Color.secondary.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [6]))
                                )
                            }
                            .disabled(!viewModel.isIdle)
                            .opacity(viewModel.isIdle ? 1.0 : 0.3)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }
            }
        }
        .sheet(isPresented: $showingPresetEditor) {
            PresetEditorView(preset: nil)
        }
        .sheet(item: $presetToEdit) { preset in
            PresetEditorView(preset: preset)
        }
    }
    
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        default: return "Good Evening"
        }
    }
}

// MARK: - Subviews

struct PresetCard: View {
    let preset: SessionPreset
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top: Icon and arrow
            HStack {
                Text(preset.icon)
                    .font(.system(size: 32))
                    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                
                Spacer()
                
                Image(systemName: "play.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(width: 28, height: 28)
                    .background(.white.opacity(0.2))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            // Bottom: Title and details
            VStack(alignment: .leading, spacing: 4) {
                Text(preset.name)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "target")
                            .font(.system(size: 10, weight: .semibold))
                        Text("\(Int(preset.sessionGoal / 3600))h")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                            .font(.system(size: 10, weight: .semibold))
                        Text("\(Int(preset.workInterval / 60))m")
                            .font(.system(size: 12, weight: .semibold))
                    }
                }
                .foregroundStyle(.white.opacity(0.75))
            }
        }
        .padding(18)
        .frame(height: 160)
        .background(
            ZStack {
                // Base gradient
                LinearGradient(
                    colors: [
                        Color(hex: preset.colorHex),
                        Color(hex: preset.colorHex).opacity(0.85)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Subtle inner glow
                LinearGradient(
                    colors: [.white.opacity(0.15), .clear],
                    startPoint: .top,
                    endPoint: .center
                )
            }
        )
        .clipShape(.rect(cornerRadius: 22))
        .shadow(color: Color(hex: preset.colorHex).opacity(0.4), radius: 12, x: 0, y: 6)
    }
}

struct DailyProgressSummary: View {
    @FetchRequest(
        sortDescriptors: [],
        predicate: NSPredicate(format: "startTime >= %@", Calendar.current.startOfDay(for: Date()) as NSDate)
    ) private var todaySessions: FetchedResults<SessionLog>
    
    @AppStorage("dailyGoalHours") private var dailyGoalHours: Double = 4.0
    
    private var goalSeconds: Double {
        dailyGoalHours * 3600
    }
    
    private var progressPercent: Double {
        min(totalDuration / goalSeconds, 1.0)
    }
    
    var body: some View {
        HStack(spacing: 20) {
            // Left: Progress ring
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.blue.opacity(0.12), lineWidth: 10)
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: progressPercent)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progressPercent)
                
                // Center content - percentage on one line
                Text("\(Int(progressPercent * 100))%")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            }
            .frame(width: 80, height: 80)
            
            // Right: Stats
            VStack(alignment: .leading, spacing: 10) {
                Text("Today")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                
                Text(TimeFormatter.formatDuration(timeInterval: totalDuration))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                
                // Session pills
                HStack(spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Color(hex: "#30D158"))
                        Text("\(todaySessions.count) sessions")
                    }
                    
                    if totalDuration > 0 {
                        Text("•")
                        Text("\(Int(dailyGoalHours))h goal")
                    }
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 4)
        )
    }
    
    var totalDuration: TimeInterval {
        todaySessions.reduce(0) { $0 + $1.duration }
    }
}
