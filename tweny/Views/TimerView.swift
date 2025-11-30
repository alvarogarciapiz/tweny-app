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
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, 60) // Adjusted for safe area
                .padding(.bottom, 20)
                .opacity(isContentVisible ? 1 : 0)
            
            // 1. Top Info (Session Progress)
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.isBreak ? "BREAK TIME" : "FOCUS SESSION")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)
                        .tracking(1.5)
                    
                    Text(viewModel.isBreak ? "Relax your eyes" : "Stay focused")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                }
                Spacer()
                
                // Minimalist Pill
                HStack(spacing: 6) {
                    Circle()
                        .fill(viewModel.isBreak ? Color.green : Color.primary)
                        .frame(width: 6, height: 6)
                    Text("\(Int(viewModel.sessionProgress * 100))%")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(UIColor.secondarySystemBackground))
                .clipShape(Capsule())
            }
            .padding(.horizontal, 32)
            .opacity(isContentVisible ? 1 : 0)
            .offset(y: isContentVisible ? 0 : 20)
            
            Spacer()
            
            // 2. Main Timer (Clean & Thin)
            ZStack {
                CircularProgressView(
                    progress: viewModel.progress,
                    color: viewModel.isBreak ? .green : .primary,
                    lineWidth: 16
                )
                .frame(width: 280, height: 280)
                
                Text(viewModel.timerText)
                    .font(.system(size: 72, weight: .light)) // Thin/Light for elegance
                    .monospacedDigit()
            }
            .opacity(isContentVisible ? 1 : 0)
            .scaleEffect(isContentVisible ? 1 : 0.9)
            .offset(y: isContentVisible ? 0 : 20)
            
            Spacer()
            
            // 3. Controls (Standard iOS Style)
            HStack(spacing: 60) {
                // End Button (Secondary)
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
                            .frame(width: 72, height: 72)
                        
                        Image(systemName: "xmark")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                // Pause/Resume Button (Primary)
                Button(action: {
                    withAnimation {
                        if viewModel.timerManager.phase == .paused {
                            viewModel.timerManager.resumeSession()
                        } else {
                            viewModel.pause()
                        }
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.primary)
                            .frame(width: 72, height: 72)
                        
                        Image(systemName: viewModel.timerManager.phase == .paused ? "play.fill" : "pause.fill")
                            .font(.system(size: 28))
                            .foregroundColor(Color(UIColor.systemBackground))
                    }
                }
            }
            .padding(.bottom, 60)
            .opacity(isContentVisible ? 1 : 0)
            .offset(y: isContentVisible ? 0 : 40)
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
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
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
                    if gesture.translation.height > 150 {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                            isContentVisible = false
                            isPresented = false
                        }
                        dragOffset = .zero
                    } else {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            dragOffset = .zero
                        }
                    }
                }
        )
    }
}
