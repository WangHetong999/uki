//
//  VoiceCallView.swift
//  uki
//
//  语音通话界面 - 全屏沉浸式实时语音交互
//

import SwiftUI

struct VoiceCallView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var callManager = VoiceCallManager()

    // 通话状态
    @State private var callDuration: TimeInterval = 0
    @State private var timer: Timer?
    @State private var showEndCallAlert = false

    var body: some View {
        ZStack {
            // 渐变背景
            LinearGradient(
                colors: [
                    Color.purple.opacity(0.6),
                    Color.purple.opacity(0.4),
                    Color.blue.opacity(0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // 顶部导航栏
                topNavigationBar

                Spacer()

                // 数字人展示区
                avatarSection

                Spacer()

                // 语音波形区域
                waveformSection

                Spacer()

                // 底部操作按钮
                controlButtons
                    .padding(.bottom, 50)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            startCall()
        }
        .onDisappear {
            endCall()
        }
        .alert("确认挂断通话吗？", isPresented: $showEndCallAlert) {
            Button("继续通话", role: .cancel) {}
            Button("挂断", role: .destructive) {
                endCall()
                dismiss()
            }
        }
        .alert("错误", isPresented: .constant(callManager.errorMessage != nil)) {
            Button("确定") {
                callManager.errorMessage = nil
            }
        } message: {
            Text(callManager.errorMessage ?? "")
        }
    }

    // MARK: - 顶部导航栏

    var topNavigationBar: some View {
        HStack {
            // 返回按钮（显示确认弹窗）
            Button(action: {
                showEndCallAlert = true
            }) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.3))
                    .clipShape(Circle())
                    .background(.ultraThinMaterial, in: Circle())
            }

            Spacer()

            Text("语音通话")
                .font(.system(size: 17))
                .foregroundColor(.white)

            Spacer()

            // 占位，保持标题居中
            Color.clear
                .frame(width: 40, height: 40)
        }
        .padding(.horizontal, 20)
        .padding(.top, 50)
    }

    // MARK: - 数字人展示区

    var avatarSection: some View {
        VStack(spacing: 16) {
            // 头像（带呼吸动画）
            AvatarWithBreathingAnimation()

            // 数字人名称
            Text("小艾")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)

            // 通话状态
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .fill(Color.green.opacity(0.5))
                            .scaleEffect(1.5)
                    )

                Text("通话中")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.9))
            }

            // 通话时长
            Text(formatDuration(callDuration))
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
        }
    }

    // MARK: - 语音波形区域

    var waveformSection: some View {
        VStack(spacing: 12) {
            // 波形可视化
            WaveformVisualization()

            // 状态提示（根据 callManager 状态动态显示）
            Text(statusText)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))

            // 调试信息：显示识别的文字
            if !callManager.recognizedText.isEmpty {
                Text("识别中: \(callManager.recognizedText)")
                    .font(.system(size: 12))
                    .foregroundColor(.yellow)
                    .padding(.top, 4)
            }

            // 调试信息：音频电平
            HStack {
                Text("音频电平:")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))

                ProgressView(value: Double(callManager.audioLevel), total: 1.0)
                    .progressViewStyle(.linear)
                    .frame(width: 100)
                    .tint(.green)

                Text(String(format: "%.2f", callManager.audioLevel))
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(Color.white.opacity(0.2))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 32))
        )
        .padding(.horizontal, 40)
    }

    // MARK: - 底部控制按钮

    var controlButtons: some View {
        HStack(spacing: 48) {
            // 静音按钮
            ControlButton(
                icon: callManager.isMuted ? "mic.slash.fill" : "mic.fill",
                label: "静音",
                size: 64,
                backgroundColor: Color.white.opacity(0.3),
                action: {
                    callManager.toggleMute()
                }
            )

            // 挂断按钮（更大）
            ControlButton(
                icon: "phone.down.fill",
                label: "挂断",
                size: 80,
                backgroundColor: Color.red.opacity(0.95),
                action: {
                    endCall()
                    dismiss()
                }
            )

            // 免提按钮
            ControlButton(
                icon: callManager.isSpeakerOn ? "speaker.wave.3.fill" : "speaker.fill",
                label: "免提",
                size: 64,
                backgroundColor: Color.white.opacity(0.3),
                action: {
                    callManager.toggleSpeaker()
                }
            )
        }
    }

    // MARK: - 通话控制

    func startCall() {
        // 启动计时器
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            callDuration += 1
        }

        // 启动语音通话管理器
        Task {
            await callManager.startCall()
        }

        print("📞 语音通话已开始")
    }

    func endCall() {
        timer?.invalidate()
        timer = nil

        callManager.endCall()

        print("📞 语音通话已结束，时长: \(formatDuration(callDuration))")
    }

    func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    // 根据 CallState 返回状态文字
    var statusText: String {
        switch callManager.callState {
        case .connecting:
            return "正在连接..."
        case .listening, .connected:
            return "正在聆听..."
        case .userSpeaking:
            return "正在聆听..."
        case .aiSpeaking:
            return "数字人正在说话..."
        case .error(let message):
            return "错误: \(message)"
        case .ended:
            return "通话已结束"
        case .idle:
            return "准备中..."
        }
    }
}

// MARK: - 头像呼吸动画组件

struct AvatarWithBreathingAnimation: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // 外圈（延迟动画）
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 2)
                .frame(width: 132, height: 132)
                .scaleEffect(isAnimating ? 1.2 : 1.0)
                .opacity(isAnimating ? 0 : 1)
                .animation(
                    Animation.easeInOut(duration: 2.0)
                        .repeatForever(autoreverses: false)
                        .delay(0.5),
                    value: isAnimating
                )

            // 内圈
            Circle()
                .stroke(Color.white.opacity(0.4), lineWidth: 4)
                .frame(width: 132, height: 132)
                .scaleEffect(isAnimating ? 1.15 : 1.0)
                .opacity(isAnimating ? 0 : 1)
                .animation(
                    Animation.easeInOut(duration: 2.0)
                        .repeatForever(autoreverses: false),
                    value: isAnimating
                )

            // 头像
            Circle()
                .fill(Color.white)
                .frame(width: 132, height: 132)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                .overlay(
                    Text("🧒")
                        .font(.system(size: 60))
                )
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - 波形可视化组件

struct WaveformVisualization: View {
    @State private var waveHeights: [CGFloat] = Array(repeating: 20, count: 20)
    @State private var timer: Timer?

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<20, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(Double.random(in: 0.6...1.0)))
                    .frame(width: 4, height: waveHeights[index])
                    .animation(
                        Animation.easeInOut(duration: 0.3)
                            .delay(Double(index) * 0.05),
                        value: waveHeights[index]
                    )
            }
        }
        .frame(height: 60)
        .onAppear {
            startWaveAnimation()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    func startWaveAnimation() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            waveHeights = waveHeights.map { _ in CGFloat.random(in: 20...60) }
        }
    }
}

// MARK: - 控制按钮组件

struct ControlButton: View {
    let icon: String
    let label: String
    let size: CGFloat
    let backgroundColor: Color
    let action: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Button(action: action) {
                Image(systemName: icon)
                    .font(.system(size: size * 0.4))
                    .foregroundColor(.white)
                    .frame(width: size, height: size)
                    .background(backgroundColor)
                    .clipShape(Circle())
                    .background(.ultraThinMaterial, in: Circle())
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            }

            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

// MARK: - Preview

#Preview {
    VoiceCallView()
}
