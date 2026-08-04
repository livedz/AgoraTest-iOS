//
//  CallHeaderView.swift
//  AgoraTest
//
//  Created by MOKSHA on 03/08/26.
//

import SwiftUI

struct CallHeaderView: View {

    let assistant: Assistant
    let callState: CallState
    let elapsedSeconds: Int

    var body: some View {
        VStack(spacing: 10) {
            assistantAvatar

            Text(assistant.name)
                .font(.system(size: 30, weight: .bold))

            Text(assistant.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(callState.title)
                .font(.headline)
                .foregroundStyle(statusColor)

            if callState == .connected {
                Text(formattedDuration)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
        .multilineTextAlignment(.center)
    }

    private var assistantAvatar: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            .blue.opacity(0.9),
                            .purple.opacity(0.9)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 104, height: 104)

            if let image = assistant.image {
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 96, height: 96)
                    .clipShape(Circle())
            } else {
                Image(systemName: "sparkles")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .shadow(
            color: .purple.opacity(0.25),
            radius: 20,
            y: 10
        )
    }

    private var statusColor: Color {
        switch callState {
        case .idle:
            return .secondary

        case .connecting, .reconnecting:
            return .orange

        case .connected:
            return .green

        case .ended:
            return .red
        }
    }

    private var formattedDuration: String {
        let hours = elapsedSeconds / 3_600
        let minutes = (elapsedSeconds % 3_600) / 60
        let seconds = elapsedSeconds % 60

        if hours > 0 {
            return String(
                format: "%02d:%02d:%02d",
                hours,
                minutes,
                seconds
            )
        }

        return String(
            format: "%02d:%02d",
            minutes,
            seconds
        )
    }
}

#Preview {
    CallHeaderView(
        assistant: Assistant(
            name: "Nova",
            subtitle: "Voice Assistant",
            image: nil
        ),
        callState: .connected,
        elapsedSeconds: 83
    )
}
