//
//  CircularProgressView.swift
//  tweny
//
//  Created by GitHub Copilot on 29/11/25.
//

import SwiftUI

struct CircularProgressView: View {
    var progress: Double
    var color: Color
    var lineWidth: CGFloat = 20
    
    var body: some View {
        ZStack {
            // Background Track
            Circle()
                .stroke(Color(UIColor.secondarySystemBackground), lineWidth: lineWidth)
            
            // Progress - Clean & Solid
            Circle()
                .trim(from: 0.0, to: CGFloat(min(self.progress, 1.0)))
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                )
                .rotationEffect(Angle(degrees: 270.0))
                .animation(.smooth, value: progress)
        }
    }
}
