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
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                // 1. Hero Section (Ring + Time)
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .stroke(Color.secondary.opacity(0.12), lineWidth: 20)
                            .frame(width: 220, height: 220)
                        Circle()
                            .trim(from: 0, to: 1)
                            .stroke(
                                Color.primary.opacity(0.12),
                                style: StrokeStyle(lineWidth: 20, lineCap: .round)
                            )
                            .frame(width: 220, height: 220)
                            .rotationEffect(.degrees(-90))
                            .shadow(color: Color.primary.opacity(0.08), radius: 8, x: 0, y: 0)
                            .animation(.easeOut(duration: 0.8), value: session.duration)
                        VStack(spacing: 4) {
                            Text("Total Focus")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                            Text(TimeFormatter.formatDuration(timeInterval: session.duration))
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundColor(.primary)
                                .transition(.opacity.combined(with: .scale))
                        }
                    }
                    .padding(.top, 20)
                }
                
                // 2. Stats Grid (Bento Style)
                VStack(alignment: .leading, spacing: 16) {
                    Text("Session Stats")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .padding(.horizontal)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        DetailStatCard(
                            title: "Start Time",
                            value: session.startTime?.formatted(date: .omitted, time: .shortened) ?? "--:--",
                            icon: "play.fill",
                            color: .green
                        )
                        DetailStatCard(
                            title: "End Time",
                            value: session.endTime?.formatted(date: .omitted, time: .shortened) ?? "--:--",
                            icon: "stop.fill",
                            color: .red
                        )
                        DetailStatCard(
                            title: "Breaks",
                            value: "\(session.breaksTaken)",
                            icon: "cup.and.saucer.fill",
                            color: .orange
                        )
                        DetailStatCard(
                            title: "Focus Ratio",
                            value: calculateFocusRatio() + "%",
                            icon: "chart.pie.fill",
                            color: .primary
                        )
                    }
                    .padding(.horizontal)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: session.breaksTaken)
                }
                
                // 3. Chart Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Time Distribution")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .padding(.horizontal)
                    VStack(alignment: .leading, spacing: 24) {
                        Chart {
                            BarMark(
                                x: .value("Type", "Focus"),
                                y: .value("Duration", session.duration - (Double(session.breaksTaken) * 20.0))
                            )
                            .foregroundStyle(Color.primary.opacity(0.15))
                            .cornerRadius(8)
                            .annotation(position: .top) {
                                Text("Focus")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            BarMark(
                                x: .value("Type", "Breaks"),
                                y: .value("Duration", Double(session.breaksTaken) * 20.0)
                            )
                            .foregroundStyle(Color.secondary.opacity(0.15))
                            .cornerRadius(8)
                            .annotation(position: .top) {
                                Text("Breaks")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .chartYAxis(.hidden)
                        .frame(height: 200)
                    }
                    .padding(24)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(24)
                    .padding(.horizontal)
                    .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
                }
                
                Spacer(minLength: 40)
            }
            .padding(.vertical)
        }
        .navigationTitle(session.startTime?.formatted(date: .abbreviated, time: .omitted) ?? "Session")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    private func calculateFocusRatio() -> String {
        let totalTime = session.duration
        let breakTime = Double(session.breaksTaken) * 20.0 // Assuming 20s breaks
        if totalTime == 0 { return "0" }
        let ratio = ((totalTime - breakTime) / totalTime) * 100
        return String(format: "%.0f", ratio)
    }
}

struct DetailStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(color)
                    .padding(8)
                    .background(color.opacity(0.1))
                    .clipShape(Circle())
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
}

