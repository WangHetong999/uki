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
- `uki Watch App/` - Apple Watch app source code
  - `ukiApp.swift` - watchOS app entry point
  - `ContentView.swift` - Main watch view

### Python Backend
- `avatar_chat.py` - AI chat backend using:
  - **MiniMax API** for TTS (Text-to-Speech) via WebSocket
  - **SiliconFlow API** for LLM chat (Qwen3-14B model)
  - Character: "嘎巴龙" (Gabaron) - a playful digital dragon from Gabaron planet
  - Supports streaming responses with real-time voice synthesis

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
# Run chat backend (requires Python dependencies)
python avatar_chat.py

# Dependencies needed:
# - websockets
# - requests
# - pydub
```

## Architecture Notes

### Multi-Platform Design
- **iOS and watchOS share similar app structure** but have separate targets
- Both use SwiftUI's declarative UI framework
- Currently both apps show basic "Hello, world!" content

### AI Chat Backend Architecture
- **Streaming chat**: Uses SiliconFlow API with Qwen3-14B LLM
- **Real-time TTS**: WebSocket connection to MiniMax speech-02-turbo
- **Sentence-based audio streaming**: Splits responses into sentences and converts to audio incrementally
- **Async audio playback**: Uses asyncio queue for continuous audio playback while generating

### Key Integration Points
The iOS/watchOS apps will need to:
1. Integrate with the Python backend's chat API
2. Handle WebSocket connections for real-time TTS
3. Implement audio playback on device
4. Sync conversation state between iPhone and Apple Watch

### API Configuration
- MiniMax API: TTS with voice "bingjiao_didi", emotion-based synthesis
- SiliconFlow API: Chat completions with streaming support
- **Note**: API keys are currently hardcoded in `avatar_chat.py` (should be moved to secure storage)

## Current State

The project is in early stage:
- ✅ Xcode project created with iOS and watchOS targets
- ✅ Python chat backend with AI character personality working
- ⚠️ iOS/watchOS apps are using default templates
- 🔲 No connection between Swift apps and Python backend yet
- 🔲 Multi-page navigation not yet implemented

## Next Steps for Development

To turn this into a functional companion chat app:
1. Implement SwiftUI navigation with multiple pages (Home, Chat, Settings)
2. Create network layer in Swift to communicate with backend
3. Decide on backend deployment: REST API, WebSocket, or cloud functions
4. Implement Watch Connectivity framework for iPhone-Watch sync
5. Add audio playback capabilities to Swift apps
6. Design UI for chat interface with character personality
