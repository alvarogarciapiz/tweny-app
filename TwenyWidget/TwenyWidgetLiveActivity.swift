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
            // Lock screen/banner UI
            LiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        Image(systemName: context.state.phase == "Focus" ? "brain.head.profile" : "cup.and.saucer.fill")
                            .foregroundColor(context.state.phase == "Focus" ? .indigo : .orange)
                        Text(context.state.phase)
                            .font(.system(.headline, design: .rounded))
                    }
                    .padding(.leading)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    if let targetTime = context.state.targetTime {
                        Text(timerInterval: Date()...targetTime, countsDown: true)
                            .monospacedDigit()
                            .font(.system(.title2, design: .rounded, weight: .semibold))
                            .padding(.trailing)
                    } else {
                        Text(timeString(from: context.state.timeRemaining))
                            .monospacedDigit()
                            .font(.system(.title2, design: .rounded, weight: .semibold))
                            .padding(.trailing)
                            .foregroundColor(.secondary)
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    // Progress Bar
                    VStack(spacing: 8) {
                        ProgressView(value: context.state.progress, total: 1.0)
                            .tint(context.state.phase == "Focus" ? .indigo : .orange)
                            .scaleEffect(x: 1, y: 2, anchor: .center)
                            .clipShape(Capsule())
                        
                        HStack {
                            Text(context.state.statusMessage)
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int((context.state.sessionElapsed / context.attributes.sessionGoal) * 100))% Session")
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                
            } compactLeading: {
                Image(systemName: context.state.phase == "Focus" ? "brain.head.profile" : "cup.and.saucer.fill")
                    .foregroundColor(context.state.phase == "Focus" ? .indigo : .orange)
            } compactTrailing: {
                if let targetTime = context.state.targetTime {
                    Text(timerInterval: Date()...targetTime, countsDown: true)
                        .monospacedDigit()
                        .font(.system(.body, design: .rounded))
                        .frame(width: 44)
                } else {
                    Text(timeString(from: context.state.timeRemaining))
                        .monospacedDigit()
                        .font(.system(.body, design: .rounded))
                        .frame(width: 44)
                        .foregroundColor(.secondary)
                }
            } minimal: {
                Image(systemName: context.state.phase == "Focus" ? "brain.head.profile" : "cup.and.saucer.fill")
                    .foregroundColor(context.state.phase == "Focus" ? .indigo : .orange)
            }
            .widgetURL(URL(string: "tweny://open"))
            .keylineTint(Color.cyan)
        }
    }
}

struct LiveActivityView: View {
    let context: ActivityViewContext<TwenyAttributes>
    
    var sessionProgress: Double {
        guard context.attributes.sessionGoal > 0 else { return 0 }
        return context.state.sessionElapsed / context.attributes.sessionGoal
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Top Row: Header
            HStack {
                Label(context.state.phase, systemImage: context.state.phase == "Focus" ? "brain.head.profile" : "cup.and.saucer.fill")
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundColor(context.state.phase == "Focus" ? .indigo : .orange)
                
                Spacer()
                
                Text(context.state.statusMessage)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            // Middle: Big Timer & Controls
            HStack {
                if let targetTime = context.state.targetTime {
                    Text(timerInterval: Date()...targetTime, countsDown: true)
                        .font(.system(size: 52, weight: .medium, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text(timeString(from: context.state.timeRemaining))
                        .font(.system(size: 52, weight: .medium, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Controls
                HStack(spacing: 20) {
                    Link(destination: URL(string: "tweny://toggle")!) {
                        Image(systemName: context.state.phase == "Paused" ? "play.circle.fill" : "pause.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.primary)
                    }
                    
                    Link(destination: URL(string: "tweny://stop")!) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Bottom: Progress Bar
            VStack(spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.secondary.opacity(0.2))
                        
                        Capsule()
                            .fill(context.state.phase == "Focus" ? Color.indigo : Color.orange)
                            .frame(width: max(0, geo.size.width * context.state.progress))
                    }
                }
                .frame(height: 12)
            }
        }
        .padding(20)
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
