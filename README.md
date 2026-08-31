# 🎙️ Mio — Real-Time AI Voice Companion

A real-time AI voice companion that allows users to have natural, two-way conversations with an AI assistant using their voice.

Instead of typing messages into a chat interface, users can simply speak naturally. Mio listens, understands the conversation, and responds back with AI-generated speech in real time.

Built with **SwiftUI**, **Agora RTC**, **FastAPI**, and **Agora Conversational AI**.

---

## 💡 The Problem

Most AI assistants are primarily text-based.

Users need to:

⌨️ Type a question
⌨️ Wait for a response
⌨️ Read the answer
⌨️ Type a follow-up question

This can feel slow and unnatural, especially when users want to have a longer or more conversational interaction.

---

## ✨ The Solution

**Mio enables natural, real-time voice conversations with an AI assistant.**

Users can simply speak:

> 🎙️ "I have an interview tomorrow. Can you help me prepare?"

Mio listens to the user, understands the conversation, and responds naturally through voice.

The conversation continues in real time:

```text
User speaks 🎙️
       ↓
Mio listens 👂
       ↓
Speech is converted to text
       ↓
AI understands the request 🧠
       ↓
AI generates a response
       ↓
Mio responds with voice 🔊
```

---

## 🎯 End-User Use Case

Mio is designed for natural conversational experiences where typing is not the most convenient way to interact with AI.

For example:

### 💼 Interview Preparation

> "I have a Senior iOS Developer interview tomorrow. Can you ask me some interview questions?"

Mio can begin a natural voice conversation and continue asking follow-up questions.

### 📚 Learning & Practice

> "Help me practice SwiftUI concepts."

The user can learn through a natural back-and-forth voice conversation.

### 🧠 Everyday AI Conversations

> "Help me plan my day."

> "Explain this topic to me simply."

> "Let's practice English conversation."

---

## 🔄 How It Works

```text
                    🎙️ User Speaks
                           │
                           ▼
                   Agora RTC Voice
                           │
                           ▼
                Deepgram Speech-to-Text
                           │
                           ▼
                    Gemini LLM 🧠
                           │
                           ▼
                  AI Generates Response
                           │
                           ▼
                 MiniMax Text-to-Speech
                           │
                           ▼
                    🔊 Mio Responds
```

---

## ✨ Features

* 🎙️ Real-time two-way voice conversations
* 🤖 AI assistant powered by Agora Conversational AI
* 🧠 Gemini LLM integration using BYOK
* 🗣️ Deepgram Speech-to-Text (ASR)
* 🔊 MiniMax Text-to-Speech (TTS)
* 🔐 Secure RTC token generation using FastAPI
* 📱 Modern SwiftUI voice calling interface
* ⏱️ Live call timer
* 🎤 Mute / Unmute microphone
* 🔈 Speaker toggle
* 📶 Connection state monitoring
* 🤖 Automatic AI agent start & stop

---

# 🏗️ Technical Architecture

```text
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
      └── MiniMax (Text-to-Speech)
```


<img width="1320" height="2868" alt="simulator_screenshot_1792A7DD-C06B-47D7-B953-22F5D55FA236" src="https://github.com/user-attachments/assets/5986f97d-4316-4e5c-9695-8d88644afd7b" />

<img width="1320" height="2868" alt="simulator_screenshot_3A9F67EF-58F0-476E-A65B-659AD4949FA6" src="https://github.com/user-attachments/assets/49e2da17-b84b-44d9-a47f-0cee176c7d13" />
