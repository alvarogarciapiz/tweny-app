//
//  SessionDetailView.swift
//  tweny
//
//  Created by GitHub Copilot on 29/11/25.
//

import SwiftUI

struct SessionDetailView: View {
    let session: SessionLog
    @Environment(\.dismiss) var dismiss
    
    private var focusTime: Double {
        session.duration - (Double(session.breaksTaken) * 20.0)
    }
    
    private var breakTime: Double {
        Double(session.breaksTaken) * 20.0
    }
    
    private var focusRatio: Double {
        guard session.duration > 0 else { return 0 }
        return focusTime / session.duration * 100
    }
    
    private var averageWorkBlock: Double {
        guard session.breaksTaken > 0 else { return session.duration / 60 }
        return focusTime / Double(session.breaksTaken + 1) / 60
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                // 1. Hero: Duration + Ring
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .stroke(Color(UIColor.tertiarySystemFill), lineWidth: 16)
                            .frame(width: 180, height: 180)
                        
                        Circle()
                            .trim(from: 0, to: focusRatio / 100)
                            .stroke(Color.primary, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                            .frame(width: 180, height: 180)
                            .rotationEffect(.degrees(-90))
                        
                        VStack(spacing: 4) {
                            Text(TimeFormatter.formatDuration(timeInterval: session.duration))
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .monospacedDigit()
                            
                            Text("Total Time")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 16)
                }
                
                // 2. Quick Stats Row
                HStack(spacing: 12) {
                    QuickStatPill(
                        icon: "clock",
                        value: session.startTime?.formatted(date: .omitted, time: .shortened) ?? "--",
                        label: "Start"
                    )
                    
                    QuickStatPill(
                        icon: "clock.badge.checkmark",
                        value: session.endTime?.formatted(date: .omitted, time: .shortened) ?? "--",
                        label: "End"
                    )
                    
                    QuickStatPill(
                        icon: "eye",
                        value: "\(session.breaksTaken)",
                        label: "Breaks"
                    )
                }
                .padding(.horizontal, 24)
                
                // 3. Session Breakdown
                VStack(alignment: .leading, spacing: 16) {
                    Text("Breakdown")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    
                    VStack(spacing: 12) {
                        BreakdownRow(
                            icon: "brain.head.profile",
                            title: "Focus Time",
                            value: TimeFormatter.formatDuration(timeInterval: focusTime),
                            color: Color(hex: "#30D158")
                        )
                        
                        BreakdownRow(
                            icon: "eye.slash",
                            title: "Break Time",
                            value: String(format: "%.0fs", breakTime),
                            color: Color(hex: "#FF9F0A")
                        )
                        
                        BreakdownRow(
                            icon: "timer",
                            title: "Avg. Work Block",
                            value: String(format: "%.0f min", averageWorkBlock),
                            color: Color(hex: "#5856D6")
                        )
                        
                        BreakdownRow(
                            icon: "percent",
                            title: "Efficiency",
                            value: String(format: "%.0f%%", focusRatio),
                            color: Color(hex: "#32ADE6")
                        )
                    }
                }
                .padding(20)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: 20))
                .padding(.horizontal, 24)
                
                // 4. Session Quality
                VStack(alignment: .leading, spacing: 16) {
                    Text("Session Quality")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    
                    HStack(spacing: 12) {
                        QualityBadge(
                            condition: session.duration >= 3600,
                            icon: "star.fill",
                            text: "1h+ Focus"
                        )
                        
                        QualityBadge(
                            condition: session.breaksTaken >= 3,
                            icon: "eye.fill",
                            text: "Eye Care"
                        )
                        
                        QualityBadge(
                            condition: focusRatio >= 95,
                            icon: "bolt.fill",
                            text: "High Focus"
                        )
                    }
                }
                .padding(20)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: 20))
                .padding(.horizontal, 24)
                
                Spacer(minLength: 40)
            }
            .padding(.vertical)
        }
        .navigationTitle(session.startTime?.formatted(date: .abbreviated, time: .omitted) ?? "Session")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(UIColor.systemGroupedBackground))
    }
}

// MARK: - Helper Views

struct QuickStatPill: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
            
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 14))
    }
}

struct BreakdownRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.12))
                .clipShape(.rect(cornerRadius: 8))
            
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.primary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
        }
    }
}

struct QualityBadge: View {
    let condition: Bool
    let icon: String
    let text: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(condition ? Color(hex: "#FFD60A") : Color.secondary.opacity(0.4))
            
            Text(text)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(condition ? Color.primary : Color.secondary.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(condition ? Color(hex: "#FFD60A").opacity(0.1) : Color(UIColor.tertiarySystemFill))
        .clipShape(.rect(cornerRadius: 12))
    }
}
