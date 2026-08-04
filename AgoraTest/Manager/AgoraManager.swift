//
//  AgoraManager.swift
//  AgoraTest
//
//  Created by MOKSHA on 03/08/26.
//
//
//  AgoraManager.swift
//  AgoraTest
//

import SwiftUI
import Combine
import AgoraRtcKit
import AVFoundation

@MainActor
final class AgoraManager: NSObject, ObservableObject {

                    // MARK: - Published State

                    @Published private(set) var isJoined = false
                    @Published private(set) var isMuted = false

                    @Published private(set) var statusMessage = "Not connected"
                    @Published private(set) var microphonePermission = "Not requested"

                    @Published private(set) var remoteUserID: UInt?

                    @Published private(set) var localAudioLevel = 0
                    @Published private(set) var remoteAudioLevel = 0

                    @Published private(set) var callState: CallState = .idle
                    @Published private(set) var elapsedSeconds = 0
                    @Published private(set) var isSpeakerEnabled = true
                    // MARK: - Private Properties

                    private var engine: AgoraRtcEngineKit?
                    private var callTimer: Timer?

                    private let appID = "37bcc6d78bd4462c92cf14ebb0d31718"
                    private let channelName = "Test"
                    // Keep UID 0 while using an automatically assigned Agora UID.
                    private let localUID: UInt = 1001
                    private let backendBaseURL = "http://127.0.0.1:8000"
                    // MARK: - Initialization

                    override init() {
                        super.init()

                        updateMicrophonePermissionStatus()
                    }

                    // MARK: - Engine Setup
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
                    // MARK: - Microphone Permission

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

                                    if granted {
                                        completion(true)
                                    } else {
                                        self.statusMessage = "Microphone permission is required"
                                        self.callState = .idle
                                        completion(false)
                                    }
                                }
                            }

                        @unknown default:
                            microphonePermission = "Unknown"
                            statusMessage = "Unable to determine microphone permission"
                            callState = .idle
                            completion(false)
                        }
                    }

                    // MARK: - Channel

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
            guard granted else {
                return
            }

            Task {
                await self?.fetchTokenAndJoin()
            }
        }
    }

    private func fetchTokenAndJoin() async {
        statusMessage = "Requesting Agora token…"

        guard var components = URLComponents(
            string: "\(backendBaseURL)/rtc-token"
        ) else {
            statusMessage = "Invalid backend URL"
            callState = .idle
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
            statusMessage = "Could not create token URL"
            callState = .idle
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(
                from: url
            )

            guard let httpResponse = response as? HTTPURLResponse else {
                statusMessage = "Invalid backend response"
                callState = .idle
                return
            }

            guard httpResponse.statusCode == 200 else {
                let message = String(
                    data: data,
                    encoding: .utf8
                ) ?? "Unknown backend error"

                statusMessage =
                    "Backend error \(httpResponse.statusCode): \(message)"

                callState = .idle
                return
            }

            let tokenResponse = try JSONDecoder().decode(
                AgoraTokenResponse.self,
                from: data
            )
            guard tokenResponse.channel == channelName else {
                statusMessage = "Backend returned the wrong channel"
                callState = .idle
                return
            }
            setupAgoraEngine(appID: tokenResponse.appId)

            guard engine != nil else {
                statusMessage = "Unable to initialize Agora"
                callState = .idle
                return
            }
            
            print("✅ Token received")
            print("App ID length:", tokenResponse.appId.count)
            print("Token length:", tokenResponse.token.count)
            print("Channel:", tokenResponse.channel)
            print("UID:", tokenResponse.uid)
            
            performJoinChannel(
                token: tokenResponse.token,
                uid: tokenResponse.uid
            )

        } catch {
            statusMessage =
                "Token request failed: \(error.localizedDescription)"

            callState = .idle
        }
    }

    private func performJoinChannel(
        token: String,
        uid: UInt
    ) {
        guard let engine else {
            statusMessage = "Agora engine is unavailable"
            callState = .idle
            return
        }

        let options = AgoraRtcChannelMediaOptions()

        options.channelProfile = .communication
        options.clientRoleType = .broadcaster
        options.publishMicrophoneTrack = true
        options.autoSubscribeAudio = true
        options.autoSubscribeVideo = false

        #if targetEnvironment(simulator)
        options.publishCameraTrack = false
        #else
        options.publishCameraTrack = true
        #endif

        statusMessage = "Joining \(channelName)…"

        let result = engine.joinChannel(
            byToken: token,
            channelId: channelName,
            uid: uid,
            mediaOptions: options
        )

        if result != 0 {
            statusMessage = agoraJoinErrorMessage(for: result)
            callState = .idle
        }
        
        print("➡️ Calling Agora joinChannel")
        print("Join result:", result)
    }
                  
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

                    // MARK: - Microphone Controls

                    func toggleMicrophone() {
                        guard isJoined else {
                            statusMessage = "Join the channel first"
                            return
                        }

                        let newMutedState = !isMuted
                        let result = engine?.muteLocalAudioStream(newMutedState) ?? -1

                        guard result == 0 else {
                            statusMessage = "Microphone update failed: \(result)"
                            return
                        }

                        isMuted = newMutedState

                        if newMutedState {
                            localAudioLevel = 0
                            statusMessage = "Microphone muted"
                        } else {
                            statusMessage = "Microphone unmuted"
                        }
                    }

    func toggleSpeaker() {
        guard isJoined else {
            statusMessage = "Join the channel first"
            return
        }

        let newValue = !isSpeakerEnabled
        let result = engine?.setEnableSpeakerphone(newValue) ?? -1

        guard result == 0 else {
            statusMessage = "Speaker update failed: \(result)"
            return
        }

        isSpeakerEnabled = newValue
    }
                    // MARK: - Call Timer

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
                    }

                    // MARK: - Helpers
    private func resetCallState() {
        isJoined = false
        isMuted = false
        isSpeakerEnabled = true

        remoteUserID = nil

        localAudioLevel = 0
        remoteAudioLevel = 0
        elapsedSeconds = 0
    }

                    private func agoraJoinErrorMessage(for code: Int32) -> String {
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

                    // MARK: - Cleanup

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
                        }
                    }

                    nonisolated func rtcEngine(
                        _ engine: AgoraRtcEngineKit,
                        didJoinedOfUid uid: UInt,
                        elapsed: Int
                    ) {
                        Task { @MainActor in
                            self.remoteUserID = uid
                            self.statusMessage = "Remote user joined: \(uid)"
                        }
                    }

                    nonisolated func rtcEngine(
                        _ engine: AgoraRtcEngineKit,
                        didOfflineOfUid uid: UInt,
                        reason: AgoraUserOfflineReason
                    ) {
                        Task { @MainActor in
                            guard self.remoteUserID == uid else {
                                return
                            }

                            self.remoteUserID = nil
                            self.remoteAudioLevel = 0
                            self.statusMessage = "Remote user left"
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
                        didOccurError errorCode: AgoraErrorCode
                    ) {
                        Task { @MainActor in
                            self.statusMessage = "Agora error: \(errorCode.rawValue)"

                            if !self.isJoined {
                                self.callState = .idle
                            }
                        }
                    }
                }
