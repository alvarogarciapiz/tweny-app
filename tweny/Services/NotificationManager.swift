//
//  NotificationManager.swift
//  tweny
//
//  Created by GitHub Copilot on 29/11/25.
//

import Foundation
import UserNotifications

class NotificationManager: NSObject {
    static let shared = NotificationManager()
    
    override init() {
        super.init()
        requestAuthorization()
    }
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error requesting notification authorization: \(error)")
            }
        }
    }
    
    func scheduleNotification(title: String, body: String, timeInterval: TimeInterval, soundName: String? = nil) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        
        if let soundName = soundName {
            content.sound = UNNotificationSound(named: UNNotificationSoundName(soundName))
        } else {
            content.sound = .default
        }
        
        // Focus-Aware: Set interruption level to timeSensitive to break through Focus modes if allowed
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
