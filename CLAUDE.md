# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is **uki** - an iOS and watchOS companion chat application project built with SwiftUI. The project includes:
- iPhone app target (`uki/`)
- Apple Watch app target (`uki Watch App/`)
- Python backend for AI chat functionality (`avatar_chat.py`)

## Project Structure

### iOS/watchOS Apps (SwiftUI)
- `uki/` - iPhone app source code
  - `ukiApp.swift` - iOS app entry point
  - `ContentView.swift` - Main iOS view
  - `HomeView.swift` - Home page with navigation
  - `ChatView.swift` - Chat interface with streaming responses
  - `VoiceCallView.swift` - Full-screen voice call interface
  - `VoiceCallManager.swift` - Speech recognition and audio manager
  - `NetworkService.swift` - HTTP/SSE network layer
  - `SettingsView.swift` - Settings page
- `uki Watch App/` - Apple Watch app source code
  - `ukiApp.swift` - watchOS app entry point
  - `ContentView.swift` - Main watch view
  - `HomeView.swift` - Simplified home page
  - `ChatView.swift` - Small-screen optimized chat interface
  - `NetworkService.swift` - Network layer (same logic as iOS)

### Python Backend
- `server.py` - Flask API server (currently in use):
  - **MiniMax API** for TTS (Text-to-Speech) via WebSocket
  - **SiliconFlow API** for LLM chat (Qwen3-14B model)
  - Character: "uki" - a cool PhD-style digital companion
  - Supports streaming responses (SSE) with optional voice synthesis
  - Endpoints: `/chat` (SSE), `/tts` (MP3), `/health`
- `avatar_chat.py` - Original CLI chat program (kept for reference)

### Test Targets
- `ukiTests/` - iOS unit tests
- `ukiUITests/` - iOS UI tests
- `uki Watch AppTests/` - watchOS unit tests
- `uki Watch AppUITests/` - watchOS UI tests

## Development Commands

### Building & Running
```bash
# Open Xcode project
open uki.xcodeproj

# Build iOS app (command line)
xcodebuild -project uki.xcodeproj -scheme uki -sdk iphoneos

# Build watchOS app (command line)
xcodebuild -project uki.xcodeproj -scheme "uki Watch App" -sdk watchos

# Run tests
xcodebuild test -project uki.xcodeproj -scheme uki -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Python Backend
```bash
# Run Flask API server (port 8000)
python server.py

# Dependencies needed:
# - flask
# - flask-cors
# - websockets
# - requests
```

## Architecture Notes

### Multi-Platform Design
- **iOS and watchOS share similar app structure** but have separate targets
- Both use SwiftUI's declarative UI framework
- watchOS version is optimized for small screens with simplified UI
- Both platforms connect to the same Python backend via HTTP/SSE

### AI Chat Backend Architecture
- **Streaming chat**: Uses SiliconFlow API with Qwen3-14B LLM
- **Real-time TTS**: WebSocket connection to MiniMax speech-02-turbo
- **Sentence-based audio streaming**: Splits responses into sentences and converts to audio incrementally
- **Async audio playback**: Uses asyncio queue for continuous audio playback while generating

### Key Integration Points
The iOS/watchOS apps:
1. ✅ Integrate with Python backend via HTTP/SSE streaming
2. ✅ Request TTS audio via HTTP POST and play MP3 locally
3. ✅ Implement audio playback using AVAudioPlayer
4. 🔲 Sync conversation state between iPhone and Apple Watch (not yet implemented)

### API Configuration
- MiniMax API: TTS with voice "bingjiao_didi", emotion-based synthesis
- SiliconFlow API: Chat completions with streaming support (Qwen3-14B)
- **Note**: API keys are currently hardcoded in `server.py` (should be moved to secure storage)

## Current State

The project is actively developed:
- ✅ Xcode project created with iOS and watchOS targets
- ✅ Python Flask backend (server.py) with AI character personality working
- ✅ iOS app fully functional:
  - Multi-page navigation (Home, Chat, Voice Call, Settings)
  - Streaming chat with text and audio messages
  - Real-time voice call with speech recognition
  - Emoji system (random trigger every 10-15 messages)
- ✅ watchOS app fully functional:
  - Simplified home and chat interface
  - Small-screen optimized UI
  - Text and audio message support
- ✅ Swift apps connected to Python backend via HTTP/SSE
- 🔲 iPhone ↔ Watch conversation sync not yet implemented

## Next Steps for Development

To enhance the companion chat app:
1. ✅ ~~Implement SwiftUI navigation with multiple pages~~
2. ✅ ~~Create network layer in Swift to communicate with backend~~
3. ✅ ~~Add audio playback capabilities to Swift apps~~
4. ✅ ~~Design UI for chat interface with character personality~~
5. ✅ ~~Build watchOS version~~
6. 🔲 Implement Watch Connectivity framework for iPhone-Watch sync
7. 🔲 Add persistent storage for conversation history
8. 🔲 Deploy backend to cloud server
9. 🔲 Add 3D avatar or Live2D character animation
