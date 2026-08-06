//
//  AgoraManager.swift
//  AgoraTest
//
//  Created by MOKSHA on 03/08/26.

import Foundation
import Combine
import AVFoundation
import AgoraRtcKit

// MARK: - Agora Manager

@MainActor
final class AgoraManager: NSObject, ObservableObject {

    // MARK: Published State

    @Published private(set) var isJoined = false
    @Published private(set) var isMuted = false
    @Published private(set) var isSpeakerEnabled = true
    @Published private(set) var isStartingAgent = false

    @Published private(set) var statusMessage = "Not connected"
    @Published private(set) var microphonePermission = "Not requested"

    @Published private(set) var remoteUserID: UInt?
    @Published private(set) var agentID: String?

    @Published private(set) var localAudioLevel = 0
    @Published private(set) var remoteAudioLevel = 0

    @Published private(set) var callState: CallState = .idle
    @Published private(set) var elapsedSeconds = 0

    // MARK: Private Properties

    private var engine: AgoraRtcEngineKit?
    private var callTimer: Timer?

    private let backendBaseURL = "http://127.0.0.1:8000"
    private let channelName = "Test"
    private let localUID: UInt = 1001

    // Prevents duplicate /agent/start requests.
    private var didRequestAgentStart = false

    // MARK: Initialization

    override init() {
        super.init()
        updateMicrophonePermissionStatus()
    }

    // MARK: Microphone Permission

    private func updateMicrophonePermissionStatus() {
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            microphonePermission = "Granted"

        case .denied:
            microphonePermission = "Denied"

        case .undetermined:
            microphonePermission = "Not requested"

        @unknown default:
            microphonePermission = "Unknown"
        }
    }

    private func requestMicrophonePermission(
        completion: @escaping (Bool) -> Void
    ) {
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            microphonePermission = "Granted"
            completion(true)

        case .denied:
            microphonePermission = "Denied"
            statusMessage = "Microphone permission is denied"
            callState = .idle
            completion(false)

        case .undetermined:
            AVAudioApplication.requestRecordPermission { [weak self] granted in
                Task { @MainActor in
                    guard let self else {
                        return
                    }

                    self.microphonePermission = granted
                        ? "Granted"
                        : "Denied"

                    if !granted {
                        self.statusMessage =
                            "Microphone permission is required"
                        self.callState = .idle
                    }

                    completion(granted)
                }
            }

        @unknown default:
            microphonePermission = "Unknown"
            statusMessage =
                "Unable to determine microphone permission"
            callState = .idle
            completion(false)
        }
    }

    // MARK: Join Channel

    func joinChannel() {
        guard !isJoined else {
            statusMessage = "Already connected"
            return
        }

        guard callState != .connecting else {
            statusMessage = "Already connecting"
            return
        }

        callState = .connecting
        statusMessage = "Requesting microphone permission…"

        requestMicrophonePermission { [weak self] granted in
            guard granted, let self else {
                return
            }

            Task {
                await self.fetchTokenAndJoin()
            }
        }
    }

    private func fetchTokenAndJoin() async {
        statusMessage = "Requesting Agora token…"

        guard var components = URLComponents(
            string: "\(backendBaseURL)/rtc-token"
        ) else {
            handleJoinFailure("Invalid backend URL")
            return
        }

        components.queryItems = [
            URLQueryItem(
                name: "channel",
                value: channelName
            ),
            URLQueryItem(
                name: "uid",
                value: String(localUID)
            )
        ]

        guard let url = components.url else {
            handleJoinFailure("Could not create token URL")
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(
                from: url
            )

            guard let httpResponse = response as? HTTPURLResponse else {
                handleJoinFailure("Invalid backend response")
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                let backendMessage = String(
                    data: data,
                    encoding: .utf8
                ) ?? "Unknown backend error"

                handleJoinFailure(
                    "Token request failed "
                    + "\(httpResponse.statusCode): "
                    + backendMessage
                )
                return
            }

            let tokenResponse = try JSONDecoder().decode(
                AgoraTokenResponse.self,
                from: data
            )

            guard tokenResponse.channel == channelName else {
                handleJoinFailure(
                    "Backend returned the wrong channel"
                )
                return
            }

            guard tokenResponse.uid == localUID else {
                handleJoinFailure(
                    "Backend returned the wrong UID"
                )
                return
            }

            setupAgoraEngine(
                appID: tokenResponse.appId
            )

            guard engine != nil else {
                handleJoinFailure(
                    "Unable to initialize Agora"
                )
                return
            }

            print("✅ Token received")
            print("Channel:", tokenResponse.channel)
            print("UID:", tokenResponse.uid)

            performJoinChannel(
                token: tokenResponse.token,
                uid: tokenResponse.uid
            )

        } catch {
            handleJoinFailure(
                "Token request failed: "
                + error.localizedDescription
            )
        }
    }

    // MARK: Engine Setup

    private func setupAgoraEngine(appID: String) {
        guard engine == nil else {
            return
        }

        let cleanAppID = appID.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !cleanAppID.isEmpty else {
            statusMessage = "Backend returned an empty App ID"
            callState = .idle
            return
        }

        let configuration = AgoraRtcEngineConfig()
        configuration.appId = cleanAppID

        let agoraEngine = AgoraRtcEngineKit.sharedEngine(
            with: configuration,
            delegate: self
        )

        agoraEngine.enableAudio()

        agoraEngine.enableAudioVolumeIndication(
            200,
            smooth: 3,
            reportVad: true
        )

        #if targetEnvironment(simulator)
        agoraEngine.disableVideo()
        #else
        agoraEngine.enableVideo()
        #endif

        engine = agoraEngine
    }

    private func performJoinChannel(
        token: String,
        uid: UInt
    ) {
        guard let engine else {
            handleJoinFailure(
                "Agora engine is unavailable"
            )
            return
        }

        let cleanToken = token.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !cleanToken.isEmpty else {
            handleJoinFailure(
                "Backend returned an empty token"
            )
            return
        }

        let options = AgoraRtcChannelMediaOptions()

        options.channelProfile = .communication
        options.clientRoleType = .broadcaster

        options.publishMicrophoneTrack = true
        options.publishCameraTrack = false

        options.autoSubscribeAudio = true
        options.autoSubscribeVideo = false

        statusMessage = "Joining \(channelName)…"

        print("➡️ Calling Agora joinChannel")

        let result = engine.joinChannel(
            byToken: cleanToken,
            channelId: channelName,
            uid: uid,
            mediaOptions: options
        )

        print("Join result:", result)

        if result != 0 {
            handleJoinFailure(
                agoraJoinErrorMessage(for: result)
            )
        }
    }

    private func handleJoinFailure(
        _ message: String
    ) {
        statusMessage = message
        callState = .idle
    }

    // MARK: Start AI Agent

    private func startAgent(
        channel: String
    ) async {
        guard !didRequestAgentStart else {
            return
        }

        guard !isStartingAgent else {
            return
        }

        didRequestAgentStart = true
        isStartingAgent = true
        statusMessage = "Starting assistant…"

        defer {
            isStartingAgent = false
        }

        guard let url = URL(
            string: "\(backendBaseURL)/agent/start"
        ) else {
            didRequestAgentStart = false
            statusMessage = "Invalid agent backend URL"
            return
        }

        struct AgentRequestBody: Encodable {
            let channel: String
        }

        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.timeoutInterval = 45

            request.setValue(
                "application/json",
                forHTTPHeaderField: "Content-Type"
            )

            request.setValue(
                "application/json",
                forHTTPHeaderField: "Accept"
            )

            request.httpBody = try JSONEncoder().encode(
                AgentRequestBody(channel: channel)
            )

            let (data, response) = try await URLSession.shared.data(
                for: request
            )

            guard let httpResponse = response as? HTTPURLResponse else {
                didRequestAgentStart = false
                statusMessage = "Invalid agent backend response"
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                didRequestAgentStart = false

                let backendMessage = String(
                    data: data,
                    encoding: .utf8
                ) ?? "Unknown backend error"

                statusMessage =
                    "Agent start failed "
                    + "\(httpResponse.statusCode): "
                    + backendMessage

                return
            }

            let result = try JSONDecoder().decode(
                AgentStartResponse.self,
                from: data
            )

            agentID = result.agora.agentId
            statusMessage = "Waiting for assistant to join…"

            print(
                "✅ Agent started:",
                result.agora.agentId
            )

        } catch {
            didRequestAgentStart = false

            statusMessage =
                "Agent request failed: "
                + error.localizedDescription
        }
    }

    // MARK: Leave Channel

    func leaveChannel() {
        guard isJoined || callState == .connecting else {
            statusMessage = "Not connected"
            return
        }

        engine?.leaveChannel(nil)

        stopCallTimer()
        resetCallState()

        callState = .ended
        statusMessage = "Call ended"
    }

    // MARK: Microphone

    func toggleMicrophone() {
        guard isJoined else {
            statusMessage = "Join the channel first"
            return
        }

        let newMutedState = !isMuted

        let result = engine?.muteLocalAudioStream(
            newMutedState
        ) ?? -1

        guard result == 0 else {
            statusMessage =
                "Microphone update failed: \(result)"
            return
        }

        isMuted = newMutedState

        if newMutedState {
            localAudioLevel = 0
            statusMessage = "Microphone muted"
        } else {
            statusMessage = remoteUserID == nil
                ? "Waiting for assistant to join…"
                : "Microphone unmuted"
        }
    }

    // MARK: Speaker

    func toggleSpeaker() {
        guard isJoined else {
            statusMessage = "Join the channel first"
            return
        }

        let newValue = !isSpeakerEnabled

        let result = engine?.setEnableSpeakerphone(
            newValue
        ) ?? -1

        guard result == 0 else {
            statusMessage =
                "Speaker update failed: \(result)"
            return
        }

        isSpeakerEnabled = newValue

        statusMessage = newValue
            ? "Speaker enabled"
            : "Earpiece enabled"
    }

    // MARK: Timer

    private func startCallTimer() {
        callTimer?.invalidate()
        elapsedSeconds = 0

        callTimer = Timer.scheduledTimer(
            withTimeInterval: 1,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                self?.elapsedSeconds += 1
            }
        }
    }

    private func stopCallTimer() {
        callTimer?.invalidate()
        callTimer = nil
        elapsedSeconds = 0
    }

    // MARK: Helpers

    private func resetCallState() {
        isJoined = false
        isMuted = false
        isSpeakerEnabled = true
        isStartingAgent = false

        remoteUserID = nil
        agentID = nil

        localAudioLevel = 0
        remoteAudioLevel = 0

        didRequestAgentStart = false
    }

    private func agoraJoinErrorMessage(
        for code: Int32
    ) -> String {
        switch code {
        case -2:
            return "Invalid Agora parameter"

        case -3:
            return "Agora SDK is not ready"

        case -5:
            return "Agora request was rejected"

        case -7:
            return "Agora SDK is not initialized"

        case -17:
            return "Already connected or currently joining"

        default:
            return "Join request failed: \(code)"
        }
    }

    // MARK: Cleanup

    deinit {
        callTimer?.invalidate()
        engine?.leaveChannel(nil)
        AgoraRtcEngineKit.destroy()
    }
}

// MARK: - Agora Delegate

extension AgoraManager: AgoraRtcEngineDelegate {

    nonisolated func rtcEngine(
        _ engine: AgoraRtcEngineKit,
        didJoinChannel channel: String,
        withUid uid: UInt,
        elapsed: Int
    ) {
        print("✅ Agora joined:", channel, uid)

        Task { @MainActor in
            self.isJoined = true
            self.callState = .connected
            self.statusMessage = "Connected"
            self.startCallTimer()

            await self.startAgent(
                channel: channel
            )
        }
    }

    nonisolated func rtcEngine(
        _ engine: AgoraRtcEngineKit,
        didJoinedOfUid uid: UInt,
        elapsed: Int
    ) {
        print("🤖 Remote user joined:", uid)

        Task { @MainActor in
            self.remoteUserID = uid
            self.statusMessage = "Assistant joined"
        }
    }

    nonisolated func rtcEngine(
        _ engine: AgoraRtcEngineKit,
        didOfflineOfUid uid: UInt,
        reason: AgoraUserOfflineReason
    ) {
        print(
            "👋 Remote user left:",
            uid,
            "reason:",
            reason.rawValue
        )

        Task { @MainActor in
            guard self.remoteUserID == uid else {
                return
            }

            self.remoteUserID = nil
            self.remoteAudioLevel = 0
            self.statusMessage = "Assistant disconnected"
        }
    }

    nonisolated func rtcEngine(
        _ engine: AgoraRtcEngineKit,
        reportAudioVolumeIndicationOfSpeakers speakers: [AgoraRtcAudioVolumeInfo],
        totalVolume: Int
    ) {
        Task { @MainActor in
            var currentLocalLevel = 0
            var currentRemoteLevel = 0

            for speaker in speakers {
                let volume = Int(speaker.volume)

                if speaker.uid == 0 {
                    currentLocalLevel = volume
                } else {
                    currentRemoteLevel = max(
                        currentRemoteLevel,
                        volume
                    )
                }
            }

            self.localAudioLevel = self.isMuted
                ? 0
                : currentLocalLevel

            self.remoteAudioLevel = currentRemoteLevel
        }
    }

    nonisolated func rtcEngine(
        _ engine: AgoraRtcEngineKit,
        connectionChangedTo state: AgoraConnectionState,
        reason: AgoraConnectionChangedReason
    ) {
        print(
            "Agora connection state:",
            state.rawValue,
            "reason:",
            reason.rawValue
        )

        Task { @MainActor in
            switch state {
            case .reconnecting:
                self.callState = .reconnecting
                self.statusMessage = "Reconnecting…"

            case .connected:
                if self.isJoined {
                    self.callState = .connected
                }

            case .failed:
                self.stopCallTimer()
                self.resetCallState()
                self.callState = .ended
                self.statusMessage =
                    "Connection failed: \(reason.rawValue)"

            case .disconnected:
                if self.isJoined {
                    self.stopCallTimer()
                    self.resetCallState()
                    self.callState = .ended
                    self.statusMessage = "Disconnected"
                }

            default:
                break
            }
        }
    }

    nonisolated func rtcEngine(
        _ engine: AgoraRtcEngineKit,
        didOccurError errorCode: AgoraErrorCode
    ) {
        print(
            "Agora error:",
            errorCode.rawValue
        )

        Task { @MainActor in
            self.statusMessage =
                "Agora error: \(errorCode.rawValue)"

            if !self.isJoined {
                self.callState = .idle
            }
        }
    }
}
