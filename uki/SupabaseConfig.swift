//
//  SupabaseConfig.swift
//  uki
//
//  Created by Claude on 2025/10/17.
//

import Foundation
import Supabase

/// Supabase 配置
/// 使用前请在 Supabase 控制台获取你的项目 URL 和 API Key
struct SupabaseConfig {
    // Supabase 项目 URL
    static let supabaseURL = "https://lxquuwlxxusufkcqhqdj.supabase.co"

    // Supabase anon public key
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx4cXV1d2x4eHVzdWZrY3FocWRqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg4MDE3NzksImV4cCI6MjA3NDM3Nzc3OX0.Yqyt9oZqtxstuMVq9bt7-teNzQuHYw07TS-Yhl5iuE0"
}

/// Supabase 客户端单例
class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        // 初始化 Supabase 客户端
        client = SupabaseClient(
            supabaseURL: URL(string: SupabaseConfig.supabaseURL)!,
            supabaseKey: SupabaseConfig.supabaseAnonKey
        )
    }
}
