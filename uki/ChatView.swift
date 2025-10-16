//
//  ChatView.swift
//  uki
//
//  聊天页面 - 与嘎巴龙对话
//

import SwiftUI

// 消息类型枚举
enum MessageType {
    case text           // 纯文本消息
    case audio          // 纯语音消息（不显示文字，只显示语音气泡）
    case emoji          // 表情包消息
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
    var emojiId: String?   // 表情包ID（如果是表情包消息）
}

struct ChatView: View {
    @StateObject private var networkService = NetworkService()
    @State private var messageText = ""
    @State private var messages: [Message] = []
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""

    // 表情包相关
    @State private var messageCounter = 0  // 消息计数器
    @State private var emojiTriggerCount = Int.random(in: 10...15)  // 随机触发阈值

    var body: some View {
        VStack(spacing: 0) {
            // 聊天消息列表
            ScrollView {
                VStack(spacing: 16) {
                    // 今天的日期
                    Text("今天 10:30")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, 8)

                    // 消息列表
                    ForEach(messages) { message in
                        MessageBubble(message: message)
                    }

                    // 加载指示器
                    if isLoading {
                        HStack {
                            ProgressView()
                                .padding()
                            Text("思考中...")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                    }
                }
                .padding()
            }

            // 输入框
            HStack(spacing: 12) {
                // 表情按钮
                Button(action: {}) {
                    Image(systemName: "face.smiling")
                        .foregroundColor(.orange)
                        .font(.system(size: 24))
                }

                // 文本输入框
                TextField("输入消息...", text: $messageText)
                    .padding(10)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(20)

                // 发送按钮
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.gray)
                        .clipShape(Circle())
                }
            }
            .padding()
            .background(Color.white)
        }
        .navigationTitle("嘎巴龙")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // 语音通话按钮
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: VoiceCallView()) {
                    Image(systemName: "phone.fill")
                        .foregroundColor(.purple)
                }
            }

            // 服务器状态检查按钮
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: checkServerStatus) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                }
            }
        }
        .alert("错误", isPresented: $showError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .task {
            // 页面加载时添加欢迎消息
            if messages.isEmpty {
                let welcomeMessage = Message(
                    text: "嘿，我是uki！我是你的专属臭宝～今天想聊点什么呢？",
                    isUser: false,
                    timestamp: Date(),
                    type: .text
                )
                messages.append(welcomeMessage)
            }
        }
    }

    func checkServerStatus() {
        Task {
            let isHealthy = await networkService.checkHealth()
            await MainActor.run {
                if isHealthy {
                    errorMessage = "✅ 服务器连接正常"
                } else {
                    errorMessage = "❌ 无法连接服务器，请确保 server.py 正在运行"
                }
                showError = true
            }
        }
    }

    func sendMessage() {
        guard !messageText.isEmpty, !isLoading else { return }

        let userText = messageText
        messageText = ""

        // 消息计数器 +1
        messageCounter += 1

        // 检查是否该触发表情包
        let shouldSendEmoji = (messageCounter >= emojiTriggerCount)
        if shouldSendEmoji {
            // 重置计数器和触发阈值
            messageCounter = 0
            emojiTriggerCount = Int.random(in: 10...15)
        }

        // 90% 概率文本，10% 概率语音
        let randomValue = Double.random(in: 0...1)
        let messageType: MessageType = randomValue < 0.9 ? .text : .audio

        // 添加用户消息（用户消息总是文本）
        let newMessage = Message(
            text: userText,
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
            type: messageType  // 根据随机结果决定类型
        )
        messages.append(aiMessage)
        let aiMessageIndex = messages.count - 1

        // 开始加载
        isLoading = true

        // 发送到服务器（流式接收）
        Task {
            do {
                // 构建历史对话（去掉最后两条：用户消息和空的AI消息）
                let history = messages.dropLast(2).suffix(10).map { msg in
                    ChatMessage(
                        role: msg.isUser ? "user" : "assistant",
                        content: msg.text
                    )
                }

                // 流式获取 AI 回复（传递表情包提示）
                let fullReply = try await networkService.sendMessageStream(userText, history: Array(history), emojiHint: shouldSendEmoji) { chunk in
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

                // 解析表情包标记 [emoji:xxx]
                var cleanedReply = fullReply
                var emojiId: String?

                print("📦 收到完整回复: \(fullReply)")

                if let emojiRange = fullReply.range(of: #"\[emoji:(\w+)\]"#, options: .regularExpression) {
                    // 提取表情包 ID
                    let emojiTag = String(fullReply[emojiRange])
                    print("🎯 找到表情包标记: \(emojiTag)")

                    if let idRange = emojiTag.range(of: #"emoji:(\w+)"#, options: .regularExpression) {
                        let match = String(emojiTag[idRange])
                        let rawId = match.replacingOccurrences(of: "emoji:", with: "")
                        // 加上 emoji_ 前缀以匹配 Assets 中的图片名称
                        emojiId = "emoji_" + rawId
                        print("✅ 解析出表情包 ID: \(emojiId ?? "nil")")
                    }
                    // 移除表情包标记
                    cleanedReply = fullReply.replacingOccurrences(of: emojiTag, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                } else {
                    print("❌ 没有找到表情包标记")
                }

                // 更新 AI 消息（使用清理后的文字）
                await MainActor.run {
                    if aiMessageIndex < messages.count {
                        messages[aiMessageIndex] = Message(
                            text: cleanedReply,
                            isUser: false,
                            timestamp: messages[aiMessageIndex].timestamp,
                            type: messageType
                        )
                    }
                }

                // 如果是语音消息，获取语音并保存
                if messageType == .audio {
                    // 获取语音并保存到本地（30% 的情况才会调用 TTS）
                    let audioURL = try await networkService.textToSpeechAndSave(cleanedReply)

                    // 更新消息，添加音频URL（不显示文字）
                    await MainActor.run {
                        if aiMessageIndex < messages.count {
                            messages[aiMessageIndex] = Message(
                                text: cleanedReply,  // 保存文本但不显示
                                isUser: false,
                                timestamp: messages[aiMessageIndex].timestamp,
                                type: .audio,
                                audioURL: audioURL,
                                audioDuration: 5.0  // 暂时固定为5秒，后面可以计算实际时长
                            )
                        }
                        isLoading = false
                    }

                    // 自动播放语音
                    try await networkService.playAudio(from: audioURL)
                } else {
                    // 文本消息：只显示文字，不调用 TTS（70% 的情况，节省成本）
                    await MainActor.run {
                        isLoading = false
                    }
                    // ⚠️ 注意：这里不调用 textToSpeech，节省成本！
                }

                // 如果有表情包，添加表情包消息
                if let emojiId = emojiId {
                    print("🎨 准备添加表情包消息，ID: \(emojiId)")
                    await MainActor.run {
                        let emojiMessage = Message(
                            text: "",
                            isUser: false,
                            timestamp: Date(),
                            type: .emoji,
                            emojiId: emojiId
                        )
                        messages.append(emojiMessage)
                        print("✅ 表情包消息已添加到列表，当前消息总数: \(messages.count)")
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

// 消息气泡组件
struct MessageBubble: View {
    let message: Message
    @State private var isPlaying = false

    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }

            HStack(alignment: .bottom, spacing: 8) {
                if !message.isUser {
                    // AI 头像
                    Circle()
                        .fill(Color.purple.opacity(0.3))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Text("🐲")
                                .font(.system(size: 20))
                        )
                }

                VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                    // 根据消息类型显示不同内容
                    if message.type == .emoji {
                        // 表情包消息
                        if let emojiId = message.emojiId {
                            Image(emojiId)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 150, height: 150)
                                .cornerRadius(8)
                                .onAppear {
                                    print("🖼️ 正在渲染表情包: \(emojiId)")
                                }
                        } else {
                            Text("❌ 表情包 ID 为空")
                                .foregroundColor(.red)
                        }
                    } else if message.type == .audio {
                        // 语音消息气泡
                        AudioMessageBubble(
                            message: message,
                            isPlaying: $isPlaying
                        )
                    } else {
                        // 文本消息
                        Text(message.text)
                            .padding(12)
                            .background(message.isUser ? Color.purple : Color.gray.opacity(0.2))
                            .foregroundColor(message.isUser ? .white : .black)
                            .cornerRadius(16)
                    }

                    // 时间戳
                    Text(timeString(from: message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.gray)
                }

                if message.isUser {
                    // 用户头像
                    Circle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.blue)
                        )
                }
            }

            if !message.isUser {
                Spacer()
            }
        }
    }

    func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// 语音消息气泡组件
struct AudioMessageBubble: View {
    let message: Message
    @Binding var isPlaying: Bool
    @StateObject private var networkService = NetworkService()

    var body: some View {
        HStack(spacing: 12) {
            // 播放按钮
            Button(action: playAudio) {
                Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.purple)
            }

            VStack(alignment: .leading, spacing: 4) {
                // 音频波形（模拟效果）
                HStack(spacing: 2) {
                    ForEach(0..<20) { i in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.purple.opacity(0.6))
                            .frame(width: 3, height: CGFloat.random(in: 8...24))
                    }
                }

                // 时长
                if let duration = message.audioDuration {
                    Text(String(format: "%.0f\"", duration))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
        .frame(minWidth: 200, alignment: .leading)
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

#Preview {
    NavigationView {
        ChatView()
    }
}
