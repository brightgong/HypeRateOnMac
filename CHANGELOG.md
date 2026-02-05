# 开发日志

## 2025-02-05

### refactor: simplify configuration and remove SettingsView

**Major changes:**
- Remove SettingsView.swift and integrate device ID configuration into MenuBarView
- Add inline device ID editing section with expandable UI
- Add connect/disconnect toggle button for manual connection control
- Simplify HeartRateService connection method signature

**Service layer:**
- HeartRateService: Simplify connect() method to accept only deviceId
- SettingsService: Remove unused validation methods
- HeartRateViewModel: Add toggleConnection() for connection state management

**UI improvements:**
- MenuBarView: Add device ID section with edit mode toggle
- MenuBarView: Add connection toggle with colored button (green/red)
- Increase popover width from 260 to 300px
- Remove settings sheet and related UI code

**Bug fixes:**
- Fix NSStatusBar.shared reference to NSStatusBar.system
- Remove unused symbolEffect for pulse animation
- Remove default device ID, now empty by default

**Documentation:**
- Update README to reflect simplified configuration flow
- Add .gitignore to exclude build artifacts and user data

## 2026-01-29

### feat: 初始化 HypeRateOnMac 菜单栏应用

创建 macOS 菜单栏应用，用于实时显示 HypeRate 设备的心率数据。
