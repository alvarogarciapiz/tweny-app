//
//  TimerView.swift
//  tweny
//
//  Created by GitHub Copilot on 30/11/25.
//

import SwiftUI

struct TimerView: View {
    @ObservedObject var viewModel: HomeViewModel
    @Binding var isPresented: Bool
    var namespace: Namespace.ID
    
    // Drag to dismiss state
    @State private var dragOffset = CGSize.zero
    @State private var isContentVisible = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Grabber Handle
            Capsule()
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 60)
                .padding(.bottom, 24)
                .opacity(isContentVisible ? 1 : 0)
                .scaleEffect(isContentVisible ? 1 : 0.5)
            
            // Header: Preset info + Session progress
            HStack(spacing: 14) {
                // Preset icon with ring
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.15), lineWidth: 2.5)
                        .frame(width: 46, height: 46)
                    
                    Circle()
                        .trim(from: 0, to: viewModel.sessionProgress)
                        .stroke(
                            viewModel.isBreak ? Color.green : Color.blue,
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                        )
                        .frame(width: 46, height: 46)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.5), value: viewModel.sessionProgress)
                    
                    Text(viewModel.timerManager.currentPresetIcon)
                        .font(.system(size: 18))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.timerManager.currentPresetName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.primary)
                    
                    Text(viewModel.isBreak ? "Break • Look away" : "Focus • \(Int(viewModel.sessionProgress * 100))% of goal")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Phase indicator pill
                Text(viewModel.isBreak ? "BREAK" : "FOCUS")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.5)
                    .foregroundStyle(viewModel.isBreak ? Color.green : Color.blue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(viewModel.isBreak ? Color.green.opacity(0.15) : Color.blue.opacity(0.15))
                    )
            }
            .padding(.horizontal, 28)
            .opacity(isContentVisible ? 1 : 0)
            .offset(y: isContentVisible ? 0 : 16)
            
            Spacer()
            
            // Main Timer
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.secondary.opacity(0.1), lineWidth: 12)
                    .frame(width: 260, height: 260)
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: viewModel.progress)
                    .stroke(
                        viewModel.isBreak ? Color.green : Color.primary,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 260, height: 260)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: viewModel.progress)
                
                // Timer text
                VStack(spacing: 6) {
                    Text(viewModel.timerText)
                        .font(.system(size: 54, weight: .regular, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())
                    
                    Text(viewModel.isBreak ? "seconds left" : "until break")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.tertiary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                }
            }
            .opacity(isContentVisible ? 1 : 0)
            .scaleEffect(isContentVisible ? 1 : 0.92)
            .offset(y: isContentVisible ? 0 : 16)
            
            Spacer()
            
            // Controls
            HStack(spacing: 56) {
                // End Button
                Button(action: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) { 
                        isContentVisible = false
                        viewModel.stop()
                        isPresented = false
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(Color(UIColor.secondarySystemBackground))
                            .frame(width: 68, height: 68)
                            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
                        
                        Image(systemName: "xmark")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(Color(UIColor.label).opacity(0.5))
                    }
                }
                
                // Pause/Resume Button
                Button(action: {
                    if viewModel.timerManager.phase == .paused {
                        viewModel.timerManager.resumeSession()
                    } else {
                        viewModel.pause()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(viewModel.isBreak ? Color.green : Color.primary)
                            .frame(width: 68, height: 68)
                            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                        
                        Image(systemName: viewModel.timerManager.phase == .paused ? "play.fill" : "pause.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(Color(UIColor.systemBackground))
                    }
                }
            }
            .padding(.bottom, 56)
            .opacity(isContentVisible ? 1 : 0)
            .offset(y: isContentVisible ? 0 : 32)
        }
        .background(
            RoundedRectangle(cornerRadius: 0)
                .fill(.ultraThinMaterial)
                .matchedGeometryEffect(id: "background", in: namespace)
                .ignoresSafeArea()
                .overlay(
                    RoundedRectangle(cornerRadius: 0)
                        .stroke(Color.white.opacity(0), lineWidth: 1)
                        .matchedGeometryEffect(id: "border", in: namespace)
                        .ignoresSafeArea()
                )
        )
        .offset(y: dragOffset.height)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                isContentVisible = true
            }
        }
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    if gesture.translation.height > 0 {
                        dragOffset = gesture.translation
                    }
                }
                .onEnded { gesture in
                    if gesture.translation.height > 120 {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                            isContentVisible = false
                            isPresented = false
                        }
                        dragOffset = .zero
                    } else {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            dragOffset = .zero
                        }
                    }
                }
        )
    }
}
