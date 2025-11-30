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
            ScrollView {
                LazyVStack(spacing: 20) {
                    if sessions.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            Text("No sessions yet")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 60)
                    } else {
                        ForEach(groupedSessions.keys.sorted(by: >), id: \.self) { date in
                            VStack(alignment: .leading, spacing: 12) {
                                Text(date, format: .dateTime.weekday().day().month())
                                    .font(.headline)
                                    .foregroundColor(.secondary)
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

struct SessionRowCard: View {
    let session: SessionLog
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(session.startTime ?? Date(), style: .time)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(TimeFormatter.formatDuration(timeInterval: session.duration))
                    .font(.title3)
                    .bold()
                    .monospacedDigit()
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                if session.breaksTaken > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "cup.and.saucer.fill")
                            .font(.caption)
                        Text("\(session.breaksTaken)")
                            .font(.caption)
                            .bold()
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .foregroundColor(.orange)
                    .clipShape(Capsule())
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal)
        .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
    }
}
