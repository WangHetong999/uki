//
//  NetworkService.swift
//  uki Watch App
//
//  网络服务层 - 与 Python API 服务器通信
//

import Foundation
import AVFoundation

// MARK: - 数据模型

struct ChatRequest: Codable {
    let message: String
    let history: [ChatMessage]
    let emoji_hint: Bool?  // 是否提示 AI 可以发表情包（Watch 端不使用）
}

struct ChatMessage: Codable {
    let role: String  // "user" 或 "assistant"
    let content: String
}

struct ChatResponse: Codable {
    let reply: String
    let success: Bool
}

struct TTSRequest: Codable {
    let text: String
}

struct StreamChunk: Codable {
    let chunk: String
    let done: Bool
    let full_text: String?
}

// MARK: - 网络服务

class NetworkService: ObservableObject {
    // 🔧 配置说明：
    // Apple Watch 通过 iPhone 的网络连接，所以使用与 iPhone 相同的配置
    // 但由于 Watch 是独立 App，需要配置真实 IP
    //
    // ⚠️ 注意：
    // 1. 如果 Watch 是配对模式，需要使用电脑 IP
    // 2. 确保电脑和 iPhone 在同一 Wi-Fi 下

    #if targetEnvironment(simulator)
    // 模拟器使用 localhost
    static let baseURL = "http://localhost:8000"
    #else
    // 真机使用电脑 IP（需要与 iPhone 一致）
    static let baseURL = "http://172.20.10.2:8000"
    #endif

    private var audioPlayer: AVAudioPlayer?

    // MARK: - 聊天接口

    /// 发送消息给 AI，流式获取回复
    /// - Parameters:
    ///   - message: 用户消息
    ///   - history: 历史对话
    ///   - onChunk: 每收到一个文字块时的回调
    /// - Returns: 完整回复文字
    func sendMessageStream(_ message: String, history: [ChatMessage] = [], onChunk: @escaping (String) -> Void) async throws -> String {
        guard let url = URL(string: "\(NetworkService.baseURL)/chat") else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Watch 端不使用表情包功能
        let requestBody = ChatRequest(message: message, history: history, emoji_hint: false)
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.serverError
        }

        var fullText = ""

        // 逐行读取 SSE 数据
        for try await line in asyncBytes.lines {
            if line.hasPrefix("data: ") {
                let jsonString = String(line.dropFirst(6))  // 去掉 "data: "

                if let jsonData = jsonString.data(using: .utf8),
                   let json = try? JSONDecoder().decode(StreamChunk.self, from: jsonData) {

                    if json.done {
                        // 完成
                        fullText = json.full_text ?? fullText
                        break
                    } else {
                        // 收到文字块
                        let chunk = json.chunk
                        fullText += chunk
                        await MainActor.run {
                            onChunk(chunk)
                        }
                    }
                }
            }
        }

        return fullText
    }

    /// 发送消息给 AI，获取完整回复（非流式，兼容旧代码）
    /// - Parameters:
    ///   - message: 用户消息
    ///   - history: 历史对话
    /// - Returns: AI 回复文字
    func sendMessage(_ message: String, history: [ChatMessage] = []) async throws -> String {
        return try await sendMessageStream(message, history: history) { _ in }
    }

    // MARK: - 语音接口

    /// 将文字转换为语音并播放
    /// - Parameter text: 要转换的文字
    func textToSpeech(_ text: String) async throws {
        guard let url = URL(string: "\(NetworkService.baseURL)/tts") else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody = TTSRequest(text: text)
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.serverError
        }

        // 播放音频
        try await playAudio(data: data)
    }

    /// 将文字转换为语音并保存到本地文件
    /// - Parameter text: 要转换的文字
    /// - Returns: 保存的音频文件 URL
    func textToSpeechAndSave(_ text: String) async throws -> URL {
        guard let url = URL(string: "\(NetworkService.baseURL)/tts") else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody = TTSRequest(text: text)
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.serverError
        }

        // 保存到临时目录
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "audio_\(UUID().uuidString).mp3"
        let fileURL = tempDir.appendingPathComponent(fileName)

        try data.write(to: fileURL)

        return fileURL
    }

    /// 从 URL 播放音频文件
    /// - Parameter url: 音频文件 URL
    func playAudio(from url: URL) async throws {
        do {
            let data = try Data(contentsOf: url)
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.prepareToPlay()

            // 在主线程播放
            await MainActor.run {
                audioPlayer?.play()
            }

            // 等待播放完成
            if let duration = audioPlayer?.duration {
                try await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            }
        } catch {
            throw NetworkError.audioPlaybackError
        }
    }

    /// 播放音频数据
    private func playAudio(data: Data) async throws {
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            throw NetworkError.audioPlaybackError
        }
    }

    // MARK: - 健康检查

    /// 检查服务器是否运行
    func checkHealth() async -> Bool {
        guard let url = URL(string: "\(NetworkService.baseURL)/health") else {
            return false
        }

        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }
        } catch {
            print("健康检查失败: \(error)")
        }

        return false
    }
}

// MARK: - 错误类型

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case serverError
    case audioPlaybackError
    case decodingError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的 URL"
        case .serverError:
            return "服务器错误"
        case .audioPlaybackError:
            return "音频播放失败"
        case .decodingError:
            return "数据解析失败"
        }
    }
}
