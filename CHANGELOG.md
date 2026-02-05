# 开发日志

## 2026-02-05

### refactor: Localization and MenuBar state synchronization

**Localization:**
- Replace all Chinese text in source code with English equivalents
- Update log messages in HeartRateService.swift to English
- Update ConnectionState descriptions to English
- Update all UI text strings in MenuBarView.swift to English
- Update comments and error messages across all Swift files

**Bug fixes:**
- Fix MenuBar icon state not updating when connection state changes
- Add Combine observer for connectionState in MenuBarManager
- MenuBar icon now updates immediately on state changes (connecting, connected, disconnected, error)
- MenuBar display now stays synchronized with UI at all times

**Technical changes:**
- Import Combine framework in MenuBarManager
- Add cancellables property to store subscriptions
- Subscribe to viewModel.$connectionState publisher
- Call updateDisplay() on both heart rate and connection state changes

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
