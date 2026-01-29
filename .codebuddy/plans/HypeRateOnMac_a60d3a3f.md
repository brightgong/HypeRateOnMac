---
name: HypeRateOnMac
overview: 创建一个 macOS 菜单栏应用，实时显示 HypeRate 心率数据，支持自定义 ID 设置
design:
  styleKeywords:
    - macOS Native
    - Minimalist
    - Menu Bar
    - Clean
    - Lightweight
  fontSystem:
    fontFamily: SF Pro
    heading:
      size: 16px
      weight: 600
    subheading:
      size: 14px
      weight: 500
    body:
      size: 13px
      weight: 400
  colorSystem:
    primary:
      - "#007AFF"
      - "#FF3B30"
    background:
      - "#FFFFFF"
      - "#F5F5F5"
    text:
      - "#000000"
      - "#8E8E93"
      - "#FF3B30"
    functional:
      - "#34C759"
      - "#FF9500"
      - "#FF3B30"
todos:
  - id: create-project
    content: 创建 Xcode 项目，配置菜单栏应用基础结构
    status: completed
  - id: models
    content: 实现心率数据模型和 WebSocket 消息模型
    status: completed
    dependencies:
      - create-project
  - id: websocket-service
    content: 实现 HeartRateService，完成 WebSocket 连接和 Phoenix Channel 协议
    status: completed
    dependencies:
      - models
  - id: settings-service
    content: 实现 SettingsService，使用 UserDefaults 保存配置
    status: completed
    dependencies:
      - create-project
  - id: viewmodel
    content: 实现 HeartRateViewModel，连接服务和 UI
    status: completed
    dependencies:
      - websocket-service
      - settings-service
  - id: menubar-ui
    content: 实现菜单栏 UI 和下拉菜单界面
    status: completed
    dependencies:
      - viewmodel
  - id: settings-ui
    content: 实现设置面板，支持修改 HypeRate ID
    status: completed
    dependencies:
      - viewmodel
  - id: integration
    content: 整合所有组件，测试完整功能流程
    status: completed
    dependencies:
      - menubar-ui
      - settings-ui
---

## 产品概述

HypeRateOnMac 是一款 macOS 菜单栏应用，用于在顶部任务栏实时显示来自 HypeRate 服务的心率数据。

## 核心功能

- **实时心率显示**: 在 macOS 菜单栏显示当前心率（格式：❤️ 72）
- **WebSocket 连接**: 通过 HypeRate WebSocket API 实时接收心率数据
- **可配置 ID**: 支持修改 HypeRate 设备 ID（如 EE6C）
- **自动重连**: 网络断开后自动恢复连接
- **连接状态指示**: 显示连接状态（连接中、已连接、断开）

## 技术规格

- **WebSocket 端点**: `wss://app.hyperate.io/socket/websocket`
- **协议**: Phoenix Framework WebSocket Channel
- **订阅频道**: `hr:{id}`（如 `hr:EE6C`）
- **消息格式**: JSON，包含 `heartrate` 字段
- **无需认证**: 公开 API，无需 API Key

## 技术栈选择

- **开发语言**: Swift 5.9+
- **UI 框架**: SwiftUI + AppKit（菜单栏集成）
- **WebSocket**: `URLSessionWebSocketTask`（原生支持）
- **数据存储**: `UserDefaults`（保存用户配置）
- **最低系统**: macOS 13.0 (Ventura)

## 实现方案

### 架构设计

采用 MVVM 架构，分离关注点：

- **Model**: 心率数据模型、WebSocket 消息模型
- **ViewModel**: 心率服务（WebSocket 管理）、配置管理
- **View**: 菜单栏 UI、设置面板

### WebSocket 通信流程

1. 建立 WebSocket 连接到 `wss://app.hyperate.io/socket/websocket`
2. 发送 Phoenix Channel `join` 消息订阅 `hr:{id}` 频道
3. 接收 `hr:update` 事件获取实时心率
4. 发送心跳包维持连接
5. 断线时自动重连

### Phoenix Channel 协议

```
// Join 消息
{
  "topic": "hr:EE6C",
  "event": "phx_join",
  "payload": {},
  "ref": "1"
}

// 心率更新消息
{
  "topic": "hr:EE6C",
  "event": "hr:update",
  "payload": {"heartrate": 72, "timestamp": 1234567890}
}
```

### 性能优化

- 使用 `URLSessionWebSocketTask` 原生 WebSocket，性能优秀
- 指数退避重连策略，避免频繁重连
- 菜单栏 UI 轻量更新，避免不必要的重绘

## 目录结构

```
HypeRateOnMac/
├── HypeRateOnMac/
│   ├── HypeRateOnMacApp.swift          # [NEW] 应用入口，菜单栏配置
│   ├── Models/
│   │   ├── HeartRateData.swift         # [NEW] 心率数据模型
│   │   └── WebSocketMessage.swift      # [NEW] WebSocket 消息模型
│   ├── Services/
│   │   ├── HeartRateService.swift      # [NEW] WebSocket 连接和心率获取服务
│   │   └── SettingsService.swift       # [NEW] 用户配置管理服务
│   ├── ViewModels/
│   │   └── HeartRateViewModel.swift    # [NEW] 心率显示逻辑
│   └── Views/
│       ├── MenuBarView.swift           # [NEW] 菜单栏下拉界面
│       └── SettingsView.swift          # [NEW] 设置面板
├── HypeRateOnMac.xcodeproj/            # [NEW] Xcode 项目配置
└── README.md                           # [NEW] 项目说明文档
```

## 关键代码结构

### HeartRateService 协议

```swift
protocol HeartRateServiceProtocol {
    var heartRate: Int? { get }
    var connectionState: ConnectionState { get }
    var onHeartRateUpdate: ((Int) -> Void)? { get set }
    var onConnectionStateChange: ((ConnectionState) -> Void)? { get set }
    
    func connect(deviceId: String)
    func disconnect()
}

enum ConnectionState {
    case disconnected
    case connecting
    case connected
    case error(String)
}
```

### WebSocketMessage 结构

```swift
struct PhoenixMessage: Codable {
    let topic: String
    let event: String
    let payload: [String: AnyCodable]
    let ref: String?
}

struct HeartRatePayload: Codable {
    let heartrate: Int
    let timestamp: Int?
}
```

## 设计风格

采用 macOS 原生设计风格，简洁、轻量、融入系统菜单栏。

### 菜单栏显示

- **图标 + 数字**: 使用 SF Symbols 心形图标 + 心率数字
- **颜色状态**: 
- 正常：系统默认文字颜色
- 高心率（>120）：橙红色警示
- 断开连接：灰色显示 "--"

### 下拉菜单设计

- **顶部**: 大字体显示当前心率（❤️ 72 BPM）
- **分隔线**: 原生 macOS 风格分隔
- **状态行**: 显示连接状态（"已连接" / "连接中..." / "已断开"）
- **操作项**: 
- 设置...（打开设置面板）
- 退出

### 设置面板

- **简洁窗口**: 使用 SwiftUI Form
- **输入项**: HypeRate ID 输入框（4位大写字母/数字）
- **实时验证**: 输入时验证格式
- **保存按钮**: 保存后自动重新连接

### 交互细节

- 点击菜单栏图标展开下拉菜单
- 悬停效果使用原生 macOS 样式
- 设置面板使用模态窗口