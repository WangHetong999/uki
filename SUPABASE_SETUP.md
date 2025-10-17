# Supabase 邮箱登录配置指南

本文档说明如何为 uki 应用配置 Supabase 邮箱登录功能。

## 📋 目录

1. [创建 Supabase 项目](#1-创建-supabase-项目)
2. [配置认证设置](#2-配置认证设置)
3. [获取 API 密钥](#3-获取-api-密钥)
4. [配置 iOS 项目](#4-配置-ios-项目)
5. [测试登录功能](#5-测试登录功能)
6. [常见问题](#6-常见问题)

---

## 1. 创建 Supabase 项目

### 步骤 1.1: 注册 Supabase 账号
1. 访问 [https://supabase.com](https://supabase.com)
2. 点击 **Start your project** 或 **Sign in**
3. 使用 GitHub 账号登录（推荐）或创建新账号

### 步骤 1.2: 创建新项目
1. 登录后，点击 **New Project**
2. 填写项目信息：
   - **Organization**: 选择或创建组织
   - **Name**: `uki` 或自定义名称
   - **Database Password**: 设置一个强密码（保存好）
   - **Region**: 选择 `Northeast Asia (Tokyo)` 或最近的区域
3. 点击 **Create new project**
4. 等待 1-2 分钟，项目初始化完成

---

## 2. 配置认证设置

### 步骤 2.1: 启用邮箱登录
1. 在项目控制台，点击左侧菜单 **Authentication**
2. 点击 **Providers** 标签
3. 找到 **Email** 提供商
4. 确保 **Email** 开关是打开的（默认已启用）

### 步骤 2.2: 配置邮箱验证（可选）
默认情况下，Supabase 要求用户验证邮箱。如果你想在开发阶段跳过验证：

1. 点击 **Email** 提供商进入设置
2. 找到 **Confirm email** 选项
3. 关闭 **Confirm email** 开关（仅用于开发，生产环境请打开）
4. 点击 **Save** 保存设置

> ⚠️ **注意**: 生产环境强烈建议启用邮箱验证！

### 步骤 2.3: 配置重定向 URL（可选）
1. 在 **Authentication > URL Configuration** 中
2. 添加重定向 URL（目前邮箱登录不需要）
3. 默认设置即可

---

## 3. 获取 API 密钥

### 步骤 3.1: 获取项目 URL 和 API Key
1. 在项目控制台，点击左侧菜单 **Settings**（齿轮图标）
2. 点击 **API** 标签
3. 复制以下信息：
   - **Project URL**: 类似 `https://xxxxxxxxxxxxx.supabase.co`
   - **anon public** key: 以 `eyJ` 开头的长字符串

> 📝 **重要**: 保存这两个值，下一步需要用到！

### 示例：
```
Project URL: https://abcdefghijk.supabase.co
anon key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6...
```

---

## 4. 配置 iOS 项目

### 步骤 4.1: 添加 Supabase Swift SDK

1. 在 Xcode 中打开 `uki.xcodeproj`
2. 选择项目文件（蓝色图标）
3. 选择 `uki` target
4. 点击 **Package Dependencies** 标签
5. 点击 `+` 按钮
6. 输入包 URL:
   ```
   https://github.com/supabase/supabase-swift
   ```
7. 点击 **Add Package**
8. 在弹出的窗口中，确保选中 `Supabase`
9. 点击 **Add Package**

### 步骤 4.2: 配置 Supabase 密钥

打开文件 `uki/SupabaseConfig.swift`，替换以下内容：

```swift
struct SupabaseConfig {
    // 替换为你的 Supabase 项目 URL
    static let supabaseURL = "https://你的项目id.supabase.co"

    // 替换为你的 Supabase anon key
    static let supabaseAnonKey = "eyJ开头的完整key..."
}
```

**示例：**
```swift
struct SupabaseConfig {
    static let supabaseURL = "https://abcdefghijk.supabase.co"
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFiY2RlZmdoaWprIiwicm9sZSI6ImFub24iLCJpYXQiOjE2OTk5OTk5OTksImV4cCI6MjAxNTU3NTk5OX0.xxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
}
```

### 步骤 4.3: 检查文件结构

确保以下文件已添加到项目中：

```
uki/
├── SupabaseConfig.swift      ✅ Supabase 配置
├── AuthService.swift          ✅ 认证服务
├── LoginView.swift            ✅ 登录界面
├── RegisterView.swift         ✅ 注册界面
├── ukiApp.swift               ✅ 已修改（认证状态管理）
└── SettingsView.swift         ✅ 已修改（退出登录）
```

---

## 5. 测试登录功能

### 步骤 5.1: 构建并运行

1. 在 Xcode 中，选择模拟器（如 iPhone 15）
2. 点击 **Run** 按钮（▶️）或按 `Cmd + R`
3. 应用启动后，应该看到登录界面

### 步骤 5.2: 注册新用户

1. 点击 **"立即注册"** 链接
2. 输入邮箱地址（如 `test@example.com`）
3. 输入密码（至少 6 个字符）
4. 确认密码
5. 点击 **"注册"** 按钮
6. 注册成功后会自动登录并显示主界面

### 步骤 5.3: 退出登录

1. 在主界面，点击 **"设置"** 按钮
2. 滚动到底部
3. 点击 **"退出登录"** 按钮（红色）
4. 确认退出
5. 应用会返回登录界面

### 步骤 5.4: 再次登录

1. 输入刚才注册的邮箱和密码
2. 点击 **"登录"** 按钮
3. 登录成功后进入主界面

---

## 6. 常见问题

### Q1: 编译错误："No such module 'Supabase'"
**解决方案:**
1. 确保已正确添加 Supabase Swift SDK（见步骤 4.1）
2. 清理构建缓存：`Cmd + Shift + K`
3. 重新构建：`Cmd + B`

### Q2: 登录时报错："Invalid URL"
**解决方案:**
- 检查 `SupabaseConfig.swift` 中的 `supabaseURL` 是否正确
- URL 必须以 `https://` 开头
- URL 格式：`https://项目id.supabase.co`

### Q3: 注册时报错："邮箱已被注册"
**解决方案:**
- 该邮箱已经注册过，请直接登录
- 或者在 Supabase 控制台删除该用户：
  1. Authentication > Users
  2. 找到该用户并点击删除

### Q4: 登录成功但显示"未登录"
**解决方案:**
- 检查 `AuthService.swift` 中的 `checkAuthStatus()` 方法
- 确保 `ukiApp.swift` 正确监听 `authService.isAuthenticated`
- 重启应用

### Q5: 如何在 Supabase 控制台查看用户？
**解决方案:**
1. 登录 Supabase 控制台
2. 选择项目
3. 点击 **Authentication** > **Users**
4. 可以看到所有注册用户

### Q6: 如何重置用户密码？
**当前实现:**
- 目前没有实现密码重置功能
- 用户需要使用 Supabase 控制台手动重置
- 或者删除用户后重新注册

**未来改进:**
可以添加 "忘记密码" 功能，使用 Supabase 的密码重置 API：
```swift
try await client.auth.resetPasswordForEmail(email)
```

---

## 🎉 完成！

现在你的 uki 应用已经具备完整的邮箱登录功能：

✅ 用户注册
✅ 用户登录
✅ 退出登录
✅ 认证状态管理
✅ 持久化会话（自动登录）

---

## 📚 相关文档

- [Supabase 官方文档](https://supabase.com/docs)
- [Supabase Swift SDK](https://github.com/supabase/supabase-swift)
- [Supabase Auth API](https://supabase.com/docs/guides/auth)

---

## 🔐 安全建议

⚠️ **生产环境注意事项:**

1. **启用邮箱验证**: 防止恶意注册
2. **配置速率限制**: 防止暴力破解
3. **使用环境变量**: 不要在代码中硬编码 API 密钥
4. **启用 Row Level Security (RLS)**: 保护数据库安全
5. **定期更新密钥**: 定期轮换 API 密钥

---

如有问题，请查看 [Supabase 社区论坛](https://github.com/supabase/supabase/discussions) 或提交 Issue。
