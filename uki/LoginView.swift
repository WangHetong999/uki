//
//  LoginView.swift
//  uki
//
//  Created by Claude on 2025/10/17.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var authService = AuthService.shared
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var errorMessage = ""
    @State private var showError = false

    var body: some View {
        NavigationView {
            ZStack {
                // 渐变背景
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.5, green: 0.3, blue: 0.8),
                        Color(red: 0.8, green: 0.4, blue: 0.7)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 30) {
                    // Logo 和标题
                    VStack(spacing: 15) {
                        Text("🐲")
                            .font(.system(size: 80))

                        Text("嘎巴龙")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text("欢迎回来")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.top, 50)

                    // 登录表单
                    VStack(spacing: 20) {
                        // 邮箱输入框
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.white.opacity(0.7))
                            TextField("邮箱地址", text: $email)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )

                        // 密码输入框
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.white.opacity(0.7))

                            if showPassword {
                                TextField("密码", text: $password)
                                    .foregroundColor(.white)
                            } else {
                                SecureField("密码", text: $password)
                                    .foregroundColor(.white)
                            }

                            Button(action: {
                                showPassword.toggle()
                            }) {
                                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 30)

                    // 登录按钮
                    Button(action: handleLogin) {
                        if authService.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .frame(height: 55)
                        } else {
                            Text("登录")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 55)
                        }
                    }
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.8, green: 0.3, blue: 0.6),
                                Color(red: 0.6, green: 0.3, blue: 0.9)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                    .padding(.horizontal, 30)
                    .disabled(authService.isLoading)

                    // 注册链接
                    NavigationLink(destination: RegisterView()) {
                        HStack(spacing: 5) {
                            Text("还没有账号?")
                                .foregroundColor(.white.opacity(0.8))
                            Text("立即注册")
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                    }

                    Spacer()
                }
            }
            .alert("登录失败", isPresented: $showError) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - 处理登录

    private func handleLogin() {
        // 隐藏键盘
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

        Task {
            do {
                try await authService.signIn(email: email, password: password)
                // 登录成功后，AuthService 会自动更新 isAuthenticated
                // ukiApp 会监听这个变化并切换到主界面
            } catch let error as AuthError {
                errorMessage = error.errorDescription ?? "未知错误"
                showError = true
            } catch {
                errorMessage = "登录失败: \(error.localizedDescription)"
                showError = true
            }
        }
    }
}

#Preview {
    LoginView()
}
