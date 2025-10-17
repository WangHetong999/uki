//
//  AuthService.swift
//  uki
//
//  Created by Claude on 2025/10/17.
//

import Foundation
import Supabase
import SwiftUI

/// 认证错误类型
enum AuthError: LocalizedError {
    case invalidEmail
    case weakPassword
    case emailAlreadyExists
    case invalidCredentials
    case networkError
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "邮箱格式不正确"
        case .weakPassword:
            return "密码至少需要 6 个字符"
        case .emailAlreadyExists:
            return "该邮箱已被注册"
        case .invalidCredentials:
            return "邮箱或密码错误"
        case .networkError:
            return "网络连接失败，请检查网络"
        case .unknown(let message):
            return message
        }
    }
}

/// 用户信息模型
struct UserProfile: Codable {
    let id: String
    let email: String
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case createdAt = "created_at"
    }
}

/// 认证服务 - 管理用户登录、注册、登出
@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var currentUser: UserProfile?
    @Published var isAuthenticated = false
    @Published var isLoading = false

    private let client = SupabaseManager.shared.client

    private init() {
        Task {
            await checkAuthStatus()
        }
    }

    // MARK: - 检查认证状态

    /// 检查当前用户是否已登录
    func checkAuthStatus() async {
        do {
            let session = try await client.auth.session
            self.isAuthenticated = true
            self.currentUser = UserProfile(
                id: session.user.id.uuidString,
                email: session.user.email ?? "",
                createdAt: session.user.createdAt
            )
        } catch {
            self.isAuthenticated = false
            self.currentUser = nil
        }
    }

    // MARK: - 注册

    /// 使用邮箱和密码注册新用户
    /// - Parameters:
    ///   - email: 用户邮箱
    ///   - password: 用户密码
    /// - Throws: AuthError
    func signUp(email: String, password: String) async throws {
        // 验证邮箱格式
        guard isValidEmail(email) else {
            throw AuthError.invalidEmail
        }

        // 验证密码强度
        guard password.count >= 6 else {
            throw AuthError.weakPassword
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await client.auth.signUp(
                email: email,
                password: password
            )

            // 注册成功后自动登录
            if let session = response.session {
                self.isAuthenticated = true
                self.currentUser = UserProfile(
                    id: session.user.id.uuidString,
                    email: session.user.email ?? "",
                    createdAt: session.user.createdAt
                )
            }
        } catch {
            // 处理 Supabase 错误
            throw mapSupabaseError(error)
        }
    }

    // MARK: - 登录

    /// 使用邮箱和密码登录
    /// - Parameters:
    ///   - email: 用户邮箱
    ///   - password: 用户密码
    /// - Throws: AuthError
    func signIn(email: String, password: String) async throws {
        // 验证邮箱格式
        guard isValidEmail(email) else {
            throw AuthError.invalidEmail
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let session = try await client.auth.signIn(
                email: email,
                password: password
            )

            self.isAuthenticated = true
            self.currentUser = UserProfile(
                id: session.user.id.uuidString,
                email: session.user.email ?? "",
                createdAt: session.user.createdAt
            )
        } catch {
            throw mapSupabaseError(error)
        }
    }

    // MARK: - 登出

    /// 退出登录
    func signOut() async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            try await client.auth.signOut()
            self.isAuthenticated = false
            self.currentUser = nil
        } catch {
            throw AuthError.unknown("登出失败: \(error.localizedDescription)")
        }
    }

    // MARK: - 辅助方法

    /// 验证邮箱格式
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    /// 映射 Supabase 错误到自定义错误
    private func mapSupabaseError(_ error: Error) -> AuthError {
        let errorMessage = error.localizedDescription.lowercased()

        if errorMessage.contains("email") && errorMessage.contains("already") {
            return .emailAlreadyExists
        } else if errorMessage.contains("invalid") && errorMessage.contains("credentials") {
            return .invalidCredentials
        } else if errorMessage.contains("network") || errorMessage.contains("connection") {
            return .networkError
        } else {
            return .unknown(error.localizedDescription)
        }
    }
}
