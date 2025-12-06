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
    @State private var headerAppeared = false
    @State private var selectedArticle: HealthArticle?
    @FocusState private var isNameFieldFocused: Bool
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \SessionLog.startTime, ascending: false)],
        animation: .default)
    private var sessions: FetchedResults<SessionLog>
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    // MARK: - Header Section
                    ProfileHeaderSection(
                        dataManager: dataManager,
                        isEditingName: $isEditingName,
                        isNameFieldFocused: $isNameFieldFocused,
                        selectedItem: $selectedItem,
                        currentRank: currentRank,
                        memberSinceDate: memberSinceDate,
                        headerAppeared: headerAppeared,
                        presetColors: presetUsageColors
                    )
                    .padding(.top, 16)
                    
                    // MARK: - Stats Bento Grid
                    StatsBentoSection(
                        currentStreak: currentStreak,
                        bestStreak: bestStreak,
                        totalHours: totalHours,
                        sessionsCount: sessions.count
                    )
                    
                    // MARK: - Weekly Activity
                    MonthlyActivitySection(sessions: Array(sessions))
                    
                    // MARK: - Awards Section
                    AwardsSection(
                        badges: dataManager.allBadges,
                        sessionsCount: sessions.count,
                        totalHours: totalHours,
                        currentStreak: currentStreak,
                        selectedBadge: $selectedBadge
                    )
                    
                    // MARK: - Health Insights
                    HealthInsightsSection(selectedArticle: $selectedArticle)
                    
                    Spacer(minLength: 100)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(.primary)
                    }
                }
            }
            .sheet(item: $selectedBadge) { badge in
                BadgeDetailView(badge: badge, achieved: badge.condition(sessions.count, totalHours, currentStreak))
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(28)
            }
            .sheet(item: $selectedArticle) { article in
                ArticleReaderView(article: article)
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                    headerAppeared = true
                }
            }
            .onChange(of: isEditingName) { _, newValue in
                if newValue {
                    isNameFieldFocused = true
                }
            }
        }
    }
    
    // MARK: - Computed Stats
    
    var totalHours: Double {
        sessions.reduce(0) { $0 + $1.duration } / 3600.0
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
    
    var bestStreak: Int {
        let dates = sessions.compactMap { $0.startTime }.map { Calendar.current.startOfDay(for: $0) }
        let uniqueDates = Set(dates).sorted()
        guard !uniqueDates.isEmpty else { return 0 }
        
        var maxStreak = 1
        var currentStreakCount = 1
        
        for i in 1..<uniqueDates.count {
            if let expectedNext = Calendar.current.date(byAdding: .day, value: 1, to: uniqueDates[i-1]),
               Calendar.current.isDate(uniqueDates[i], inSameDayAs: expectedNext) {
                currentStreakCount += 1
                maxStreak = max(maxStreak, currentStreakCount)
            } else {
                currentStreakCount = 1
            }
        }
        return maxStreak
    }
    
    var currentRank: String {
        switch totalHours {
        case 0..<10: return "Novice"
        case 10..<50: return "Focus Apprentice"
        case 50..<100: return "Deep Worker"
        default: return "Flow Master"
        }
    }
    
    var memberSinceDate: Date? {
        sessions.last?.startTime
    }
    
    // Get preset colors for the profile ring from DataManager presets
    var presetUsageColors: [Color] {
        let presetColors = dataManager.presets.map { Color(hex: $0.colorHex) }
        
        // Use preset colors if available, otherwise fallback
        if presetColors.count >= 2 {
            return presetColors
        } else if presetColors.count == 1 {
            return [presetColors[0], presetColors[0].opacity(0.6)]
        } else {
            return [.blue, .purple, .pink]
        }
    }
}

// MARK: - Profile Header Section

struct ProfileHeaderSection: View {
    @ObservedObject var dataManager: DataManager
    @Binding var isEditingName: Bool
    var isNameFieldFocused: FocusState<Bool>.Binding
    @Binding var selectedItem: PhotosPickerItem?
    let currentRank: String
    let memberSinceDate: Date?
    let headerAppeared: Bool
    let presetColors: [Color]
    
    @State private var ringRotation: Double = 0
    
    var body: some View {
        VStack(spacing: 16) {
            // Profile Image with dynamic preset-color gradient ring
            ZStack {
                // Animated gradient ring based on preset colors
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: presetColors + presetColors.prefix(1), // Loop colors
                            center: .center
                        ),
                        lineWidth: 4
                    )
                    .frame(width: 124, height: 124)
                    .rotationEffect(.degrees(ringRotation))
                    .opacity(headerAppeared ? 1 : 0)
                    .onAppear {
                        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                            ringRotation = 360
                        }
                    }
                
                if let data = dataManager.profileImageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 112, height: 112)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color(UIColor.tertiarySystemBackground))
                        .frame(width: 112, height: 112)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 44, weight: .medium))
                                .foregroundStyle(.secondary)
                        )
                }
                
                // Camera badge
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 34, height: 34)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.primary)
                        )
                }
                .offset(x: 42, y: 42)
            }
            .frame(width: 124, height: 124)
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        dataManager.saveProfileImage(data)
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                    }
                }
            }
            .scaleEffect(headerAppeared ? 1 : 0.8)
            .opacity(headerAppeared ? 1 : 0)
            
            // Name & Edit
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    if isEditingName {
                        TextField("Your Name", text: $dataManager.userName)
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .submitLabel(.done)
                            .focused(isNameFieldFocused)
                            .onSubmit {
                                dataManager.saveUserName(dataManager.userName)
                                isEditingName = false
                            }
                            .frame(maxWidth: 200)
                    } else {
                        Text(dataManager.userName)
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                        
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isEditingName = true
                            }
                        } label: {
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                // Rank pill
                Text(currentRank)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 5)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .scaleEffect(headerAppeared ? 1 : 0.9)
                
                // Member since
                if let date = memberSinceDate {
                    Text("Member since \(date.formatted(.dateTime.month(.wide).year()))")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.tertiary)
                        .padding(.top, 2)
                }
            }
            .offset(y: headerAppeared ? 0 : 10)
            .opacity(headerAppeared ? 1 : 0)
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Stats Bento Section

struct StatsBentoSection: View {
    let currentStreak: Int
    let bestStreak: Int
    let totalHours: Double
    let sessionsCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Overview")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .padding(.horizontal, 24)
            
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    // Streak - Large Card (same height as right column)
                    ProfileStatCard(
                        title: "Current Streak",
                        value: "\(currentStreak)",
                        unit: "days",
                        icon: "bolt.fill",
                        iconColor: Color(hex: "#FF6B35"),
                        trend: currentStreak > 0 ? .up : nil,
                        size: .large,
                        detailText: currentStreak > 0 ? "You're on fire! Keep the momentum going." : "Start a session today to begin your streak."
                    )
                    
                    // Right column
                    VStack(spacing: 12) {
                        ProfileStatCard(
                            title: "Focus Time",
                            value: String(format: "%.1f", totalHours),
                            unit: "hours",
                            icon: "hourglass",
                            iconColor: Color(hex: "#5856D6"),
                            size: .small,
                            detailText: totalHours >= 10 ? "Impressive dedication! You've invested real time in yourself." : "Every minute counts. Keep building your focus habit."
                        )
                        
                        ProfileStatCard(
                            title: "Sessions",
                            value: "\(sessionsCount)",
                            unit: "completed",
                            icon: "circle.inset.filled",
                            iconColor: Color(hex: "#34C759"),
                            size: .small,
                            detailText: sessionsCount >= 20 ? "Consistency master! \(sessionsCount) sessions complete." : "Each session builds your focus muscle."
                        )
                    }
                }
                .frame(height: 220) // Increased to align streak with focus+sessions
                
                // Best Streak - Full width
                ProfileStatCard(
                    title: "Best Streak",
                    value: "\(bestStreak)",
                    unit: "days",
                    icon: "crown.fill",
                    iconColor: Color(hex: "#FFD60A"),
                    trend: bestStreak >= 7 ? .up : nil,
                    size: .wide,
                    detailText: bestStreak >= 7 ? "Your personal best! Can you beat it?" : "Challenge yourself to a 7-day streak."
                )
                .frame(height: 80)
            }
            .padding(.horizontal, 24)
        }
    }
}

struct ProfileStatCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let iconColor: Color
    var trend: TrendDirection? = nil
    let size: CardSize
    var detailText: String = ""
    
    enum CardSize {
        case small, large, wide
    }
    
    enum TrendDirection {
        case up, down
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: size == .wide ? 0 : 8) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: size == .large ? 16 : 14, weight: .semibold))
                        .foregroundStyle(iconColor)
                    
                    Text(title)
                        .font(.system(size: size == .large ? 13 : 11, weight: .medium))
                        .foregroundStyle(.secondary)
                    
                    if let trend = trend {
                        Image(systemName: trend == .up ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(trend == .up ? .green : .red)
                    }
                }
                
                if size != .wide {
                    Spacer()
                }
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.system(size: size == .large ? 48 : (size == .wide ? 28 : 26), weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())
                    
                    Text(unit)
                        .font(.system(size: size == .large ? 15 : 12, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
            }
            
            if size == .wide {
                Spacer()
            }
        }
        .padding(size == .large ? 20 : 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 20))
    }
}

// MARK: - Monthly Activity Section (Minimalist GitHub Style)

struct MonthlyActivitySection: View {
    let sessions: [SessionLog]
    
    private let daysToShow = 28 // 4 weeks
    
    // Generate last 28 days of data
    private var monthData: [(date: Date, hours: Double)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return (0..<daysToShow).reversed().map { daysAgo in
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) else {
                return (date: Date(), hours: 0)
            }
            
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            let dayHours = sessions
                .filter { session in
                    guard let startTime = session.startTime else { return false }
                    return startTime >= dayStart && startTime < dayEnd
                }
                .reduce(0) { $0 + $1.duration } / 3600.0
            
            return (date: date, hours: dayHours)
        }
    }
    
    private var maxHours: Double {
        max(monthData.map { $0.hours }.max() ?? 1, 0.5)
    }
    
    private var totalHours: Double {
        monthData.reduce(0) { $0 + $1.hours }
    }
    
    private var activeDays: Int {
        monthData.filter { $0.hours > 0 }.count
    }
    
    private func intensityColor(for hours: Double) -> Color {
        if hours == 0 {
            return Color(UIColor.quaternarySystemFill)
        }
        let intensity = min(hours / maxHours, 1.0)
        if intensity < 0.33 {
            return Color.green.opacity(0.4)
        } else if intensity < 0.66 {
            return Color.green.opacity(0.7)
        } else {
            return Color.green
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with inline stats
            HStack(spacing: 12) {
                Text("Activity")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                
                Spacer()
                
                // Inline legend
                HStack(spacing: 3) {
                    ForEach([0.0, 0.3, 0.6, 1.0], id: \.self) { intensity in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(intensityColor(for: intensity * maxHours))
                            .frame(width: 10, height: 10)
                    }
                }
                
                Text(String(format: "%.1fh", totalHours))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            
            // Compact contribution grid - single horizontal row per week
            HStack(spacing: 2) {
                ForEach(0..<daysToShow, id: \.self) { index in
                    let data = monthData[index]
                    RoundedRectangle(cornerRadius: 2)
                        .fill(intensityColor(for: data.hours))
                        .frame(height: 24)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(.rect(cornerRadius: 16))
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Awards Section

struct AwardsSection: View {
    let badges: [Badge]
    let sessionsCount: Int
    let totalHours: Double
    let currentStreak: Int
    @Binding var selectedBadge: Badge?
    
    private var unlockedCount: Int {
        badges.filter { $0.condition(sessionsCount, totalHours, currentStreak) }.count
    }
    
    private var nextBadge: Badge? {
        badges.first { !$0.condition(sessionsCount, totalHours, currentStreak) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Awards")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                
                Spacer()
                
                Text("\(unlockedCount) of \(badges.count)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            
            // Next badge progress
            if let next = nextBadge {
                HStack(spacing: 12) {
                    Image(systemName: next.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 40, height: 40)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Next: \(next.name)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.primary)
                        
                        Text(next.description)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.tertiary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding(14)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: 16))
                .padding(.horizontal, 24)
                .onTapGesture {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    selectedBadge = next
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                let rows = [
                    GridItem(.fixed(148), spacing: 12),
                    GridItem(.fixed(148), spacing: 12)
                ]
                
                LazyHGrid(rows: rows, spacing: 16) {
                    ForEach(badges) { badge in
                        let achieved = badge.condition(sessionsCount, totalHours, currentStreak)
                        FitnessBadgeView(badge: badge, achieved: achieved)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    selectedBadge = badge
                                }
                            }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
            }
        }
    }
}

struct FitnessBadgeView: View {
    let badge: Badge
    let achieved: Bool
    @State private var shimmerOffset: CGFloat = -36
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Subtle outer glow for achieved
                if achieved {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.orange.opacity(0.25), .clear],
                                center: .center,
                                startRadius: 34,
                                endRadius: 54
                            )
                        )
                        .frame(width: 108, height: 108)
                }
                
                // Main badge
                Circle()
                    .fill(
                        achieved ?
                        LinearGradient(
                            colors: [Color(hex: "#FFD60A"), Color(hex: "#FF9500")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [Color(UIColor.tertiarySystemFill), Color(UIColor.quaternarySystemFill)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 72, height: 72)
                    .shadow(color: achieved ? .orange.opacity(0.35) : .clear, radius: 14, x: 0, y: 7)
                
                // Icon
                Image(systemName: badge.icon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(achieved ? Color.white : Color.secondary)
                
                // Elegant shimmer
                if achieved {
                    Circle()
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: .clear, location: 0.0),
                                    .init(color: .white.opacity(0.35), location: 0.5),
                                    .init(color: .clear, location: 1.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 72, height: 72)
                        .offset(x: shimmerOffset, y: shimmerOffset)
                        .mask(Circle().frame(width: 72, height: 72))
                        .onAppear {
                            withAnimation(
                                .linear(duration: 2.5)
                                .repeatForever(autoreverses: false)
                            ) {
                                shimmerOffset = 36
                            }
                        }
                }
            }
            .frame(width: 108, height: 108) // Fixed frame for consistent alignment
            
            Text(badge.name)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(achieved ? .primary : .tertiary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: 80, height: 32, alignment: .top)
        }
    }
}

// MARK: - Health Insights Section

struct HealthArticle: Identifiable {
    let id = UUID()
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let url: String
    let content: String
}

struct HealthInsightsSection: View {
    @Binding var selectedArticle: HealthArticle?
    
    private let articles: [HealthArticle] = [
        HealthArticle(
            icon: "eye.circle.fill",
            iconColor: Color(hex: "#5856D6"),
            title: "The 20-20-20 Rule",
            subtitle: "Reduce eye strain effectively",
            url: "https://www.aao.org/eye-health/tips-prevention/computer-usage",
            content: """
            The 20-20-20 rule is a simple yet effective technique recommended by eye care professionals to reduce digital eye strain.
            
            **How it works:**
            Every 20 minutes, take a 20-second break and look at something 20 feet away.
            
            **Why it helps:**
            When you stare at a screen, you blink less frequently—about 66% less than normal. This causes your eyes to dry out and become strained. Looking at a distant object relaxes the focusing muscle inside the eye.
            
            **Tips for success:**
            • Set a timer or use an app like Tweny
            • Keep a window nearby to look outside
            • Use eye drops if needed
            • Adjust screen brightness to match surroundings
            """
        ),
        HealthArticle(
            icon: "humidity.fill",
            iconColor: Color(hex: "#32ADE6"),
            title: "Stay Hydrated",
            subtitle: "Your eyes need water too",
            url: "https://www.healthline.com/health/dry-eyes",
            content: """
            Proper hydration is essential for maintaining healthy eyes and preventing dry eye syndrome.
            
            **The connection:**
            Your eyes are surrounded by fluid that protects and lubricates them. When you're dehydrated, your body produces fewer tears.
            
            **Signs of dehydration affecting your eyes:**
            • Dry, gritty sensation
            • Redness and irritation
            • Blurred vision
            • Light sensitivity
            
            **Recommendations:**
            • Drink 8-10 glasses of water daily
            • Keep water at your desk
            • Limit caffeine and alcohol
            • Eat water-rich foods
            """
        ),
        HealthArticle(
            icon: "slider.horizontal.3",
            iconColor: Color(hex: "#FF9F0A"),
            title: "Optimal Screen Settings",
            subtitle: "Adjust for comfort",
            url: "https://www.mayoclinic.org/diseases-conditions/eyestrain",
            content: """
            Your screen settings can significantly impact eye comfort during long work sessions.
            
            **Brightness:**
            Match your screen brightness to your environment. If your screen looks like a light source, it's too bright.
            
            **Blue light:**
            Consider using Night Shift or True Tone to reduce blue light emission, especially in the evening.
            
            **Text size:**
            Increase text size if you find yourself leaning forward. The sweet spot is when you can read comfortably at arm's length.
            
            **Position:**
            Place your screen 20-26 inches from your eyes, slightly below eye level.
            """
        ),
        HealthArticle(
            icon: "figure.stand",
            iconColor: Color(hex: "#30D158"),
            title: "Movement Breaks",
            subtitle: "Stand, stretch, reset",
            url: "https://www.health.harvard.edu/staying-healthy",
            content: """
            Regular movement breaks benefit not just your eyes, but your entire body and mind.
            
            **Why move:**
            Sitting for prolonged periods can cause muscle tension, reduced circulation, and mental fatigue.
            
            **Quick exercises:**
            • Roll your shoulders backward 10 times
            • Stretch your neck side to side
            • Stand and do 10 squats
            • Take a short walk
            
            **Eye exercises:**
            • Blink rapidly for 20 seconds
            • Roll your eyes in circles
            • Focus near and far alternately
            • Gently massage your temples
            """
        )
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Eye Health Tips")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                
                Spacer()
                
                Text("Learn more")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.blue)
            }
            .padding(.horizontal, 24)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(articles) { article in
                        HealthTipCard(article: article)
                            .onTapGesture {
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                selectedArticle = article
                            }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
}

struct HealthTipCard: View {
    let article: HealthArticle
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon with gradient background
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [article.iconColor, article.iconColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                
                Image(systemName: article.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 4) {
                Text(article.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(article.subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            // Read more indicator
            HStack(spacing: 4) {
                Text("Read more")
                    .font(.system(size: 12, weight: .medium))
                Image(systemName: "arrow.right")
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundStyle(article.iconColor)
        }
        .padding(16)
        .frame(width: 170, height: 180)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }
}

// MARK: - Article Reader View

struct ArticleReaderView: View {
    let article: HealthArticle
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack(spacing: 14) {
                        Image(systemName: article.icon)
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(article.iconColor)
                            .frame(width: 56, height: 56)
                            .background(article.iconColor.opacity(0.15))
                            .clipShape(.rect(cornerRadius: 14))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(article.title)
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                            
                            Text(article.subtitle)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.bottom, 8)
                    
                    // Content
                    Text(LocalizedStringKey(article.content))
                        .font(.system(size: 16, weight: .regular))
                        .lineSpacing(6)
                    
                    // External link
                    Link(destination: URL(string: article.url)!) {
                        HStack {
                            Image(systemName: "safari")
                            Text("Read full article")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                        }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.blue)
                        .padding(16)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(.rect(cornerRadius: 14))
                    }
                    .padding(.top, 8)
                }
                .padding(24)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Badge Detail View (Interactive 3D Apple Watch Style)

struct BadgeDetailView: View {
    let badge: Badge
    let achieved: Bool
    @Environment(\.dismiss) var dismiss
    
    // Animation states
    @State private var badgeScale: CGFloat = 0.3
    @State private var rotationY: Double = 0
    @State private var lastRotation: Double = 0  // Track the last snapped position
    @State private var showBack = false
    @State private var textAppeared = false
    @State private var showConfetti = false
    
    // Computed date for when badge was achieved (mockup - you'd store this in real app)
    private var achievedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: Date())
    }
    
    var body: some View {
        ZStack {
            // Background
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            // Confetti for achieved badges
            if showConfetti && achieved {
                BadgeConfettiView()
            }
            
            VStack(spacing: 0) {
                // Gray X button (no accent color)
                HStack {
                    Spacer()
                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color(UIColor.tertiaryLabel))
                            .frame(width: 30, height: 30)
                            .background(Color(UIColor.tertiarySystemFill))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                
                Spacer()
                
                // 3D Flippable Badge
                ZStack {
                    // BACK of badge (date)
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "#2C2C2E"), Color(hex: "#1C1C1E")],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 140, height: 140)
                            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                        
                        VStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(.white.opacity(0.7))
                            
                            Text("Achieved")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.white.opacity(0.5))
                            
                            Text(achieved ? achievedDate : "Not Yet")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                    .opacity(showBack ? 1 : 0)
                    
                    // FRONT of badge (icon)
                    ZStack {
                        // Main badge circle
                        Circle()
                            .fill(
                                achieved ?
                                LinearGradient(
                                    colors: [
                                        Color(hex: "#FFD60A"),
                                        Color(hex: "#FF9F0A"),
                                        Color(hex: "#FF6B35")
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) :
                                LinearGradient(
                                    colors: [
                                        Color(UIColor.secondarySystemFill),
                                        Color(UIColor.tertiarySystemFill)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 140, height: 140)
                            .shadow(
                                color: achieved ? .orange.opacity(0.5) : .black.opacity(0.15),
                                radius: achieved ? 30 : 15,
                                x: 0,
                                y: achieved ? 15 : 8
                            )
                            .overlay(
                                // Glossy highlight
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.white.opacity(achieved ? 0.4 : 0.2), .clear],
                                            startPoint: .top,
                                            endPoint: .center
                                        )
                                    )
                                    .frame(width: 140, height: 140)
                                    .mask(
                                        Ellipse()
                                            .frame(width: 110, height: 55)
                                            .offset(y: -35)
                                    )
                            )
                        
                        // Icon
                        Image(systemName: badge.icon)
                            .font(.system(size: 60, weight: .medium))
                            .foregroundStyle(achieved ? .white : Color(UIColor.secondaryLabel))
                            .shadow(color: achieved ? .black.opacity(0.25) : .clear, radius: 3, x: 0, y: 2)
                    }
                    .opacity(showBack ? 0 : 1)
                }
                .scaleEffect(badgeScale)
                .rotation3DEffect(.degrees(rotationY), axis: (x: 0, y: 1, z: 0))
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            // Unlimited rotation: add drag directly to last position
                            let dragAmount = Double(value.translation.width) * 0.5
                            rotationY = lastRotation + dragAmount
                            
                            // Calculate which side is showing (handle full rotations)
                            let normalized = rotationY.truncatingRemainder(dividingBy: 360)
                            let adjustedRotation = normalized < 0 ? normalized + 360 : normalized
                            showBack = adjustedRotation > 90 && adjustedRotation < 270
                        }
                        .onEnded { value in
                            // Determine which side is showing
                            let normalized = rotationY.truncatingRemainder(dividingBy: 360)
                            let adjustedRotation = normalized < 0 ? normalized + 360 : normalized
                            let shouldShowBack = adjustedRotation > 90 && adjustedRotation < 270
                            
                            // Calculate nearest snap point (could be 0, 180, 360, -180, etc.)
                            let fullRotations = floor(rotationY / 360) * 360
                            
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                if shouldShowBack {
                                    rotationY = fullRotations + 180
                                    lastRotation = fullRotations + 180
                                    showBack = true
                                } else {
                                    // Snap to nearest 0 or 360
                                    if adjustedRotation > 270 {
                                        rotationY = fullRotations + 360
                                        lastRotation = fullRotations + 360
                                    } else {
                                        rotationY = fullRotations
                                        lastRotation = fullRotations
                                    }
                                    showBack = false
                                }
                            }
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                        }
                )
                
                Spacer()
                    .frame(height: 24)
                
                // Info section
                VStack(spacing: 12) {
                    Text(badge.name)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .opacity(textAppeared ? 1 : 0)
                        .offset(y: textAppeared ? 0 : 12)
                    
                    // Status pill
                    HStack(spacing: 6) {
                        Image(systemName: achieved ? "checkmark.seal.fill" : "lock.fill")
                            .font(.system(size: 11, weight: .semibold))
                        Text(achieved ? "Unlocked" : "Locked")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(achieved ? .white : .secondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        achieved ?
                        AnyShapeStyle(Color.green) :
                        AnyShapeStyle(Color(UIColor.secondarySystemFill))
                    )
                    .clipShape(Capsule())
                    .opacity(textAppeared ? 1 : 0)
                    .offset(y: textAppeared ? 0 : 8)
                    
                    Text(badge.description)
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .padding(.horizontal, 32)
                        .opacity(textAppeared ? 1 : 0)
                        .offset(y: textAppeared ? 0 : 6)
                    
                    // Share button for achieved badges
                    if achieved {
                        ShareLink(
                            item: "I just earned the \"\(badge.name)\" badge in Tweny! 🏆 \(badge.description)",
                            subject: Text("My Tweny Achievement"),
                            message: Text("Check out my progress!")
                        ) {
                            HStack(spacing: 6) {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share")
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color(UIColor.secondarySystemFill))
                            .clipShape(Capsule())
                        }
                        .padding(.top, 8)
                        .opacity(textAppeared ? 1 : 0)
                    }
                }
                
                Spacer()
            }
        }
        .onAppear {
            // Entrance animation
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                badgeScale = 1.0
            }
            
            // Initial celebratory spin for achieved badges (then resets to 0)
            if achieved {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.1)) {
                    rotationY = 360
                }
                // Reset rotation after animation so gesture works from 0
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                    rotationY = 0
                }
                
                // Trigger confetti
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    showConfetti = true
                }
            }
            
            // Text fade in
            withAnimation(.easeOut(duration: 0.5).delay(0.35)) {
                textAppeared = true
            }
        }
    }
}

// Confetti specifically for badge achievements
struct BadgeConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    
    struct ConfettiParticle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        let color: Color
        let size: CGFloat
        var opacity: Double = 1
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { particle in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size * 0.6)
                        .rotationEffect(.degrees(Double.random(in: 0...360)))
                        .position(x: particle.x, y: particle.y)
                        .opacity(particle.opacity)
                }
            }
            .onAppear {
                createParticles(in: geo.size)
            }
        }
        .allowsHitTesting(false)
    }
    
    private func createParticles(in size: CGSize) {
        // Golden/warm achievement colors
        let colors: [Color] = [
            Color(hex: "#FFD700"), // Gold
            Color(hex: "#FFA500"), // Orange
            Color(hex: "#FF8C00"), // Dark orange
            Color(hex: "#FFB347"), // Light orange
            Color(hex: "#FFDF00"), // Golden yellow
            .white
        ]
        let centerX = size.width / 2
        let centerY = size.height * 0.32
        
        for i in 0..<40 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.012) {
                let particle = ConfettiParticle(
                    x: centerX + CGFloat.random(in: -20...20),
                    y: centerY,
                    color: colors.randomElement()!,
                    size: CGFloat.random(in: 5...12)
                )
                particles.append(particle)
                
                // Burst outward with physics-like motion
                let angle = Double.random(in: -Double.pi...Double.pi)
                let distance = CGFloat.random(in: 80...180)
                let targetX = centerX + cos(angle) * distance
                let targetY = centerY + sin(angle) * distance - CGFloat.random(in: 20...60)
                
                withAnimation(.easeOut(duration: Double.random(in: 0.6...1.0))) {
                    if let index = particles.firstIndex(where: { $0.id == particle.id }) {
                        particles[index].x = targetX
                        particles[index].y = targetY
                    }
                }
                
                // Fade out
                withAnimation(.easeOut(duration: 0.4).delay(0.5)) {
                    if let index = particles.firstIndex(where: { $0.id == particle.id }) {
                        particles[index].opacity = 0
                    }
                }
            }
        }
    }
}

// MARK: - Confetti View

struct ConfettiView: View {
    @State private var animate = false
    
    private let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<50, id: \.self) { index in
                    let randomX = CGFloat.random(in: -geometry.size.width/2...geometry.size.width/2)
                    let randomY = CGFloat.random(in: -geometry.size.height/2...geometry.size.height/2)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(colors[index % colors.count])
                        .frame(width: 8, height: 8)
                        .offset(
                            x: animate ? randomX : 0,
                            y: animate ? randomY : 0
                        )
                        .opacity(animate ? 0 : 1)
                        .scaleEffect(animate ? CGFloat.random(in: 0.5...1.5) : 0.1)
                        .rotationEffect(.degrees(animate ? Double.random(in: 180...720) : 0))
                        .animation(
                            .easeOut(duration: Double.random(in: 1.5...2.5))
                            .delay(Double(index) * 0.02),
                            value: animate
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            animate = true
        }
    }
}

