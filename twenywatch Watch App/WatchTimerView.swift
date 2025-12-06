//
//  WatchTimerView.swift
//  twenywatch Watch App
//
//  Timer view adapted for Apple Watch
//

import SwiftUI

struct WatchTimerView: View {
    @ObservedObject var sessionManager: WatchSessionManager
    
    var phaseColor: Color {
        Color(hex: sessionManager.currentPresetColorHex)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Phase indicator
            HStack(spacing: 4) {
                Image(systemName: sessionManager.isBreak ? "eye.slash" : "eye")
                    .font(.system(size: 10, weight: .semibold))
                Text(sessionManager.isBreak ? "BREAK" : "FOCUS")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.5)
            }
            .foregroundStyle(phaseColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(phaseColor.opacity(0.2))
            .clipShape(Capsule())
            
            // Timer with progress ring
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 8)
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: sessionManager.progress)
                    .stroke(phaseColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                // Timer text
                VStack(spacing: 2) {
                    Text(sessionManager.currentPresetIcon)
                        .font(.system(size: 20))
                    
                    Text(formatTime(sessionManager.timeRemaining))
                        .font(.system(size: 28, weight: .medium, design: .rounded))
                        .monospacedDigit()
                }
            }
            .frame(width: 120, height: 120)
            
            // Controls
            HStack(spacing: 16) {
                Button(action: {
                    sessionManager.togglePauseResume()
                }) {
                    Image(systemName: sessionManager.phase == .paused ? "play.fill" : "pause.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 44, height: 44)
                        .background(Color.primary.opacity(0.15))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    sessionManager.stopSession()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 44, height: 44)
                        .background(Color.secondary.opacity(0.15))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
    }
    
    func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// Color+Hex extension for Watch
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
            (a, r, g, b) = (255, 0, 122, 255)
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
