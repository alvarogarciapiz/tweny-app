//
//  EyeHealthView.swift
//  tweny
//
//  Created by GitHub Copilot on 30/11/25.
//

import SwiftUI

struct EyeHealthView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Hero Image/Icon
                HStack {
                    Spacer()
                    Image(systemName: "eye.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                        .padding()
                        .background(Circle().fill(Color.blue.opacity(0.1)))
                    Spacer()
                }
                .padding(.top)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Digital Eye Strain")
                        .font(.title)
                        .bold()
                    Text("Computer Vision Syndrome")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                Text("Digital eye strain describes a group of eye and vision-related problems that result from prolonged computer, tablet, e-reader and cell phone use.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .lineSpacing(4)
                
                // Tips Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Practical Tips")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(spacing: 16) {
                        HealthTipRow(icon: "clock.arrow.2.circlepath", title: "The 20-20-20 Rule", description: "Every 20 minutes, look at something 20 feet away for 20 seconds.")
                        HealthTipRow(icon: "sun.max.fill", title: "Adjust Lighting", description: "Ensure your room is well-lit and avoid glare on your screen.")
                        HealthTipRow(icon: "arrow.up.and.down.and.arrow.left.and.right", title: "Screen Distance", description: "Keep your screen about an arm's length (20-28 inches) away.")
                        HealthTipRow(icon: "drop.fill", title: "Blink Often", description: "Blinking keeps your eyes moist. Staring at screens reduces blink rate.")
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding(.bottom)
        }
        .navigationTitle("Eye Health Info")
    }
}

struct HealthTipRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
}
