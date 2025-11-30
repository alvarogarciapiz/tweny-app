//
//  SessionDetailView.swift
//  tweny
//
//  Created by GitHub Copilot on 29/11/25.
//

import SwiftUI
import Charts

struct SessionDetailView: View {
    let session: SessionLog
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Big Duration Header
                VStack(spacing: 8) {
                    Text("Total Focus Time")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(TimeFormatter.formatDuration(timeInterval: session.duration))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .monospacedDigit()
                }
                .padding(.top, 20)
                
                // Stats Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    StatCard(title: "Start Time", value: session.startTime?.formatted(date: .omitted, time: .shortened) ?? "--:--", unit: "", icon: "play.circle.fill", color: .green)
                    StatCard(title: "End Time", value: session.endTime?.formatted(date: .omitted, time: .shortened) ?? "--:--", unit: "", icon: "stop.circle.fill", color: .red)
                    StatCard(title: "Breaks Taken", value: "\(session.breaksTaken)", unit: "breaks", icon: "cup.and.saucer.fill", color: .orange)
                    StatCard(title: "Focus Ratio", value: calculateFocusRatio(), unit: "%", icon: "chart.pie.fill", color: .blue)
                }
                .padding(.horizontal)
                
                // Chart Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Time Distribution")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Chart {
                        BarMark(
                            x: .value("Type", "Focus"),
                            y: .value("Duration", session.duration - (Double(session.breaksTaken) * 20.0))
                        )
                        .foregroundStyle(Color.blue.gradient)
                        .annotation(position: .top) {
                            Text("Focus")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        BarMark(
                            x: .value("Type", "Breaks"),
                            y: .value("Duration", Double(session.breaksTaken) * 20.0)
                        )
                        .foregroundStyle(Color.orange.gradient)
                        .annotation(position: .top) {
                            Text("Breaks")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(height: 220)
                    .padding(24)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(24)
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding(.vertical)
        }
        .navigationTitle(session.startTime?.formatted(date: .abbreviated, time: .omitted) ?? "Session")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(UIColor.systemBackground))
    }
    
    private func calculateFocusRatio() -> String {
        let totalTime = session.duration
        let breakTime = Double(session.breaksTaken) * 20.0 // Assuming 20s breaks
        if totalTime == 0 { return "0" }
        let ratio = ((totalTime - breakTime) / totalTime) * 100
        return String(format: "%.0f", ratio)
    }
}

