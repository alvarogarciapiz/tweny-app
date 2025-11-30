//
//  ProfileView.swift
//  tweny
//
//  Created by GitHub Copilot on 29/11/25.
//

import SwiftUI
import CoreData
import PhotosUI

struct ProfileView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var dataManager = DataManager.shared
    @State private var isEditingName = false
    @State private var selectedBadge: Badge?
    @State private var selectedItem: PhotosPickerItem?
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \SessionLog.startTime, ascending: false)],
        animation: .default)
    private var sessions: FetchedResults<SessionLog>
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    // 1. Header Section (Apple Style)
                    VStack(spacing: 16) {
                        // Profile Image
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            ZStack {
                                if let data = dataManager.profileImageData, let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.secondary.opacity(0.1), lineWidth: 1))
                                } else {
                                    Circle()
                                        .fill(Color(UIColor.secondarySystemBackground))
                                        .frame(width: 100, height: 100)
                                        .overlay(
                                            Image(systemName: "person.fill")
                                                .font(.system(size: 40))
                                                .foregroundColor(.secondary)
                                        )
                                }
                                
                                // Edit Badge
                                Circle()
                                    .fill(Color.primary)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(Color(UIColor.systemBackground))
                                    )
                                    .offset(x: 35, y: 35)
                            }
                        }
                        .onChange(of: selectedItem) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                    dataManager.saveProfileImage(data)
                                }
                            }
                        }
                        
                        // Name & Rank
                        VStack(spacing: 4) {
                            if isEditingName {
                                TextField("Your Name", text: $dataManager.userName)
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .multilineTextAlignment(.center)
                                    .submitLabel(.done)
                                    .onSubmit {
                                        dataManager.saveUserName(dataManager.userName)
                                        isEditingName = false
                                    }
                            } else {
                                Text(dataManager.userName)
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                    .onTapGesture { isEditingName = true }
                            }
                            
                            Text(currentRank)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Color.secondary.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.top, 20)
                    
                    // 2. Stats Bento Grid (Vercel Style)
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Overview")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .padding(.horizontal)
                        
                        HStack(spacing: 12) {
                            // Left Column (Large Card)
                            BentoCard(
                                title: "Streak",
                                value: "\(currentStreak)",
                                unit: "Days",
                                icon: "flame.fill",
                                color: .orange,
                                size: .large
                            )
                            .frame(height: 240) // Increased height for better spacing
                            
                            // Right Column (Two Small Cards)
                            VStack(spacing: 12) {
                                BentoCard(
                                    title: "Focus Time",
                                    value: String(format: "%.1f", totalHours),
                                    unit: "Hours",
                                    icon: "clock.fill",
                                    color: .blue,
                                    size: .small
                                )
                                .frame(height: 114) // (240 - 12) / 2
                                
                                BentoCard(
                                    title: "Sessions",
                                    value: "\(sessions.count)",
                                    unit: "Total",
                                    icon: "checkmark.circle.fill",
                                    color: .green,
                                    size: .small
                                )
                                .frame(height: 114)
                            }
                            .frame(height: 240)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 32) // Increased spacing to prevent overlap with Awards
                    
                    // 3. Badges (Apple Fitness Style)
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Awards")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                            Spacer()
                            Text("\(unlockedBadgesCount) of \(dataManager.allBadges.count)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 24) { // Increased spacing between badges
                                ForEach(dataManager.allBadges) { badge in
                                    FitnessBadgeView(
                                        badge: badge,
                                        achieved: badge.condition(sessions.count, totalHours, currentStreak)
                                    )
                                    .onTapGesture {
                                        selectedBadge = badge
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 20)
                        }
                    }
                    
                    Spacer(minLength: 80)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                            .foregroundColor(.primary)
                    }
                }
            }
            .sheet(item: $selectedBadge) { badge in
                BadgeDetailView(badge: badge, achieved: badge.condition(sessions.count, totalHours, currentStreak))
                    .presentationDetents([.fraction(0.75)]) // Increased height to prevent cutoff
                    .presentationDragIndicator(.visible)
            }
        }
    }
    
    // MARK: - Computed Stats
    
    var totalHours: Double {
        sessions.reduce(0) { $0 + $1.duration } / 3600.0
    }
    
    var totalBreaks: Int {
        Int(sessions.reduce(0) { $0 + $1.breaksTaken })
    }
    
    var currentStreak: Int {
        let dates = sessions.compactMap { $0.startTime }.map { Calendar.current.startOfDay(for: $0) }
        let uniqueDates = Set(dates).sorted(by: >)
        guard let lastDate = uniqueDates.first else { return 0 }
        if !Calendar.current.isDateInToday(lastDate) && !Calendar.current.isDateInYesterday(lastDate) { return 0 }
        var streak = 1
        var currentDate = lastDate
        for i in 1..<uniqueDates.count {
            let prevDate = uniqueDates[i]
            if let expectedPrev = Calendar.current.date(byAdding: .day, value: -1, to: currentDate),
               Calendar.current.isDate(prevDate, inSameDayAs: expectedPrev) {
                streak += 1
                currentDate = prevDate
            } else { break }
        }
        return streak
    }
    
    var currentRank: String {
        switch totalHours {
        case 0..<10: return "Novice"
        case 10..<50: return "Focus Apprentice"
        case 50..<100: return "Deep Worker"
        default: return "Flow Master"
        }
    }
    
    var unlockedBadgesCount: Int {
        dataManager.allBadges.filter { $0.condition(sessions.count, totalHours, currentStreak) }.count
    }
}

// MARK: - Subviews

struct BentoCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    let size: CardSize
    
    enum CardSize {
        case small, large
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: size == .large ? 20 : 16))
                    .foregroundColor(color)
                    .padding(size == .large ? 8 : 6)
                    .background(color.opacity(0.1))
                    .clipShape(Circle())
                Spacer()
            }
            .padding(.bottom, size == .large ? 16 : 4)
            
            Spacer()
            
            Text(value)
                .font(.system(size: size == .large ? 32 : 24, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .minimumScaleFactor(0.8)
            
            Text(unit)
                .font(.system(size: size == .large ? 15 : 13, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(size == .large ? 16 : 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
        .clipped()
    }
}

struct FitnessBadgeView: View {
    let badge: Badge
    let achieved: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                // Hexagon Shape with Richer Gradient
                Image(systemName: "hexagon.fill")
                    .font(.system(size: 84))
                    .foregroundStyle(
                        achieved ?
                        AnyShapeStyle(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    .yellow, .orange, .red, .purple, .blue, .yellow
                                ]),
                                center: .center
                            )
                        ) :
                        AnyShapeStyle(
                            LinearGradient(colors: [Color.gray.opacity(0.3)], startPoint: .top, endPoint: .bottom)
                        )
                    )
                    .shadow(color: achieved ? .orange.opacity(0.5) : .clear, radius: 12, x: 0, y: 6)
                    .overlay(
                        // Shine effect
                        Image(systemName: "hexagon")
                            .font(.system(size: 84))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white.opacity(0.6), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .mask(Image(systemName: "hexagon.fill").font(.system(size: 84)))
                    )
                
                // Icon with Drop Shadow
                Image(systemName: badge.icon)
                    .font(.system(size: 34))
                    .foregroundColor(achieved ? .white : .gray)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 2)
            }
            
            Text(badge.name)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(achieved ? .primary : .secondary)
                .multilineTextAlignment(.center)
                .frame(width: 90)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .opacity(achieved ? 1 : 0.6)
        .scaleEffect(achieved ? 1 : 0.95)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: achieved)
    }
}

struct BadgeDetailView: View {
    let badge: Badge
    let achieved: Bool
    @Environment(\.dismiss) var dismiss
    @State private var rotation: Double = 0
    @State private var showConfetti = false
    
    var body: some View {
        ZStack {
            // Background Confetti (Simple Implementation)
            if showConfetti && achieved {
                ConfettiView()
            }
            
            VStack(spacing: 32) {
                // 3D-like Badge Presentation
                ZStack {
                    // Glow
                    Circle()
                        .fill(
                            AngularGradient(gradient: Gradient(colors: [.red, .orange, .yellow, .green, .blue, .purple, .red]), center: .center)
                        )
                        .frame(width: 160, height: 160)
                        .blur(radius: 40)
                        .opacity(achieved ? 0.5 : 0)
                        .scaleEffect(showConfetti ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: showConfetti)
                    
                    // Badge
                    ZStack {
                        Image(systemName: "hexagon.fill")
                            .font(.system(size: 180))
                            .foregroundStyle(
                                achieved ?
                                LinearGradient(colors: [.yellow, .orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                LinearGradient(colors: [Color.gray.opacity(0.2)], startPoint: .top, endPoint: .bottom)
                            )
                            .shadow(color: achieved ? .orange.opacity(0.5) : .clear, radius: 30, x: 0, y: 15)
                        
                        Image(systemName: badge.icon)
                            .font(.system(size: 80))
                            .foregroundColor(achieved ? .white : .gray)
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 2)
                    }
                    .rotation3DEffect(
                        .degrees(rotation),
                        axis: (x: 0.0, y: 1.0, z: 0.0)
                    )
                }
                .padding(.top, 60)
                .onAppear {
                    if achieved {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                            rotation = 360
                            showConfetti = true
                        }
                    }
                }
                
                VStack(spacing: 16) {
                    Text(badge.name)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                    
                    if achieved {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.green)
                            Text("Unlocked")
                                .fontWeight(.semibold)
                        }
                        .font(.system(size: 15))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.15))
                        .clipShape(Capsule())
                    } else {
                        HStack(spacing: 6) {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.secondary)
                            Text("Locked")
                                .fontWeight(.semibold)
                        }
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }
                
                Text(badge.description)
                    .font(.system(size: 18, weight: .regular, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 40)
                    .lineSpacing(6)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Text("Close")
                        .font(.headline)
                        .foregroundColor(Color(UIColor.systemBackground))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.primary)
                        .cornerRadius(20)
                        .shadow(color: Color.primary.opacity(0.2), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
        .background(Color(UIColor.systemBackground))
    }
}

// Simple Confetti Effect
struct ConfettiView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            ForEach(0..<50) { _ in
                Circle()
                    .fill(Color(
                        red: .random(in: 0...1),
                        green: .random(in: 0...1),
                        blue: .random(in: 0...1)
                    ))
                    .frame(width: 8, height: 8)
                    .offset(x: .random(in: -200...200), y: .random(in: -300...300))
                    .opacity(animate ? 0 : 1)
                    .scaleEffect(animate ? 0 : 1)
                    .animation(
                        .easeOut(duration: .random(in: 1...2))
                        .delay(.random(in: 0...0.5)),
                        value: animate
                    )
            }
        }
        .onAppear {
            animate = true
        }
    }
}
