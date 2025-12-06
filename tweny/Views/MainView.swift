//
//  MainView.swift
//  tweny
//
//  Created by GitHub Copilot on 29/11/25.
//

import SwiftUI

struct MainView: View {
    @StateObject private var timerManager = TimerManager.shared
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showingOnboarding = false
    @State private var showingTimerView = false
    @Namespace private var animation
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView {
                HomeView(viewModel: HomeViewModel(timerManager: timerManager))
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
                
                ProfileView()
                    .tabItem {
                        Label("Insights", systemImage: "chart.bar.fill")
                    }
                
                HistoryView()
                    .tabItem {
                        Label("History", systemImage: "clock.arrow.circlepath")
                    }
            }
            .accentColor(.primary)
            
            // Custom Accessory View (Simulating tabViewBottomAccessory)
            if !showingTimerView {
                SessionAccessoryView(timerManager: timerManager, namespace: animation)
                    .padding(.bottom, 60)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.88)) {
                            showingTimerView = true
                        }
                    }
                    .gesture(
                        DragGesture()
                            .onEnded { gesture in
                                if gesture.translation.height < -50 {
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.88)) {
                                        showingTimerView = true
                                    }
                                }
                            }
                    )
            }
            
            if showingTimerView {
                TimerView(viewModel: HomeViewModel(timerManager: timerManager), isPresented: $showingTimerView, namespace: animation)
                    .zIndex(1)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            if !hasSeenOnboarding {
                showingOnboarding = true
            }
        }
        .fullScreenCover(isPresented: $showingOnboarding, onDismiss: {
            hasSeenOnboarding = true
        }) {
            OnboardingView(isPresented: $showingOnboarding)
        }
        .onOpenURL { url in
            handleURL(url)
        }
    }
    
    private func handleURL(_ url: URL) {
        switch url.scheme {
        case "tweny":
            switch url.host {
            case "open":
                showingTimerView = true
            case "toggle":
                if timerManager.phase == .paused {
                    timerManager.resumeSession()
                } else {
                    timerManager.pauseSession()
                }
            case "stop":
                timerManager.stopSession()
                showingTimerView = false
            default:
                break
            }
        default:
            break
        }
    }
}
