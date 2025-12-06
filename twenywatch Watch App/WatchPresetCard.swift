//
//  WatchPresetCard.swift
//  twenywatch Watch App
//
//  Compact preset card for Apple Watch
//

import SwiftUI

struct WatchPresetCard: View {
    let preset: WatchPreset
    let onTap: () -> Void
    
    var presetColor: Color {
        Color(hex: preset.colorHex)
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                // Icon
                Text(preset.icon)
                    .font(.system(size: 24))
                    .frame(width: 36, height: 36)
                    .background(presetColor.opacity(0.2))
                    .clipShape(Circle())
                
                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(preset.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    HStack(spacing: 6) {
                        HStack(spacing: 2) {
                            Image(systemName: "timer")
                                .font(.system(size: 9))
                            Text("\(Int(preset.workInterval / 60))m")
                                .font(.system(size: 10, weight: .medium))
                        }
                        
                        HStack(spacing: 2) {
                            Image(systemName: "target")
                                .font(.system(size: 9))
                            Text("\(Int(preset.sessionGoal / 3600))h")
                                .font(.system(size: 10, weight: .medium))
                        }
                    }
                    .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Play indicator
                Image(systemName: "play.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(presetColor)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(white: 0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(presetColor.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
