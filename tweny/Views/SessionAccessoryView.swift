//
//  SessionAccessoryView.swift
//  tweny
//
//  Created by GitHub Copilot on 30/11/25.
//

import SwiftUI

struct SessionAccessoryView: View {
    @ObservedObject var timerManager: TimerManager
    var namespace: Namespace.ID
    
    var body: some View {
        if timerManager.phase != .idle {
            HStack(spacing: 8) {
                // Icon
                Text(timerManager.currentPresetIcon)
                    .font(.system(size: 18))
                    .frame(width: 30, height: 30)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Circle())
                
                // Info
                VStack(alignment: .leading, spacing: 0) {
                    Text(timerManager.currentPresetName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(statusText)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Controls
                HStack(spacing: 0) {
                    Button(action: {
                        if timerManager.phase == .paused {
                            timerManager.resumeSession()
                        } else {
                            timerManager.pauseSession()
                        }
                    }) {
                        Image(systemName: timerManager.phase == .paused ? "play.fill" : "pause.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                            .frame(width: 36, height: 36)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        timerManager.stopSession()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.secondary)
                            .frame(width: 36, height: 36)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 32)
                    .fill(.ultraThinMaterial)
                    .matchedGeometryEffect(id: "background", in: namespace)
                    .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 32)
                            .stroke(
                                LinearGradient(
                                    stops: [
                                        .init(color: .white.opacity(0.6), location: 0),
                                        .init(color: .white.opacity(0.2), location: 0.2),
                                        .init(color: .white.opacity(0.1), location: 0.5),
                                        .init(color: .white.opacity(0.3), location: 1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                            .matchedGeometryEffect(id: "border", in: namespace)
                    )
            )
            .padding(.horizontal, 60) // More compressed width
            .transition(.asymmetric(
                insertion: .move(edge: .bottom).combined(with: .opacity),
                removal: .opacity
            ))
        }
    }
    
    var statusText: String {
        if timerManager.phase == .paused {
            return "Paused"
        } else if timerManager.phase == .breakTime {
            return "Break Time"
        } else {
            let progress = Int(timerManager.progress * 100)
            return "\(progress)% Completed"
        }
    }
}
