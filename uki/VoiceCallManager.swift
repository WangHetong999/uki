//
//  VoiceCallManager.swift
//  uki
//
//  语音通话管理器 - 负责语音识别、音频处理、对话流程
//

import Foundation
import Speech
import AVFoundation
import Combine

// MARK: - 通话状态

enum CallState: Equatable {
    case idle              // 空闲
    case connecting        // 连接中
    case connected         // 已连接
    case listening         // 正在聆听用户
    case userSpeaking      // 用户正在说话
    case aiSpeaking        // AI 正在说话
    case error(String)     // 错误状态
    case ended             // 已结束

    // 手动实现 Equatable 协议
    static func == (lhs: CallState, rhs: CallState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.connecting, .connecting),
             (.connected, .connected),
             (.listening, .listening),
             (.userSpeaking, .userSpeaking),
             (.aiSpeaking, .aiSpeaking),
             (.ended, .ended):
            return true
        case (.error, .error):
            return true  // 只比较类型，不比较错误信息
        default:
            return false
        }
    }
}

// MARK: - 语音通话管理器

class VoiceCallManager: NSObject, ObservableObject {

    // MARK: - Published 状态

    @Published var callState: CallState = .idle
    @Published var recognizedText: String = ""
    @Published var audioLevel: Float = 0.0
    @Published var isMuted: Bool = false
    @Published var isSpeakerOn: Bool = false
    @Published var errorMessage: String?

    // MARK: - 语音识别

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    // MARK: - 音频引擎

    private let audioEngine = AVAudioEngine()
    private var audioPlayer: AVAudioPlayer?

    // MARK: - 网络服务

    private let networkService = NetworkService()

    // MARK: - 对话控制

    private var silenceTimer: Timer?
    private var lastSpeechTime: Date?
    private let silenceThreshold: TimeInterval = 1.5  // 1.5秒静默后发送
    private var isProcessingAI = false

    // MARK: - 初始化

    override init() {
        super.init()
        print("🎤 VoiceCallManager 初始化")
    }

    deinit {
        print("🎤 VoiceCallManager 释放")
        endCall()
    }

    // MARK: - 权限请求

    /// 请求麦克风和语音识别权限
    func requestPermissions() async -> Bool {
        // 1. 请求麦克风权限
        let micStatus = await requestMicrophonePermission()
        guard micStatus else {
            await MainActor.run {
                errorMessage = "需要麦克风权限才能进行语音通话"
                callState = .error("麦克风权限被拒绝")
            }
            return false
        }

        // 2. 请求语音识别权限
        let speechStatus = await requestSpeechRecognitionPermission()
        guard speechStatus else {
            await MainActor.run {
                errorMessage = "需要语音识别权限才能进行语音通话"
                callState = .error("语音识别权限被拒绝")
            }
            return false
        }

        print("✅ 权限请求成功")
        return true
    }

    private func requestMicrophonePermission() async -> Bool {
        let granted = await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
        print("🔐 麦克风权限: \(granted ? "✅ 已授予" : "❌ 被拒绝")")
        return granted
    }

    private func requestSpeechRecognitionPermission() async -> Bool {
        let status = await withCheckedContinuation { (continuation: CheckedContinuation<SFSpeechRecognizerAuthorizationStatus, Never>) in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        let granted = (status == .authorized)
        print("🔐 语音识别权限: \(status.rawValue) - \(granted ? "✅ 已授予" : "❌ 被拒绝")")
        return granted
    }

    // MARK: - 通话控制

    /// 开始通话
    func startCall() async {
        print("📞 开始通话")

        await MainActor.run {
            callState = .connecting
        }

        // 请求权限
        let hasPermissions = await requestPermissions()
        guard hasPermissions else {
            return
        }

        // 配置音频会话
        do {
            try configureAudioSession()
        } catch {
            await MainActor.run {
                errorMessage = "音频配置失败: \(error.localizedDescription)"
                callState = .error("音频配置失败")
            }
            return
        }

        // 启动语音识别
        do {
            try startSpeechRecognition()
            await MainActor.run {
                callState = .connected
                callState = .listening
            }
            print("✅ 通话已建立，开始监听")
        } catch {
            await MainActor.run {
                errorMessage = "语音识别启动失败: \(error.localizedDescription)"
                callState = .error("语音识别失败")
            }
        }
    }

    /// 结束通话
    func endCall() {
        print("📞 开始结束通话...")

        // 在后台线程执行清理，避免阻塞主线程
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            self.stopSpeechRecognition()
            self.stopAudioEngine()

            DispatchQueue.main.async {
                self.silenceTimer?.invalidate()
                self.silenceTimer = nil
                self.callState = .ended
                print("✅ 通话已结束")
            }
        }
    }

    // MARK: - 音频会话配置

    private func configureAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetooth])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        print("✅ 音频会话配置完成")
    }

    // MARK: - 语音识别

    private func startSpeechRecognition() throws {
        // 如果之前有任务在运行，先停止
        stopSpeechRecognition()

        // 创建识别请求
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw NSError(domain: "VoiceCallManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法创建识别请求"])
        }

        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = false

        // 获取音频输入节点
        let inputNode = audioEngine.inputNode

        // 启动识别任务
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                let transcription = result.bestTranscription.formattedString

                DispatchQueue.main.async {
                    self.recognizedText = transcription
                    self.lastSpeechTime = Date()

                    // 用户正在说话
                    if self.callState == .listening {
                        self.callState = .userSpeaking
                    }
                }

                // 重置静默计时器
                self.resetSilenceTimer()

                print("🎤 识别文字: \(transcription)")
            }

            if let error = error {
                print("❌ 识别错误: \(error.localizedDescription)")
            }
        }

        // 配置音频格式
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)

            // 计算音频电平（用于波形显示）
            self?.calculateAudioLevel(from: buffer)
        }

        // 启动音频引擎
        print("🎧 准备启动音频引擎...")
        audioEngine.prepare()
        try audioEngine.start()
        print("🎧 音频引擎已启动，运行中: \(audioEngine.isRunning)")

        print("✅ 语音识别已启动，识别器可用: \(speechRecognizer != nil)")
    }

    private func stopSpeechRecognition() {
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest?.endAudio()
        recognitionRequest = nil

        print("⏹️ 语音识别已停止")
    }

    private func stopAudioEngine() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
            print("⏹️ 音频引擎已停止")
        }
    }

    // MARK: - 静默检测

    private func resetSilenceTimer() {
        silenceTimer?.invalidate()

        silenceTimer = Timer.scheduledTimer(withTimeInterval: silenceThreshold, repeats: false) { [weak self] _ in
            self?.onSilenceDetected()
        }
    }

    private func onSilenceDetected() {
        guard !recognizedText.isEmpty, !isProcessingAI else { return }

        print("🔕 检测到静默，发送文字到 AI: \(recognizedText)")

        let textToSend = recognizedText
        recognizedText = ""  // 清空

        // 发送到 AI
        Task {
            await sendToAI(textToSend)
        }
    }

    // MARK: - AI 对话

    private func sendToAI(_ text: String) async {
        guard !isProcessingAI else {
            print("⚠️ AI 正在处理中，跳过")
            return
        }

        isProcessingAI = true

        await MainActor.run {
            callState = .aiSpeaking
        }

        // 暂停语音识别
        stopSpeechRecognition()

        do {
            // 调用 AI 接口（流式）
            let aiReply = try await networkService.sendMessageStream(text, history: []) { chunk in
                print("💬 AI 回复: \(chunk)", terminator: "")
            }

            print("\n✅ AI 完整回复: \(aiReply)")

            // 转换为语音并播放
            try await playAIVoice(aiReply)

            // 播放完成，恢复监听
            await MainActor.run {
                callState = .listening
            }

            // 重新启动语音识别
            try startSpeechRecognition()

        } catch {
            print("❌ AI 对话失败: \(error.localizedDescription)")

            await MainActor.run {
                errorMessage = "AI 回复失败"
                callState = .listening
            }

            // 恢复语音识别
            try? startSpeechRecognition()
        }

        isProcessingAI = false
    }

    private func playAIVoice(_ text: String) async throws {
        print("🔊 开始播放 AI 语音")

        // 调用 TTS 接口
        try await networkService.textToSpeech(text)

        print("✅ AI 语音播放完成")
    }

    // MARK: - 音频电平计算

    private func calculateAudioLevel(from buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }

        let channelDataValue = channelData.pointee
        let channelDataValueArray = stride(from: 0, to: Int(buffer.frameLength), by: buffer.stride).map { channelDataValue[$0] }

        let rms = sqrt(channelDataValueArray.map { $0 * $0 }.reduce(0, +) / Float(buffer.frameLength))
        let avgPower = 20 * log10(rms)
        let normalizedLevel = max(0, min(1, (avgPower + 50) / 50))

        DispatchQueue.main.async {
            self.audioLevel = normalizedLevel
        }
    }

    // MARK: - 静音/免提控制

    func toggleMute() {
        isMuted.toggle()

        if isMuted {
            // 静音：停止语音识别
            stopSpeechRecognition()
            print("🔇 已静音")
        } else {
            // 取消静音：恢复语音识别
            try? startSpeechRecognition()
            print("🔊 已取消静音")
        }
    }

    func toggleSpeaker() {
        isSpeakerOn.toggle()

        do {
            let audioSession = AVAudioSession.sharedInstance()
            if isSpeakerOn {
                try audioSession.overrideOutputAudioPort(.speaker)
                print("📢 已切换到扬声器")
            } else {
                try audioSession.overrideOutputAudioPort(.none)
                print("🎧 已切换到听筒")
            }
        } catch {
            print("❌ 切换音频输出失败: \(error.localizedDescription)")
        }
    }
}
