# HypeRateOnMac

一个 macOS 菜单栏应用，用于在顶部任务栏实时显示来自 HypeRate 的心率数据。

## 功能特性

- **实时心率显示**：在 macOS 菜单栏显示当前心率（❤️ 72）
- **WebSocket 实时连接**：通过 HypeRate WebSocket API 实时接收心率数据
- **可配置设备 ID**：支持修改 HypeRate 设备 ID
- **自动重连**：网络断开后自动恢复连接
- **连接状态指示**：显示连接状态（连接中、已连接、断开）

## 系统要求

- macOS 13.0 (Ventura) 或更高版本
- Apple Silicon 或 Intel Mac

## 安装方法

### 方法 1：从源码构建

1. 克隆仓库
```bash
git clone https://github.com/yourusername/HypeRateOnMac.git
cd HypeRateOnMac
```

2. 使用 Xcode 打开项目
```bash
open HypeRateOnMac.xcodeproj
```

3. 在 Xcode 中选择你的开发团队（Signing & Capabilities）

4. 构建并运行（Cmd + R）

### 方法 2：下载预构建版本

从 [Releases](https://github.com/yourusername/HypeRateOnMac/releases) 页面下载最新版本。

## 使用方法

1. **启动应用**：应用启动后会在菜单栏显示心形图标
2. **查看心率**：点击菜单栏图标展开下拉菜单，查看实时心率
3. **修改设备 ID**：
   - 点击菜单栏图标
   - 选择"设置"
   - 输入你的 HypeRate 设备 ID（4位大写字母或数字）
   - 点击保存

## 获取 HypeRate 设备 ID

1. 在手机上打开 HypeRate 应用
2. 开始测量心率
3. 获取分享链接，例如：`https://app.hyperate.io/EE6C`
4. 设备 ID 就是链接最后的部分（如 `EE6C`）

## 技术细节

- **开发语言**：Swift 5.9+
- **UI 框架**：SwiftUI + AppKit
- **WebSocket**：原生 `URLSessionWebSocketTask`
- **架构**：MVVM
- **最低系统**：macOS 13.0

### WebSocket API

- **端点**：`wss://app.hyperate.io/socket/websocket`
- **协议**：Phoenix Framework WebSocket Channel
- **订阅频道**：`hr:{deviceId}`

## 项目结构

```
HypeRateOnMac/
├── HypeRateOnMac/
│   ├── HypeRateOnMacApp.swift          # 应用入口
│   ├── Models/
│   │   ├── HeartRateData.swift         # 心率数据模型
│   │   └── WebSocketMessage.swift      # WebSocket 消息模型
│   ├── Services/
│   │   ├── HeartRateService.swift      # WebSocket 服务
│   │   └── SettingsService.swift       # 配置管理
│   ├── ViewModels/
│   │   └── HeartRateViewModel.swift    # 业务逻辑
│   └── Views/
│       ├── MenuBarView.swift           # 菜单栏 UI
│       └── SettingsView.swift          # 设置面板
└── README.md
```

## 许可证

MIT License

## 致谢

- [HypeRate](https://www.hyperate.io/) - 提供心率数据服务
