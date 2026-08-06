# Agora AI Voice Assistant (SwiftUI + FastAPI)

A real-time AI voice assistant built with **SwiftUI**, **Agora RTC**, **FastAPI**, and **Agora Conversational AI**.

The project demonstrates how to build a two-way voice conversation between an iOS application and an AI assistant using Agora's Conversational AI platform.

## ✨ Features

- 🎙️ Real-time voice calls using Agora RTC
- 🤖 AI Assistant powered by Agora Conversational AI
- 🧠 Gemini LLM integration (BYOK)
- 🗣️ Deepgram Speech-to-Text (ASR)
- 🔊 MiniMax Text-to-Speech (TTS)
- 🔐 Secure RTC token generation using FastAPI
- 📱 Modern SwiftUI calling interface
- ⏱️ Live call timer
- 🎤 Mute / Unmute microphone
- 🔈 Speaker toggle
- 📶 Connection state monitoring
- 🤖 Automatic AI agent start & stop

---

## Architecture

```
SwiftUI App
      │
      │ RTC Token Request
      ▼
FastAPI Backend
      │
      ├── Generate RTC Token
      └── Start Agora AI Agent
                │
                ▼
Agora Conversational AI
      │
      ├── Deepgram (Speech Recognition)
      ├── Gemini (LLM)
      └── MiniMax (Text To Speech)
```

---

## Tech Stack

### iOS

- SwiftUI
- Agora iOS SDK
- AVFoundation
- URLSession
- Combine

### Backend

- Python
- FastAPI
- Uvicorn
- HTTPX

### AI Services

- Agora Conversational AI
- Google Gemini
- Deepgram ASR
- MiniMax TTS

---

## Backend Endpoints

### Generate RTC Token

```
GET /rtc-token
```

Returns

```json
{
    "appId": "...",
    "token": "...",
    "channel": "Test",
    "uid": 1001
}
```

---

### Start AI Agent

```
POST /agent/start
```

```json
{
    "channel":"Test"
}
```

---

### Stop AI Agent

```
POST /agent/stop
```

---

## Project Structure

```
AgoraBackend/
│
├── main.py
├── agent_service.py
├── token_service.py
├── config.py
├── models.py
└── .env
```

```
AgoraTest/
│
├── AgoraManager.swift
├── AudioCallView.swift
├── VoiceOrbView.swift
├── CallHeaderView.swift
└── Components/
```

---

## Environment Variables

```
AGORA_APP_ID=
AGORA_APP_CERTIFICATE=
AGORA_CUSTOMER_ID=
AGORA_CUSTOMER_SECRET=
AGORA_PIPELINE_ID=

GEMINI_API_KEY=
```

> Never commit `.env` files or API keys to GitHub.

---

## Running the Backend

```bash
python3 -m uvicorn main:app --reload --port 8000
```

Swagger

```
http://127.0.0.1:8000/docs
```

---

## Running the iOS App

1. Start the FastAPI backend.
2. Launch the SwiftUI app.
3. Request RTC token.
4. Join Agora channel.
5. Backend starts AI agent.
6. Begin voice conversation.

---

## Current Status

✅ RTC token generation

✅ Agora channel connection

✅ AI agent lifecycle management

✅ Gemini integration

✅ Deepgram ASR

✅ MiniMax TTS

✅ SwiftUI voice call interface

⚠️ Note: Audio quality and microphone behavior may vary when testing in the iOS Simulator. A physical iOS device is recommended for the best real-time voice experience.

---

## Future Improvements

- Conversation history
- Voice selection
- Multi-language support
- Streaming transcription
- Interruptible AI responses
- Call recording
- Authentication
- Push notifications

---

## License

MIT

<img width="1320" height="2868" alt="simulator_screenshot_1792A7DD-C06B-47D7-B953-22F5D55FA236" src="https://github.com/user-attachments/assets/5986f97d-4316-4e5c-9695-8d88644afd7b" />

<img width="1320" height="2868" alt="simulator_screenshot_3A9F67EF-58F0-476E-A65B-659AD4949FA6" src="https://github.com/user-attachments/assets/49e2da17-b84b-44d9-a47f-0cee176c7d13" />
