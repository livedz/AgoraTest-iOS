//
//  VoiceOrbView.swift
//  AgoraTest
//
//  Created by MOKSHA on 03/08/26.
//

import SwiftUI

struct VoiceOrbView: View {

    let audioLevel: Int
    let isMuted: Bool
    let callState: CallState

    @State private var isBreathing = false
    @State private var rotation = 0.0

    var body: some View {
        ZStack {
            outerGlow

            middleGlow

            coreOrb

            microphoneIcon
        }
        .frame(width: 230, height: 230)
        .onAppear {
            isBreathing = true

            withAnimation(
                .linear(duration: 12)
                .repeatForever(autoreverses: false)
            ) {
                rotation = 360
            }
        }
    }

    private var normalizedLevel: CGFloat {
        let clampedLevel = min(max(audioLevel, 0), 255)
        return CGFloat(clampedLevel) / 255
    }

    private var activeScale: CGFloat {
        guard callState == .connected, !isMuted else {
            return 1
        }

        return 1 + normalizedLevel * 0.35
    }

    private var outerGlow: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        .purple.opacity(0.28),
                        .blue.opacity(0.12),
                        .clear
                    ],
                    center: .center,
                    startRadius: 10,
                    endRadius: 115
                )
            )
            .scaleEffect(
                isBreathing ? 1.08 * activeScale : 0.94
            )
            .animation(
                .easeInOut(duration: 1.8)
                .repeatForever(autoreverses: true),
                value: isBreathing
            )
            .animation(
                .easeOut(duration: 0.16),
                value: audioLevel
            )
    }

    private var middleGlow: some View {
        Circle()
            .stroke(
                AngularGradient(
                    colors: [
                        .blue,
                        .purple,
                        .cyan,
                        .blue
                    ],
                    center: .center
                ),
                lineWidth: 7
            )
            .frame(width: 150, height: 150)
            .rotationEffect(.degrees(rotation))
            .scaleEffect(activeScale)
            .opacity(callState == .ended ? 0.25 : 0.85)
            .animation(
                .easeOut(duration: 0.16),
                value: audioLevel
            )
    }

    private var coreOrb: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: isMuted
                        ? [
                            .gray.opacity(0.8),
                            .gray.opacity(0.5)
                        ]
                        : [
                            .blue,
                            .purple
                        ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 118, height: 118)
            .scaleEffect(activeScale)
            .shadow(
                color: isMuted
                    ? .clear
                    : .purple.opacity(0.45),
                radius: 25
            )
            .animation(
                .spring(
                    response: 0.22,
                    dampingFraction: 0.7
                ),
                value: audioLevel
            )
    }

    private var microphoneIcon: some View {
        Image(
            systemName: isMuted
                ? "mic.slash.fill"
                : "waveform"
        )
        .font(.system(size: 38, weight: .semibold))
        .foregroundStyle(.white)
        .symbolEffect(
            .pulse,
            options: .repeating,
            value: callState == .connecting
        )
    }
}

#Preview {
    VoiceOrbView(
        audioLevel: 70,
        isMuted: false,
        callState: .connected
    )
}
