//
//  ChatView.swift
//  uki Watch App
//
//  聊天页面 - 与 uki 对话（watchOS 适配版）
//

import SwiftUI

// 消息类型枚举
enum MessageType {
    case text           // 纯文本消息
    case audio          // 纯语音消息（不显示文字，只显示语音气泡）
}

// 消息模型
struct Message: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool  // true = 用户消息, false = AI消息
    let timestamp: Date
    let type: MessageType  // 消息类型
    var audioURL: URL?     // 语音文件URL（如果是语音消息）
    var audioDuration: TimeInterval?  // 语音时长
}

struct ChatView: View {
    @StateObject private var networkService = NetworkService()
    @State private var messageText = ""
    @State private var messages: [Message] = []
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showingTextInput = false

    var body: some View {
        VStack(spacing: 0) {
            // 聊天消息列表
            ScrollView {
                VStack(spacing: 8) {
                    // 消息列表
                    ForEach(messages) { message in
                        MessageBubble(message: message)
                    }

                    // 加载指示器
                    if isLoading {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("思考中...")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }

            // 输入框（watchOS 使用系统输入）
            HStack(spacing: 4) {
                // 文本输入按钮
                Button(action: showTextInput) {
                    Image(systemName: "message")
                        .font(.system(size: 16))
                }
                .buttonStyle(.bordered)
                .tint(.purple)

                // 语音输入按钮
                Button(action: showVoiceInput) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 16))
                }
                .buttonStyle(.bordered)
                .tint(.orange)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .navigationTitle("uki")
        .navigationBarTitleDisplayMode(.inline)
        .alert("错误", isPresented: $showError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showingTextInput) {
            // watchOS 文本输入界面
            TextInputView { text in
                if !text.isEmpty {
                    sendMessage(text)
                }
            }
        }
        .task {
            // 页面加载时添加欢迎消息
            if messages.isEmpty {
                let welcomeMessage = Message(
                    text: "嘿，我是uki！",
                    isUser: false,
                    timestamp: Date(),
                    type: .text
                )
                messages.append(welcomeMessage)
            }
        }
    }

    // 显示文本输入界面
    func showTextInput() {
        showingTextInput = true
    }

    // 显示语音输入界面
    func showVoiceInput() {
        // 使用系统语音输入
        showingTextInput = true
    }

    func sendMessage(_ text: String) {
        guard !text.isEmpty, !isLoading else { return }

        // 50% 概率文本，50% 概率语音（Watch 端语音占比更高）
        let randomValue = Double.random(in: 0...1)
        let messageType: MessageType = randomValue < 0.5 ? .text : .audio

        // 添加用户消息（用户消息总是文本）
        let newMessage = Message(
            text: text,
            isUser: true,
            timestamp: Date(),
            type: .text
        )
        messages.append(newMessage)

        // 创建一个空的 AI 消息，用于流式更新
        let aiMessage = Message(
            text: "",
            isUser: false,
            timestamp: Date(),
            type: messageType
        )
        messages.append(aiMessage)
        let aiMessageIndex = messages.count - 1

        // 开始加载
        isLoading = true

        // 发送到服务器（流式接收）
        Task {
            do {
                // 构建历史对话（去掉最后两条：用户消息和空的AI消息）
                let history = messages.dropLast(2).suffix(8).map { msg in
                    ChatMessage(
                        role: msg.isUser ? "user" : "assistant",
                        content: msg.text
                    )
                }

                // 流式获取 AI 回复
                let fullReply = try await networkService.sendMessageStream(text, history: Array(history)) { chunk in
                    // 每收到一个字符，更新消息
                    if aiMessageIndex < messages.count {
                        messages[aiMessageIndex] = Message(
                            text: messages[aiMessageIndex].text + chunk,
                            isUser: false,
                            timestamp: messages[aiMessageIndex].timestamp,
                            type: messageType
                        )
                    }
                }

                // 更新 AI 消息
                await MainActor.run {
                    if aiMessageIndex < messages.count {
                        messages[aiMessageIndex] = Message(
                            text: fullReply,
                            isUser: false,
                            timestamp: messages[aiMessageIndex].timestamp,
                            type: messageType
                        )
                    }
                }

                // 如果是语音消息，获取语音并保存
                if messageType == .audio {
                    // 获取语音并保存到本地
                    let audioURL = try await networkService.textToSpeechAndSave(fullReply)

                    // 更新消息，添加音频URL（不显示文字）
                    await MainActor.run {
                        if aiMessageIndex < messages.count {
                            messages[aiMessageIndex] = Message(
                                text: fullReply,  // 保存文本但不显示
                                isUser: false,
                                timestamp: messages[aiMessageIndex].timestamp,
                                type: .audio,
                                audioURL: audioURL,
                                audioDuration: 5.0  // 暂时固定为5秒
                            )
                        }
                        isLoading = false
                    }

                    // 自动播放语音
                    try await networkService.playAudio(from: audioURL)
                } else {
                    // 文本消息：只显示文字
                    await MainActor.run {
                        isLoading = false
                    }
                }

            } catch {
                await MainActor.run {
                    errorMessage = "发送失败: \(error.localizedDescription)"
                    showError = true
                    isLoading = false

                    // 移除空的 AI 消息
                    if aiMessageIndex < messages.count && messages[aiMessageIndex].text.isEmpty {
                        messages.remove(at: aiMessageIndex)
                    }
                }
            }
        }
    }
}

// 消息气泡组件（watchOS 精简版）
struct MessageBubble: View {
    let message: Message
    @State private var isPlaying = false

    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            if message.isUser {
                Spacer(minLength: 20)
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 2) {
                // 根据消息类型显示不同内容
                if message.type == .audio {
                    // 语音消息气泡
                    AudioMessageBubble(
                        message: message,
                        isPlaying: $isPlaying
                    )
                } else {
                    // 文本消息
                    Text(message.text)
                        .font(.system(size: 14))
                        .padding(8)
                        .background(message.isUser ? Color.purple : Color.gray.opacity(0.3))
                        .foregroundColor(message.isUser ? .white : .primary)
                        .cornerRadius(12)
                }

                // 时间戳
                Text(timeString(from: message.timestamp))
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            }

            if !message.isUser {
                Spacer(minLength: 20)
            }
        }
    }

    func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// 语音消息气泡组件（watchOS 精简版）
struct AudioMessageBubble: View {
    let message: Message
    @Binding var isPlaying: Bool
    @StateObject private var networkService = NetworkService()

    var body: some View {
        HStack(spacing: 6) {
            // 播放按钮
            Button(action: playAudio) {
                Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.purple)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                // 音频波形（模拟效果）
                HStack(spacing: 1) {
                    ForEach(0..<10) { i in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.purple.opacity(0.6))
                            .frame(width: 2, height: CGFloat.random(in: 6...16))
                    }
                }

                // 时长
                if let duration = message.audioDuration {
                    Text(String(format: "%.0f\"", duration))
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(6)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
    }

    func playAudio() {
        guard let audioURL = message.audioURL else {
            print("没有语音文件")
            return
        }

        isPlaying = true

        Task {
            do {
                try await networkService.playAudio(from: audioURL)
                await MainActor.run {
                    isPlaying = false
                }
            } catch {
                print("播放失败: \(error)")
                await MainActor.run {
                    isPlaying = false
                }
            }
        }
    }
}

// MARK: - 文本输入视图（watchOS 专用）

struct TextInputView: View {
    @Environment(\.dismiss) var dismiss
    @State private var inputText = ""
    let onSubmit: (String) -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("输入消息")
                .font(.headline)

            TextField("说点什么...", text: $inputText)

            HStack(spacing: 12) {
                Button("取消") {
                    dismiss()
                }
                .buttonStyle(.bordered)

                Button("发送") {
                    onSubmit(inputText)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(inputText.isEmpty)
            }
        }
        .padding()
    }
}

#Preview {
    NavigationStack {
        ChatView()
    }
}
