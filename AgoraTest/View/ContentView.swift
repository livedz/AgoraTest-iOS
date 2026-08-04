//
//  ContentView.swift
//  AgoraTest
//
//  Created by MOKSHA on 03/08/26.
//
import SwiftUI

struct ContentView: View {

    @StateObject private var agoraManager = AgoraManager()

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {

                statusSection

                permissionSection

                connectionSection

                audioLevelSection(
                    title: "Your microphone",
                    level: agoraManager.localAudioLevel,
                    icon: agoraManager.isMuted
                        ? "mic.slash.fill"
                        : "mic.fill"
                )

                audioLevelSection(
                    title: "Remote audio",
                    level: agoraManager.remoteAudioLevel,
                    icon: "speaker.wave.2.fill"
                )

                controlsSection
            }
            .padding(24)
            .frame(maxWidth: 500)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Status

    private var statusSection: some View {
        Text(agoraManager.statusMessage)
            .font(.headline)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }

    private var permissionSection: some View {
        HStack {
            Image(
                systemName: microphonePermissionIcon
            )

            Text(
                "Microphone: \(agoraManager.microphonePermission)"
            )

            Spacer()
        }
        .font(.subheadline)
        .foregroundStyle(microphonePermissionColor)
        .padding()
        .background(
            Color.secondary.opacity(0.1),
            in: RoundedRectangle(cornerRadius: 14)
        )
    }

    private var microphonePermissionIcon: String {
        switch agoraManager.microphonePermission {
        case "Granted":
            return "checkmark.circle.fill"

        case "Denied":
            return "xmark.circle.fill"

        default:
            return "questionmark.circle.fill"
        }
    }

    private var microphonePermissionColor: Color {
        switch agoraManager.microphonePermission {
        case "Granted":
            return .green

        case "Denied":
            return .red

        default:
            return .secondary
        }
    }

    // MARK: - Connection

    private var connectionSection: some View {
        Group {
            if let remoteUID = agoraManager.remoteUserID {
                Label(
                    "Connected with UID: \(remoteUID)",
                    systemImage: "person.2.fill"
                )
                .foregroundStyle(.green)
            } else if agoraManager.isJoined {
                Label(
                    "Waiting for another user",
                    systemImage: "person.crop.circle.badge.clock"
                )
                .foregroundStyle(.orange)
            } else {
                Label(
                    "Not connected",
                    systemImage: "person.2.slash"
                )
                .foregroundStyle(.secondary)
            }
        }
        .font(.subheadline)
    }

    // MARK: - Audio Levels

    private func audioLevelSection(
        title: String,
        level: Int,
        icon: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 24)

                Text(title)

                Spacer()

                Text("\(level)")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }

            ProgressView(
                value: Double(level),
                total: 255
            )
        }
    }

    // MARK: - Controls

    private var controlsSection: some View {
        VStack(spacing: 14) {

            Button {
                agoraManager.joinChannel()
            } label: {
                Label(
                    agoraManager.isJoined
                        ? "Connected"
                        : "Join Channel",
                    systemImage: agoraManager.isJoined
                        ? "checkmark.circle.fill"
                        : "phone.fill"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(agoraManager.isJoined)

            Button {
                agoraManager.toggleMicrophone()
            } label: {
                Label(
                    agoraManager.isMuted
                        ? "Unmute"
                        : "Mute",
                    systemImage: agoraManager.isMuted
                        ? "mic.slash.fill"
                        : "mic.fill"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(agoraManager.isMuted ? .orange : .blue)
            .disabled(!agoraManager.isJoined)

            Button(role: .destructive) {
                agoraManager.leaveChannel()
            } label: {
                Label(
                    "Leave Channel",
                    systemImage: "phone.down.fill"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(!agoraManager.isJoined)
        }
    }
}

#Preview {
    ContentView()
}
