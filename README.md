# HypeRateOnMac

HypeRateOnMac 是一款 macOS 菜单栏应用程序，用于实时显示 HypeRate 设备的心率数据。

![macOS](https://img.shields.io/badge/macOS-13.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.0+-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## 功能特性

- **实时心率显示**：通过 WebSocket 连接实时获取并显示心率数据
- **菜单栏集成**：在 macOS 菜单栏中显示当前心率（BPM）
- **连接状态可视化**：
  - ❤️ 已连接：显示绿色状态和心率数值
  - 💛 连接中：显示橙色状态
  - 💔 已断开：显示灰色状态
  - ❌ 错误：显示红色状态和错误信息
- **自动重连**：连接断开后自动重连，采用指数退避策略
- **心跳保活**：每 15 秒发送一次心跳消息保持连接
- **配置持久化**：使用 UserDefaults 保存设备 ID
- **网络监控**：实时监测网络连接状态

## 快速开始

### 1. 获取 API Key

前往 [HypeRate API](https://www.hyperate.io/api) 申请你的 API Key。

### 2. 配置 API Key

```bash
# 复制配置模板
cp Secrets.xcconfig.example Secrets.xcconfig

# 编辑配置文件，填入你的 API Key
# HYPERATE_API_KEY = your_api_key_here
```

### 3. 构建运行

```bash
# 使用 Xcode 打开项目
open HypeRateOnMac.xcodeproj

# 或使用命令行构建
xcodebuild -scheme HypeRateOnMac -configuration Release build
```

### 4. 安装应用

构建完成后，将 `HypeRateOnMac.app` 复制到 `/Applications` 目录。

## 项目结构

```
HypeRateOnMac/
├── HypeRateOnMac/
│   ├── HypeRateOnMacApp.swift              # 应用入口和 AppDelegate
│   ├── Info.plist                          # 应用配置
│   ├── Assets.xcassets/                    # 资源文件（图标等）
│   ├── Managers/
│   │   └── MenuBarManager.swift            # 菜单栏管理
│   ├── Models/
│   │   └── HeartRateData.swift             # 连接状态枚举
│   ├── ViewModels/
│   │   └── HeartRateViewModel.swift        # 视图模型
│   ├── Views/
│   │   └── MenuBarView.swift               # 菜单栏弹出视图
│   ├── Services/
│   │   ├── HeartRateService.swift          # WebSocket 服务
│   │   ├── HeartRateServiceProtocol.swift  # 服务协议（依赖注入）
│   │   ├── SettingsService.swift           # 设置持久化
│   │   └── NetworkMonitor.swift            # 网络状态监控
│   └── Utilities/
│       ├── AppColors.swift                 # 颜色常量
│       └── AppConfig.swift                 # 配置管理（API Key）
├── HypeRateOnMacTests/                     # 单元测试
├── Secrets.xcconfig                        # API Key 配置（不提交到 Git）
├── Secrets.xcconfig.example                # 配置模板
└── HypeRateOnMac.xcodeproj/                # Xcode 项目文件
```

## 技术栈

- **语言**：Swift 5.0+
- **最低系统**：macOS 13.0+
- **框架**：
  - SwiftUI：用户界面
  - Combine：响应式数据流
  - AppKit：macOS 系统集成（NSStatusItem、NSPopover）
  - Network：网络状态监控（NWPathMonitor）
  - OSLog：日志记录
- **网络**：URLSessionWebSocketTask（WebSocket 连接）

## 使用说明

### 配置设备

1. 点击菜单栏中的心形图标
2. 在弹出窗口中输入你的 HypeRate 设备 ID（3-6 位字母数字）
3. 点击"Connect"按钮连接

### 查看心率

- 菜单栏显示实时心率数值
- 点击图标查看详细信息和连接状态
- 心率颜色表示：
  - 绿色：正常 (<100 BPM)
  - 橙色：升高 (100-120 BPM)
  - 红色：偏高 (>120 BPM)

## WebSocket 协议

应用使用 HypeRate WebSocket API，遵循 Phoenix 框架的频道协议：

- **端点**：`wss://app.hyperate.io/socket/websocket?token={api_key}`
- **频道**：`hr:{device_id}`

### 消息类型

| 事件 | 说明 |
|-----|------|
| `phx_join` | 加入心率频道 |
| `phx_leave` | 离开心率频道 |
| `hr_update` | 心率更新 |
| `ping` | 心跳保活 |

## 连接状态

| 状态 | 颜色 | 说明 |
|-----|------|------|
| `disconnected` | 灰色 | 未连接 |
| `connecting` | 橙色 | 连接中 |
| `connected` | 绿色 | 已连接 |
| `error` | 红色 | 错误 |

## 重连机制

- 最大重连次数：10 次
- 重连延迟：指数退避（2s → 4s → 8s → ... → 60s）
- 重连成功后自动重置计数器

## 开发说明

### 构建要求

- macOS 13.0+
- Xcode 14.0+
- Swift 5.0+

### 运行测试

```bash
xcodebuild test -scheme HypeRateOnMac -destination 'platform=macOS'
```

### 查看日志

```bash
log show --predicate 'subsystem == "com.hyperate.HypeRateOnMac"' --last 5m
```

## 安全说明

- API Key 存储在 `Secrets.xcconfig` 文件中
- 该文件已添加到 `.gitignore`，不会提交到版本控制
- 构建时 API Key 会被编译到应用中

## 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件

## 相关链接

- [HypeRate 官网](https://hyperate.io/)
- [HypeRate WebSocket API](https://github.com/HypeRate/HypeRate-Websocket-API)
