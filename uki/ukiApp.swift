//
//  ukiApp.swift
//  uki
//
//  Created by 王鹤潼 on 2025/10/13.
//

import SwiftUI

@main
struct ukiApp: App {
    @StateObject private var authService = AuthService.shared

    var body: some Scene {
        WindowGroup {
            if authService.isAuthenticated {
                // 已登录 - 显示主应用界面
                ContentView()
            } else {
                // 未登录 - 显示登录界面
                LoginView()
            }
        }
    }
}
