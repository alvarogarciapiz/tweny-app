//
//  OnboardingView.swift
//  tweny
//
//  Created by GitHub Copilot on 30/11/25.
//

import SwiftUI
import UserNotifications

// MARK: - User Roles
enum UserRole: String, CaseIterable, Identifiable {
    case student = "Student"
    case developer = "Developer"
    case office = "Office Worker"
    case creative = "Creative"
    case other = "Other"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .student: return "book.fill"
        case .developer: return "laptopcomputer"
        case .office: return "briefcase.fill"
        case .creative: return "paintpalette.fill"
        case .other: return "person.fill"
        }
    }
    
    var description: String {
        switch self {
        case .student: return "Balanced intervals for study sessions."
        case .developer: return "Longer focus blocks for deep coding."
        case .office: return "Classic Pomodoro for productivity."
        case .creative: return "Extended flow states for creation."
        case .other: return "Standard 20-20-20 rule."
        }
    }
    
    var preset: SessionPreset {
        switch self {
        case .student:
            return SessionPreset(name: "Study Session", sessionGoal: 4 * 3600, workInterval: 45 * 60, breakInterval: 10 * 60, colorHex: "#007AFF", icon: "📚")
        case .developer:
            return SessionPreset(name: "Dev Mode", sessionGoal: 6 * 3600, workInterval: 50 * 60, breakInterval: 7 * 60, colorHex: "#5856D6", icon: "💻")
        case .office:
            return SessionPreset(name: "Productivity", sessionGoal: 8 * 3600, workInterval: 25 * 60, breakInterval: 5 * 60, colorHex: "#FF9500", icon: "💼")
        case .creative:
            return SessionPreset(name: "Flow State", sessionGoal: 4 * 3600, workInterval: 60 * 60, breakInterval: 15 * 60, colorHex: "#FF2D55", icon: "🎨")
        case .other:
            return SessionPreset(name: "Balanced", sessionGoal: 4 * 3600, workInterval: 20 * 60, breakInterval: 20, colorHex: "#34C759", icon: "⚖️")
        }
    }
}

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    @State private var userName: String = ""
    @State private var selectedRole: UserRole?
    @StateObject private var dataManager = DataManager.shared
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress Indicator
                HStack(spacing: 6) {
                    ForEach(0..<6) { index in
                        Capsule()
                            .fill(index <= currentPage ? Color.primary : Color.secondary.opacity(0.2))
                            .frame(height: 4)
                            .frame(maxWidth: .infinity)
                            .animation(.spring(), value: currentPage)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 20)
                .padding(.bottom, 20)
                
                TabView(selection: $currentPage) {
                    // 1. Welcome
                    OnboardingPage(
                        image: "brain.head.profile",
                        title: "Welcome to Tweny",
                        description: "Your personal assistant for digital eye health. Master your focus and prevent strain.",
                        color: .indigo
                    )
                    .tag(0)
                    
                    // 2. The Rule
                    OnboardingPage(
                        image: "eye.fill",
                        title: "The 20-20-20 Rule",
                        description: "Every 20 minutes, look at something 20 feet away for 20 seconds. We'll handle the timing.",
                        color: .blue
                    )
                    .tag(1)
                    
                    // 3. Name Input
                    OnboardingNamePage(name: $userName)
                        .tag(2)
                    
                    // 4. Use Case (New)
                    OnboardingUseCasePage(selectedRole: $selectedRole)
                        .tag(3)
                    
                    // 5. Notifications
                    OnboardingNotificationPage()
                        .tag(4)
                    
                    // 6. All Set
                    OnboardingPage(
                        image: "checkmark.seal.fill",
                        title: "You're All Set",
                        description: "Start your first session and build healthy digital habits today.",
                        color: .green
                    )
                    .tag(5)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Bottom Controls
                VStack(spacing: 16) {
                    Button(action: handleNext) {
                        Text(currentPage == 5 ? "Get Started" : "Continue")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Color(UIColor.systemBackground))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.primary)
                            .cornerRadius(16)
                            .shadow(color: Color.primary.opacity(0.1), radius: 10, x: 0, y: 5)
                    }
                    .disabled(shouldDisableButton)
                    .opacity(shouldDisableButton ? 0.5 : 1)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 20)
            }
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    var shouldDisableButton: Bool {
        if currentPage == 2 && userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return true }
        if currentPage == 3 && selectedRole == nil { return true }
        return false
    }
    
    private func handleNext() {
        // Dismiss keyboard
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        if currentPage == 2 {
            dataManager.saveUserName(userName)
        }
        
        if currentPage == 3, let role = selectedRole {
            // Save the personalized preset
            dataManager.savePreset(role.preset)
        }
        
        if currentPage < 5 {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                currentPage += 1
            }
        } else {
            withAnimation {
                isPresented = false
            }
        }
    }
}

// MARK: - Subviews

struct OnboardingPage: View {
    let image: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 160, height: 160)
                
                Image(systemName: image)
                    .font(.system(size: 72))
                    .foregroundColor(color)
            }
            .padding(.bottom, 16)
            
            VStack(spacing: 16) {
                Text(title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .lineSpacing(4)
            }
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

struct OnboardingNamePage: View {
    @Binding var name: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Text("What's your name?")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                
                Text("We'll use this to personalize your experience.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            TextField("Your Name", text: $name)
                .font(.system(size: 24, weight: .medium, design: .rounded))
                .multilineTextAlignment(.center)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(UIColor.secondarySystemBackground))
                )
                .padding(.horizontal, 32)
                .focused($isFocused)
                .submitLabel(.done)
            
            Spacer()
            Spacer()
        }
        .contentShape(Rectangle()) // Make entire area tappable
        .onTapGesture {
            isFocused = false
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isFocused = true
            }
        }
    }
}

struct OnboardingUseCasePage: View {
    @Binding var selectedRole: UserRole?
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                Text("How will you use Tweny?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                
                Text("We'll create a custom preset for you.")
                    .font(.system(size: 17))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            .padding(.bottom, 32) // Added margin between title and list
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    ForEach(UserRole.allCases) { role in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedRole = role
                            }
                        }) {
                            HStack(spacing: 16) {
                                // Icon Container
                                ZStack {
                                    Circle()
                                        .fill(selectedRole == role ? Color.primary : Color(UIColor.secondarySystemBackground))
                                        .frame(width: 52, height: 52)
                                    
                                    Image(systemName: role.icon)
                                        .font(.system(size: 22))
                                        .foregroundColor(selectedRole == role ? Color(UIColor.systemBackground) : .primary)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(role.rawValue)
                                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                                        .foregroundColor(.primary)
                                    
                                    Text(role.description)
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                
                                Spacer()
                                
                                // Selection Indicator (Radio Button Style)
                                ZStack {
                                    Circle()
                                        .strokeBorder(selectedRole == role ? Color.primary : Color.secondary.opacity(0.2), lineWidth: 2)
                                        .frame(width: 24, height: 24)
                                    
                                    if selectedRole == role {
                                        Circle()
                                            .fill(Color.primary)
                                            .frame(width: 14, height: 14)
                                    }
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(Color(UIColor.systemBackground))
                                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 24)
                                            .stroke(selectedRole == role ? Color.primary : Color.clear, lineWidth: 2)
                                    )
                            )
                            .scaleEffect(selectedRole == role ? 1.02 : 1.0)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 8) // Extra padding to prevent clipping
                .padding(.bottom, 40)
            }
        }
    }
}

struct OnboardingNotificationPage: View {
    @State private var status: UNAuthorizationStatus = .notDetermined
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 160, height: 160)
                
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 72))
                    .foregroundColor(.orange)
            }
            .padding(.bottom, 16)
            
            VStack(spacing: 16) {
                Text("Stay in the Loop")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                
                Text("Enable notifications to see your timer on the Lock Screen and get reminded when breaks end.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .lineSpacing(4)
            }
            
            Button(action: requestPermissions) {
                HStack {
                    Text(buttonText)
                        .fontWeight(.medium)
                    if status == .authorized {
                        Image(systemName: "checkmark")
                    }
                }
                .foregroundColor(status == .authorized ? .green : .primary)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .strokeBorder(status == .authorized ? Color.green : Color.primary.opacity(0.2), lineWidth: 1)
                )
            }
            .disabled(status == .authorized)
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
        .onAppear(perform: checkStatus)
    }
    
    var buttonText: String {
        switch status {
        case .authorized: return "Notifications Enabled"
        case .denied: return "Notifications Denied"
        default: return "Enable Notifications"
        }
    }
    
    func checkStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.status = settings.authorizationStatus
            }
        }
    }
    
    func requestPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                self.status = granted ? .authorized : .denied
            }
        }
    }
}
