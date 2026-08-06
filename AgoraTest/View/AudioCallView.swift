//
//  AudioCallView.swift
//  AgoraTest
//
//  Created by MOKSHA on 03/08/26.
//

import SwiftUI

struct AudioCallView: View {

    @StateObject private var agoraManager = AgoraManager()

    let assistant: Assistant

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                topBar

                Spacer()

                CallHeaderView(
                    assistant: assistant,
                    callState: agoraManager.callState,
                    elapsedSeconds: agoraManager.elapsedSeconds
                )

                Spacer(minLength: 30)

                VoiceOrbView(
                    audioLevel: activeAudioLevel,
                    isMuted: agoraManager.isMuted,
                    callState: agoraManager.callState
                )

                Spacer()

                connectionMessage
                if agoraManager.callState == .ended {
                    Button {
                        agoraManager.joinChannel()
                    } label: {
                        Label(
                            "Call Again",
                            systemImage: "phone.fill"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.bottom, 20)
                }
                callControls
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .task {
            guard agoraManager.callState == .idle else {
                return
            }

            agoraManager.joinChannel()
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [
                Color.blue.opacity(0.10),
                Color.purple.opacity(0.08),
                Color(.systemBackground)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var topBar: some View {
        HStack {
            Text("Voice Call")
                .font(.headline)

            Spacer()

            connectionIndicator
        }
    }

    private var connectionIndicator: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(connectionColor)
                .frame(width: 8, height: 8)

            Text(connectionTitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var connectionColor: Color {
        switch agoraManager.callState {
        case .connected:
            return .green

        case .connecting, .reconnecting:
            return .orange

        case .idle, .ended:
            return .gray
        }
    }

    private var connectionTitle: String {
        switch agoraManager.callState {
        case .idle:
            return "Ready"

        case .connecting:
            return "Connecting"

        case .connected:
            return "Live"

        case .reconnecting:
            return "Reconnecting"

        case .ended:
            return "Ended"
        }
    }

    private var activeAudioLevel: Int {
        if agoraManager.remoteAudioLevel > 0 {
            return agoraManager.remoteAudioLevel
        }

        return agoraManager.localAudioLevel
    }

    private var connectionMessage: some View {
        Group {
            if let remoteUID = agoraManager.remoteUserID {
                Text("Connected with UID \(remoteUID)")
            } else if agoraManager.isJoined {
                Text("Waiting for the assistant to join…")
            } else {
                Text(agoraManager.statusMessage)
            }
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .padding(.bottom, 26)
    }

    private var callControls: some View {
        HStack(spacing: 34) {
            CallControlButton(
                title: agoraManager.isMuted ? "Unmute" : "Mute",
                systemImage: agoraManager.isMuted
                    ? "mic.slash.fill"
                    : "mic.fill",
                style: agoraManager.isMuted ? .active : .normal,
                isDisabled: !agoraManager.isJoined
            ) {
                agoraManager.toggleMicrophone()
            }

            CallControlButton(
                title: agoraManager.isSpeakerEnabled
                    ? "Speaker"
                    : "Earpiece",
                systemImage: agoraManager.isSpeakerEnabled
                    ? "speaker.wave.3.fill"
                    : "speaker.fill",
                style: agoraManager.isSpeakerEnabled
                    ? .active
                    : .normal,
                isDisabled: !agoraManager.isJoined 
            ) {
                agoraManager.toggleSpeaker()
            }

            CallControlButton(
                title: "End",
                systemImage: "phone.down.fill",
                style: .destructive,
                isDisabled: !agoraManager.isJoined
            ) {
                agoraManager.leaveChannel()
            }
        }
    }
}

#Preview {
    AudioCallView(
        assistant: Assistant(
            name: "Nova",
            subtitle: "Voice Assistant",
            image: nil
        )
    )
}
