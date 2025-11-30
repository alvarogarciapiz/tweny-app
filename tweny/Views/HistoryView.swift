//
//  HistoryView.swift
//  tweny
//
//  Created by GitHub Copilot on 29/11/25.
//

import SwiftUI
import CoreData

struct HistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \SessionLog.startTime, ascending: false)],
        animation: .default)
    private var sessions: FetchedResults<SessionLog>
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 24) {
                    // Summary Header
                    if !sessions.isEmpty {
                        HistorySummaryView(sessions: sessions)
                            .padding(.horizontal)
                            .padding(.top, 10)
                    }
                    
                    if sessions.isEmpty {
                        EmptyHistoryView()
                    } else {
                        ForEach(groupedSessions.keys.sorted(by: >), id: \.self) { date in
                            VStack(alignment: .leading, spacing: 16) {
                                Text(date, format: .dateTime.weekday(.wide).day().month(.wide))
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                    .padding(.horizontal)
                                
                                ForEach(groupedSessions[date] ?? []) { session in
                                    NavigationLink(destination: SessionDetailView(session: session)) {
                                        SessionRowCard(session: session)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("History")
            .background(Color(UIColor.systemGroupedBackground))
        }
    }
    
    var groupedSessions: [Date: [SessionLog]] {
        Dictionary(grouping: sessions) { session in
            Calendar.current.startOfDay(for: session.startTime ?? Date())
        }
    }
}

struct HistorySummaryView: View {
    let sessions: FetchedResults<SessionLog>
    
    var totalHours: Double {
        sessions.reduce(0) { $0 + $1.duration } / 3600.0
    }
    
    var totalSessions: Int {
        sessions.count
    }
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.blue)
                    Text("Total Time")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Text(String(format: "%.1f h", totalHours))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Sessions")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Text("\(totalSessions)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
        }
    }
}

struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 64))
                .foregroundColor(.secondary.opacity(0.5))
                .padding(.top, 60)
            
            VStack(spacing: 8) {
                Text("No sessions yet")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Start a focus session to see your history here.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }
}

struct SessionRowCard: View {
    let session: SessionLog
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon / Time
            VStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
                    .background(Color(UIColor.systemBackground))
                    .clipShape(Circle())
                    .shadow(color: Color.primary.opacity(0.04), radius: 2, x: 0, y: 1)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(TimeFormatter.formatDuration(timeInterval: session.duration))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .transition(.opacity.combined(with: .scale))
                Text("\(session.startTime?.formatted(date: .omitted, time: .shortened) ?? "") - \(session.endTime?.formatted(date: .omitted, time: .shortened) ?? "")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if session.breaksTaken > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 10))
                    Text("\(session.breaksTaken)")
                        .font(.system(size: 12, weight: .bold))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(UIColor.systemGray5))
                .foregroundColor(.primary)
                .clipShape(Capsule())
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: session.breaksTaken)
    }
}
