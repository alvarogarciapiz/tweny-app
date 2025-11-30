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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(preset.icon)
                    .font(.system(size: 28))
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            Text(preset.name)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            Text("\(Int(preset.sessionGoal / 3600))h target")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(20)
        .frame(height: 170)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: preset.colorHex), Color(hex: preset.colorHex).opacity(0.8)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(24)
        .shadow(color: Color(hex: preset.colorHex).opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

struct DailyProgressSummary: View {
    @FetchRequest(
        sortDescriptors: [],
        predicate: NSPredicate(format: "startTime >= %@", Calendar.current.startOfDay(for: Date()) as NSDate)
    ) private var todaySessions: FetchedResults<SessionLog>
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("TODAY'S FOCUS")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .tracking(1)
                
                Text(TimeFormatter.formatDuration(timeInterval: totalDuration))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.primary)
                
                Text("\(todaySessions.count) sessions completed")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.1), lineWidth: 8)
                
                Circle()
                    .trim(from: 0, to: min(totalDuration / (4 * 3600), 1.0))
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 0) {
                    Text("\(Int(min(totalDuration / (4 * 3600), 1.0) * 100))%")
                        .font(.system(size: 14, weight: .bold))
                    Text("Goal")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 80, height: 80)
        }
        .padding(24)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    var totalDuration: TimeInterval {
        todaySessions.reduce(0) { $0 + $1.duration }
    }
}

