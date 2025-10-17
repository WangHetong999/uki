//
//  SettingsView.swift
//  uki
//
//  设置页面 - 用户信息和应用设置
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var authService = AuthService.shared
    @State private var nickname = "小艾"
    @State private var age = "25"
    @State private var gender = "女"
    @State private var enableNotifications = true
    @State private var enableSound = true
    @State private var voiceSpeed: Double = 1.0
    @State private var showLogoutConfirm = false
    @State private var showLogoutError = false
    @State private var errorMessage = ""

    var body: some View {
        Form {
            // 用户信息部分
            Section(header: Text("用户信息")) {
                HStack {
                    Text("头像")
                    Spacer()
                    Circle()
                        .fill(Color.purple.opacity(0.3))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Text("🐲")
                                .font(.system(size: 30))
                        )
                }

                HStack {
                    Text("邮箱")
                    Spacer()
                    Text(authService.currentUser?.email ?? "未登录")
                        .foregroundColor(.gray)
                }

                HStack {
                    Text("昵称")
                    Spacer()
                    TextField("输入昵称", text: $nickname)
                        .multilineTextAlignment(.trailing)
                }

                HStack {
                    Text("性别")
                    Spacer()
                    Picker("性别", selection: $gender) {
                        Text("男").tag("男")
                        Text("女").tag("女")
                        Text("其他").tag("其他")
                    }
                    .pickerStyle(.menu)
                }

                HStack {
                    Text("年龄")
                    Spacer()
                    TextField("年龄", text: $age)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
            }

            // 聊天设置
            Section(header: Text("聊天设置")) {
                Toggle("开启通知", isOn: $enableNotifications)

                Toggle("开启声音", isOn: $enableSound)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("语音速度")
                        Spacer()
                        Text(String(format: "%.1fx", voiceSpeed))
                            .foregroundColor(.gray)
                    }

                    Slider(value: $voiceSpeed, in: 0.5...2.0, step: 0.1)
                        .accentColor(.purple)
                }
            }

            // AI 角色信息
            Section(header: Text("AI 角色")) {
                HStack {
                    Text("名字")
                    Spacer()
                    Text("嘎巴龙")
                        .foregroundColor(.gray)
                }

                HStack {
                    Text("性格")
                    Spacer()
                    Text("调皮、俏皮、专情")
                        .foregroundColor(.gray)
                }

                HStack {
                    Text("来自")
                    Spacer()
                    Text("嘎巴星球")
                        .foregroundColor(.gray)
                }
            }

            // 关于
            Section(header: Text("关于")) {
                HStack {
                    Text("版本")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.gray)
                }

                Button(action: {}) {
                    Text("隐私政策")
                }

                Button(action: {}) {
                    Text("用户协议")
                }
            }

            // 退出登录
            Section {
                Button(action: {
                    showLogoutConfirm = true
                }) {
                    HStack {
                        Spacer()
                        Text("退出登录")
                            .foregroundColor(.red)
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
        .alert("确认退出", isPresented: $showLogoutConfirm) {
            Button("取消", role: .cancel) { }
            Button("退出", role: .destructive) {
                handleLogout()
            }
        } message: {
            Text("确定要退出登录吗？")
        }
        .alert("退出失败", isPresented: $showLogoutError) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - 退出登录

    private func handleLogout() {
        Task {
            do {
                try await authService.signOut()
                // 登出成功后，AuthService 会自动更新 isAuthenticated
                // ukiApp 会监听这个变化并切换到登录界面
            } catch {
                errorMessage = error.localizedDescription
                showLogoutError = true
            }
        }
    }
}

#Preview {
    NavigationView {
        SettingsView()
    }
}
