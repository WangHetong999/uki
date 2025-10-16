# 🚀 如何运行真实聊天功能

## 📋 前置准备

### 1. 安装 Python 依赖

```bash
cd /Users/wanghetong/Desktop/uki
pip install flask flask-cors requests websockets pydub
```

## 🎯 启动步骤

### 第一步：启动 Python API 服务器

在终端中运行：

```bash
cd /Users/wanghetong/Desktop/uki
python server.py
```

你会看到：
```
🚀 启动 API 服务器...
📡 接口列表:
   POST http://localhost:5000/chat - 聊天接口
   POST http://localhost:5000/tts - 语音合成接口
   GET  http://localhost:5000/health - 健康检查

按 Ctrl+C 停止服务器
 * Running on http://0.0.0.0:5000
```

**保持这个终端窗口开着！** 不要关闭。

### 第二步：在 Xcode 中运行 iOS 应用

1. 打开 Xcode
2. 打开项目 `uki.xcodeproj`
3. 确保以下文件已添加到项目中：
   - `ChatView.swift`
   - `HomeView.swift`
   - `SettingsView.swift`
   - `NetworkService.swift`
4. 选择模拟器（如 iPhone 15）
5. 按 `Cmd + R` 运行

### 第三步：测试聊天功能

1. 应用启动后，点击 **"开始聊天"**
2. 你会看到嘎巴龙的欢迎消息
3. 点击右上角的 **📡 天线图标**，检查服务器连接状态
4. 在输入框输入消息，点击发送
5. 等待 AI 回复（会显示"思考中..."）
6. 回复会自动播放语音！

## 🔧 如何测试 API

### 使用 curl 测试聊天接口

```bash
curl -X POST http://localhost:5000/chat \
  -H "Content-Type: application/json" \
  -d '{
    "message": "你好",
    "history": []
  }'
```

返回：
```json
{
  "reply": "嘿，嘎巴嘎巴！你好呀～今天心情怎么样？🐲",
  "success": true
}
```

### 测试语音接口

```bash
curl -X POST http://localhost:5000/tts \
  -H "Content-Type: application/json" \
  -d '{"text": "你好"}' \
  --output test.mp3
```

会下载一个 `test.mp3` 文件，可以播放。

### 测试健康检查

```bash
curl http://localhost:5000/health
```

返回：
```json
{
  "status": "ok",
  "message": "服务器运行正常"
}
```

## 📱 应用功能说明

### ChatView（聊天页面）

- **发送消息**：在底部输入框输入文字，点击发送按钮
- **接收回复**：AI 会回复文字，并自动播放语音
- **历史对话**：自动保存最近 10 条对话，提供给 AI 作为上下文
- **加载状态**：发送消息时显示"思考中..."
- **错误提示**：如果网络出错会弹出提示

### 检查服务器状态

点击右上角的 📡 图标，会检查服务器是否在线：
- ✅ 服务器连接正常
- ❌ 无法连接服务器

## ⚠️ 常见问题

### 1. 发送消息后没有回复

**原因**：服务器没有启动
**解决**：确保 `python server.py` 正在运行

### 2. 显示"无法连接服务器"

**原因**：iOS 模拟器无法访问 localhost
**解决**：
- 在模拟器中，`localhost:5000` 应该是可以访问的
- 如果使用真机测试，需要修改 `NetworkService.swift` 中的 `baseURL`：
  ```swift
  static let baseURL = "http://你的电脑IP:5000"
  ```
  查看 IP：系统设置 -> 网络 -> Wi-Fi -> 详细信息

### 3. API Key 过期

如果 API 返回 401 错误，说明 API Key 过期了。
需要更新 `server.py` 中的：
- `MINIMAX_API_KEY` - 语音合成
- `SILICONFLOW_HEADERS` 中的 Bearer token - 聊天模型

### 4. 语音播放失败

确保：
- 模拟器音量已开启
- 检查终端是否显示 TTS 错误

## 🎨 页面导航说明

### 多页面是如何工作的？

SwiftUI 使用 `NavigationView` + `NavigationLink` 实现页面跳转：

```swift
NavigationView {  // 外层容器
    NavigationLink(destination: ChatView()) {  // 跳转链接
        Text("开始聊天")
    }
}
```

### 当前页面结构

```
ContentView
  └─ HomeView (主页)
       ├─ NavigationLink → ChatView (聊天页)
       └─ NavigationLink → SettingsView (设置页)
```

## 📂 项目文件说明

### Python 后端
- `server.py` - Flask API 服务器（**新创建**，用这个！）
- `api.py` - 原始命令行程序（保留，不使用）
- `avatar_chat.py` - 原始聊天程序（保留，不使用）

### iOS 前端
- `HomeView.swift` - 主页/欢迎页
- `ChatView.swift` - 聊天页面（已更新，支持真实 API）
- `SettingsView.swift` - 设置页面
- `NetworkService.swift` - 网络服务层（**新创建**）
- `ContentView.swift` - 主入口

## 🔄 完整测试流程

1. ✅ 启动 `python server.py`
2. ✅ 在 Xcode 运行应用
3. ✅ 点击"开始聊天"
4. ✅ 点击右上角📡检查连接
5. ✅ 发送消息"你好"
6. ✅ 等待 AI 回复和语音播放
7. ✅ 继续对话测试

## 🎉 完成！

现在你的应用已经可以：
- ✅ 发送消息到 AI
- ✅ 接收 AI 的文字回复
- ✅ 自动播放语音
- ✅ 保持对话上下文
- ✅ 多页面导航

下一步你可以：
- 添加 Apple Watch 端
- 实现 iPhone 和 Watch 之间的同步
- 美化 UI 界面
- 添加更多功能（表情、图片等）
