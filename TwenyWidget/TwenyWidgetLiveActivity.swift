//
//  TwenyWidgetLiveActivity.swift
//  TwenyWidget
//
//  Created by Álvaro García Pizarro on 29/11/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct TwenyWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TwenyAttributes.self) { context in
            // Lock screen/banner UI - uses activityFamily to differentiate
            ActivityContentView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI - Apple Flight style
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Image(systemName: "eye")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.primary)
                        
                        Text(context.attributes.sessionName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.phase.uppercased())
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(context.state.phase == "Focus" ? .white : .black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(context.state.phase == "Focus" ? Color.primary : Color.green)
                        .clipShape(Capsule())
                }
                
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 6) {
                        // Progress bar with markers
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                // Background track
                                Capsule()
                                    .fill(Color.primary.opacity(0.2))
                                    .frame(height: 4)
                                
                                // Progress fill
                                Capsule()
                                    .fill(Color.primary)
                                    .frame(width: max(4, geo.size.width * context.state.progress), height: 4)
                                
                                // Start marker
                                Circle()
                                    .fill(Color.primary)
                                    .frame(width: 8, height: 8)
                                    .offset(x: -2)
                                
                                // End marker
                                Circle()
                                    .stroke(Color.primary.opacity(0.3), lineWidth: 2)
                                    .frame(width: 8, height: 8)
                                    .offset(x: geo.size.width - 6)
                            }
                            .frame(height: 8)
                        }
                        .frame(height: 8)
                        
                        // Time labels
                        HStack {
                            Text("0:00")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            // Center: current time big
                            if let targetTime = context.state.targetTime {
                                Text(timerInterval: Date()...targetTime, countsDown: true)
                                    .monospacedDigit()
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundStyle(.primary)
                            }
                            
                            Spacer()
                            
                            Text(formatTime(context.attributes.intervalDuration))
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 4)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.state.statusMessage)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 2)
                }
                
            } compactLeading: {
                ZStack {
                    Circle()
                        .trim(from: 0, to: context.state.progress)
                        .stroke(phaseColor(context.state.phase), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 22, height: 22)
                    
                    Image(systemName: context.state.phase == "Focus" ? "eye" : "eye.slash")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(phaseColor(context.state.phase))
                }
            } compactTrailing: {
                if let targetTime = context.state.targetTime {
                    Text(timerInterval: Date()...targetTime, countsDown: true)
                        .monospacedDigit()
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .frame(minWidth: 44)
                } else {
                    Text(timeString(from: context.state.timeRemaining))
                        .monospacedDigit()
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .frame(minWidth: 44)
                        .foregroundStyle(.secondary)
                }
            } minimal: {
                ZStack {
                    Circle()
                        .trim(from: 0, to: context.state.progress)
                        .stroke(phaseColor(context.state.phase), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    
                    Image(systemName: context.state.phase == "Focus" ? "eye" : "eye.slash")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(phaseColor(context.state.phase))
                }
            }
            .widgetURL(URL(string: "tweny://open"))
        }
        .supplementalActivityFamilies([.small]) // Smart Stack on Apple Watch
    }
    
    func phaseColor(_ phase: String) -> Color {
        phase == "Focus" ? .primary : .green
    }
    
    func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Activity Content View (handles activityFamily)

struct ActivityContentView: View {
    @Environment(\.activityFamily) var activityFamily
    let context: ActivityViewContext<TwenyAttributes>
    
    var body: some View {
        switch activityFamily {
        case .small:
            // Apple Watch Smart Stack
            SmallActivityView(context: context)
        case .medium:
            // iOS Lock Screen
            LiveActivityView(context: context)
        @unknown default:
            LiveActivityView(context: context)
        }
    }
}

// MARK: - Small Activity View (Apple Watch Smart Stack)

struct SmallActivityView: View {
    @Environment(\.isLuminanceReduced) var isLuminanceReduced
    let context: ActivityViewContext<TwenyAttributes>
    
    var presetColor: Color {
        Color(hex: context.attributes.presetColorHex)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Progress ring with icon
            ZStack {
                Circle()
                    .stroke(presetColor.opacity(isLuminanceReduced ? 0.2 : 0.3), lineWidth: 4)
                
                Circle()
                    .trim(from: 0, to: context.state.progress)
                    .stroke(
                        isLuminanceReduced ? presetColor.opacity(0.6) : presetColor,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                
                Text(context.attributes.sessionName.prefix(1))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(isLuminanceReduced ? .secondary : .primary)
            }
            .frame(width: 44, height: 44)
            
            // Timer and status
            VStack(alignment: .leading, spacing: 2) {
                if let targetTime = context.state.targetTime {
                    Text(timerInterval: Date()...targetTime, countsDown: true)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(isLuminanceReduced ? .secondary : .primary)
                }
                
                Text(context.state.phase == "Focus" ? "Focus" : "Break")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

// MARK: - iOS Lock Screen Live Activity View

struct LiveActivityView: View {
    let context: ActivityViewContext<TwenyAttributes>
    
    var presetColor: Color {
        Color(hex: context.attributes.presetColorHex)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Top row: Phase pill + Timer on left, Controls on right
            HStack(alignment: .center) {
                // Left: Phase pill and Timer
                VStack(alignment: .leading, spacing: 4) {
                    // Phase pill
                    HStack(spacing: 4) {
                        Image(systemName: context.state.phase == "Focus" ? "eye" : "eye.slash")
                            .font(.system(size: 10, weight: .semibold))
                        
                        Text(context.state.phase.uppercased())
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(0.3)
                    }
                    .foregroundStyle(presetColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(presetColor.opacity(0.12))
                    .clipShape(Capsule())
                    
                    // Timer
                    if let targetTime = context.state.targetTime {
                        Text(timerInterval: Date()...targetTime, countsDown: true)
                            .font(.system(size: 42, weight: .medium, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.primary)
                    } else {
                        Text(timeString(from: context.state.timeRemaining))
                            .font(.system(size: 42, weight: .medium, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                // Right: Controls (top right corner)
                HStack(spacing: 10) {
                    Link(destination: URL(string: "tweny://toggle")!) {
                        Image(systemName: context.state.phase == "Paused" ? "play.fill" : "pause.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 36, height: 36)
                            .background(Color.primary.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    Link(destination: URL(string: "tweny://stop")!) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.tertiary)
                            .frame(width: 36, height: 36)
                            .background(Color.primary.opacity(0.06))
                            .clipShape(Circle())
                    }
                }
            }
            
            // Bottom: Full-width progress bar with preset color
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background track
                    Capsule()
                        .fill(presetColor.opacity(0.2))
                    
                    // Progress fill
                    Capsule()
                        .fill(presetColor)
                        .frame(width: max(6, geo.size.width * context.state.progress))
                }
            }
            .frame(height: 8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .activityBackgroundTint(Color(UIColor.systemBackground))
    }
    
    func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// Helper for Widget
func timeString(from timeInterval: TimeInterval) -> String {
    let minutes = Int(timeInterval) / 60
    let seconds = Int(timeInterval) % 60
    return String(format: "%02d:%02d", minutes, seconds)
}

// Color+Hex extension for Widget
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 122, 255) // Default blue
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
