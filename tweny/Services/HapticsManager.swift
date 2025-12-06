//
//  HapticsManager.swift
//  tweny
//
//  Created by GitHub Copilot on 29/11/25.
//

import UIKit

class HapticsManager {
    static let shared = HapticsManager()
    
    var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: "isHapticsEnabled")
    }
    
    func playLightImpact() {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    func playMediumImpact() {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    func playSuccess() {
        guard isEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    func playWarning() {
        guard isEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
}
