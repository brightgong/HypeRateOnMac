# HypeRateOnMac

[中文](README_zh.md) | English

A macOS menu bar app for displaying real-time heart rate data from HypeRate devices.

![macOS](https://img.shields.io/badge/macOS-13.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.0+-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

- **Real-time Heart Rate Display**: Get live heart rate data via WebSocket connection
- **Menu Bar Integration**: Display current BPM in macOS menu bar
- **Connection Status Visualization**:
  - ❤️ Connected: Green status with heart rate value
  - 💛 Connecting: Orange status
  - 💔 Disconnected: Gray status
  - ❌ Error: Red status with error message
- **Auto Reconnection**: Automatic reconnection with exponential backoff
- **Heartbeat Keep-alive**: Send heartbeat every 15 seconds
- **Persistent Configuration**: Save device ID using UserDefaults
- **Network Monitoring**: Real-time network connectivity detection

## Quick Start

### Option 1: Download Release (Recommended)

1. Download the latest release from [Releases](https://github.com/brightgong/HypeRateOnMac/releases)
2. Unzip and drag `HypeRateOnMac.app` to `/Applications`
3. Launch the app and enter your HypeRate device ID

### Option 2: Build from Source

#### 1. Get API Key

Visit [HypeRate API](https://www.hyperate.io/api) to get your API Key.

#### 2. Configure API Key

```bash
# Copy the config template
cp Secrets.xcconfig.example Secrets.xcconfig

# Edit the config file with your API Key
# HYPERATE_API_KEY = your_api_key_here
```

#### 3. Build and Run

```bash
# Open project in Xcode
open HypeRateOnMac.xcodeproj

# Or build from command line
xcodebuild -scheme HypeRateOnMac -configuration Release build
```

#### 4. Install

Copy `HypeRateOnMac.app` from build output to `/Applications`.

## Project Structure

```
HypeRateOnMac/
├── HypeRateOnMac/
│   ├── HypeRateOnMacApp.swift              # App entry and AppDelegate
│   ├── Info.plist                          # App configuration
│   ├── Assets.xcassets/                    # Resources (icons, etc.)
│   ├── Managers/
│   │   └── MenuBarManager.swift            # Menu bar management
│   ├── Models/
│   │   └── HeartRateData.swift             # Connection state enum
│   ├── ViewModels/
│   │   └── HeartRateViewModel.swift        # View model
│   ├── Views/
│   │   └── MenuBarView.swift               # Menu bar popover view
│   ├── Services/
│   │   ├── HeartRateService.swift          # WebSocket service
│   │   ├── HeartRateServiceProtocol.swift  # Service protocol (DI)
│   │   ├── SettingsService.swift           # Settings persistence
│   │   └── NetworkMonitor.swift            # Network status monitor
│   └── Utilities/
│       ├── AppColors.swift                 # Color constants
│       └── AppConfig.swift                 # Config management (API Key)
├── HypeRateOnMacTests/                     # Unit tests
├── Secrets.xcconfig                        # API Key config (not in Git)
├── Secrets.xcconfig.example                # Config template
└── HypeRateOnMac.xcodeproj/                # Xcode project
```

## Tech Stack

- **Language**: Swift 5.0+
- **Minimum OS**: macOS 13.0+
- **Frameworks**:
  - SwiftUI: User interface
  - Combine: Reactive data flow
  - AppKit: macOS integration (NSStatusItem, NSPopover)
  - Network: Network monitoring (NWPathMonitor)
  - OSLog: Logging
- **Networking**: URLSessionWebSocketTask (WebSocket)

## Usage

### Configure Device

1. Click the heart icon in the menu bar
2. Enter your HypeRate device ID (3-6 alphanumeric characters)
3. Click "Connect" button

### View Heart Rate

- Menu bar displays real-time heart rate
- Click icon for detailed info and connection status
- Heart rate colors:
  - Green: Normal (<100 BPM)
  - Orange: Elevated (100-120 BPM)
  - Red: High (>120 BPM)

## WebSocket Protocol

Uses HypeRate WebSocket API following Phoenix channel protocol:

- **Endpoint**: `wss://app.hyperate.io/socket/websocket?token={api_key}`
- **Channel**: `hr:{device_id}`

### Message Types

| Event | Description |
|-------|-------------|
| `phx_join` | Join heart rate channel |
| `phx_leave` | Leave heart rate channel |
| `hr_update` | Heart rate update |
| `ping` | Heartbeat keep-alive |

## Connection States

| State | Color | Description |
|-------|-------|-------------|
| `disconnected` | Gray | Not connected |
| `connecting` | Orange | Connecting |
| `connected` | Green | Connected |
| `error` | Red | Error |

## Reconnection

- Max attempts: 10
- Delay: Exponential backoff (2s → 4s → 8s → ... → 60s max)
- Counter resets on successful connection

## Development

### Requirements

- macOS 13.0+
- Xcode 14.0+
- Swift 5.0+

### Run Tests

```bash
xcodebuild test -scheme HypeRateOnMac -destination 'platform=macOS'
```

### View Logs

```bash
log show --predicate 'subsystem == "com.hyperate.HypeRateOnMac"' --last 5m
```

## Security

- API Key stored in `Secrets.xcconfig`
- File is in `.gitignore`, not committed to version control
- API Key is compiled into the app at build time

## License

MIT License

## Links

- [HypeRate Website](https://hyperate.io/)
- [HypeRate WebSocket API](https://github.com/HypeRate/HypeRate-Websocket-API)
