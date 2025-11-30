//
//  DataManager.swift
//  tweny
//
//  Created by GitHub Copilot on 29/11/25.
//

import SwiftUI
import Combine

class DataManager: ObservableObject {
    static let shared = DataManager()
    
    @Published var presets: [SessionPreset] = []
    @Published var userName: String = "Focus User"
    @Published var profileImageData: Data?
    
    private let presetsKey = "saved_presets"
    private let userNameKey = "user_name"
    private let profileImageKey = "user_profile_image"
    
    init() {
        loadPresets()
        loadUserName()
        loadProfileImage()
    }
    
    // MARK: - User Profile
    func loadUserName() {
        if let name = UserDefaults.standard.string(forKey: userNameKey) {
            userName = name
        }
    }
    
    func saveUserName(_ name: String) {
        userName = name
        UserDefaults.standard.set(name, forKey: userNameKey)
    }
    
    func loadProfileImage() {
        if let data = UserDefaults.standard.data(forKey: profileImageKey) {
            profileImageData = data
        }
    }
    
    func saveProfileImage(_ data: Data?) {
        profileImageData = data
        UserDefaults.standard.set(data, forKey: profileImageKey)
    }
    
    // MARK: - Presets
    func loadPresets() {
        if let data = UserDefaults.standard.data(forKey: presetsKey),
           let decoded = try? JSONDecoder().decode([SessionPreset].self, from: data) {
            presets = decoded
        } else {
            presets = SessionPreset.defaults
        }
    }
    
    func savePreset(_ preset: SessionPreset) {
        if let index = presets.firstIndex(where: { $0.id == preset.id }) {
            presets[index] = preset
        } else {
            presets.append(preset)
        }
        persistPresets()
    }
    
    func deletePreset(at offsets: IndexSet) {
        presets.remove(atOffsets: offsets)
        persistPresets()
    }
    
    private func persistPresets() {
        if let encoded = try? JSONEncoder().encode(presets) {
            UserDefaults.standard.set(encoded, forKey: presetsKey)
        }
    }
}

struct Badge: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let description: String
    let condition: (Int, Double, Int) -> Bool // (sessions, hours, streak)
}

extension DataManager {
    var allBadges: [Badge] {
        [
            Badge(name: "First Step", icon: "figure.walk", description: "Complete your first session", condition: { s, _, _ in s >= 1 }),
            Badge(name: "Consistency", icon: "calendar", description: "Reach a 3-day streak", condition: { _, _, st in st >= 3 }),
            Badge(name: "Marathon", icon: "figure.run", description: "Focus for 10 total hours", condition: { _, h, _ in h >= 10 }),
            Badge(name: "Zen Master", icon: "leaf.fill", description: "Focus for 50 total hours", condition: { _, h, _ in h >= 50 }),
            Badge(name: "Deep Diver", icon: "arrow.down.circle.fill", description: "Complete 50 sessions", condition: { s, _, _ in s >= 50 }),
            Badge(name: "Flow State", icon: "wind", description: "Reach a 7-day streak", condition: { _, _, st in st >= 7 }),
            Badge(name: "Time Lord", icon: "clock.badge.checkmark.fill", description: "Focus for 100 total hours", condition: { _, h, _ in h >= 100 }),
            Badge(name: "Century Club", icon: "trophy.fill", description: "Complete 100 sessions", condition: { s, _, _ in s >= 100 }),
            Badge(name: "Focus God", icon: "crown.fill", description: "Focus for 500 total hours", condition: { _, h, _ in h >= 500 }),
            Badge(name: "Unstoppable", icon: "flame.circle.fill", description: "Reach a 30-day streak", condition: { _, _, st in st >= 30 })
        ]
    }
}
