//
//  RegisterView.swift
//  uki
//
//  Created by Claude on 2025/10/17.
//

import SwiftUI

struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authService = AuthService.shared

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var showSuccess = false

    var body: some View {
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

            ScrollView {
                VStack(spacing: 30) {
                    // Logo 和标题
                    VStack(spacing: 15) {
                        Text("🐲")
                            .font(.system(size: 80))

                        Text("创建账号")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text("加入嘎巴龙的世界")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.top, 50)

                    // 注册表单
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
                                TextField("密码 (至少6位)", text: $password)
                                    .foregroundColor(.white)
                            } else {
                                SecureField("密码 (至少6位)", text: $password)
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

                        // 确认密码输入框
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.white.opacity(0.7))

                            if showConfirmPassword {
                                TextField("确认密码", text: $confirmPassword)
                                    .foregroundColor(.white)
                            } else {
                                SecureField("确认密码", text: $confirmPassword)
                                    .foregroundColor(.white)
                            }

                            Button(action: {
                                showConfirmPassword.toggle()
                            }) {
                                Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
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

                        // 密码强度提示
                        if !password.isEmpty {
                            HStack {
                                Image(systemName: password.count >= 6 ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(password.count >= 6 ? .green : .red)
                                Text(password.count >= 6 ? "密码强度合格" : "密码至少需要6个字符")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                                Spacer()
                            }
                            .padding(.horizontal, 5)
                        }

                        // 密码匹配提示
                        if !confirmPassword.isEmpty {
                            HStack {
                                Image(systemName: password == confirmPassword ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(password == confirmPassword ? .green : .red)
                                Text(password == confirmPassword ? "密码匹配" : "两次密码不一致")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                                Spacer()
                            }
                            .padding(.horizontal, 5)
                        }
                    }
                    .padding(.horizontal, 30)

                    // 注册按钮
                    Button(action: handleRegister) {
                        if authService.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .frame(height: 55)
                        } else {
                            Text("注册")
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
                    .disabled(authService.isLoading || !isFormValid)
                    .opacity(isFormValid ? 1.0 : 0.6)

                    // 用户协议提示
                    Text("注册即表示您同意我们的服务条款和隐私政策")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    Spacer()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("注册失败", isPresented: $showError) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .alert("注册成功", isPresented: $showSuccess) {
            Button("开始使用", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("欢迎加入嘎巴龙的世界！")
        }
    }

    // MARK: - 表单验证

    private var isFormValid: Bool {
        !email.isEmpty &&
        password.count >= 6 &&
        password == confirmPassword
    }

    // MARK: - 处理注册

    private func handleRegister() {
        // 验证密码匹配
        guard password == confirmPassword else {
            errorMessage = "两次输入的密码不一致"
            showError = true
            return
        }

        // 隐藏键盘
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

        Task {
            do {
                try await authService.signUp(email: email, password: password)
                // 注册成功
                showSuccess = true
            } catch let error as AuthError {
                errorMessage = error.errorDescription ?? "未知错误"
                showError = true
            } catch {
                errorMessage = "注册失败: \(error.localizedDescription)"
                showError = true
            }
        }
    }
}

#Preview {
    NavigationView {
        RegisterView()
    }
}
