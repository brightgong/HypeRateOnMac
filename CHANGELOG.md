# 开发日志

## 2026-02-06

### refactor: Major code quality improvements and comprehensive test coverage

#### Code Structure

**Remove dead code:**
- Delete unused `HeartRateData` struct - heart rate is now stored directly as `Int?`
- Remove unused `deviceIdInput` property from HeartRateViewModel

**Centralize color management:**
- Create `AppColors` enum to manage all color constants in one place
- Consolidate connection state colors (connected, connecting, disconnected, error)
- Consolidate heart rate colors (normal <100, elevated 100-120, high >120)
- Update `ConnectionState`, `MenuBarView`, and tests to use `AppColors`

**Improve architecture for testability:**
- Create `HeartRateServiceProtocol` to enable dependency injection
- Add protocol publishers: `currentHeartRatePublisher`, `connectionStatePublisher`
- Update `HeartRateViewModel` to depend on protocol instead of concrete class
- Enables easy mocking in unit tests

#### Service Layer

**Replace print statements with OSLog:**
- Replace 30+ print statements with proper logging framework
- Add `Logger` with subsystem "com.hyperate.HypeRateOnMac"
- Use appropriate log levels (debug, info, warning, error)
- Remove custom `timestampFormatter` and `logTimestamp()` methods
- Production builds automatically filter debug logs

**Add network connectivity monitoring:**
- Create `NetworkMonitor` singleton using `NWPathMonitor`
- Check network status before attempting connection
- Show "No network connection" error when offline

**Enhance error handling:**
- Add user feedback when JSON parsing fails
- Set connection state to "Data format error" on parse failures
- Trigger automatic reconnection on parse errors

**Fix thread safety issues:**
- Move `scheduleReconnect()` state checks to main thread
- Prevent race conditions in `connectionState` reads/writes
- Prevent multiple simultaneous reconnection attempts

#### Testing

**Add new test suites:**
- `AppColorsTests.swift` (18 tests) - validates color constants
- `NetworkMonitorTests.swift` (14 tests) - tests network monitoring
- `HeartRateServiceProtocolTests.swift` (21 tests) - validates protocol conformance
- `MockHeartRateService.swift` - protocol-based mock for testing

**Update existing tests:**
- Update tests to use `AppColors` instead of hardcoded hex values
- Remove `deviceIdInput` references from ViewModel tests
- Fix async timing issues in UI workflow tests
- Fix singleton state isolation in Settings tests
- Simplify network tests to avoid real WebSocket connections

**Remove obsolete tests:**
- Delete `HeartRateDataTests.swift` - tests deleted struct

**Test results:**
- 201 tests, 100% pass rate (was 182/201 passing)
- Execution time: 7.22 seconds
- Code coverage: 43.07% overall, 78.29% for HeartRateService

#### File Changes

**New files (+3):**
- `HypeRateOnMac/Utilities/AppColors.swift`
- `HypeRateOnMac/Services/HeartRateServiceProtocol.swift`
- `HypeRateOnMac/Services/NetworkMonitor.swift`

**Modified files (5):**
- `HypeRateOnMac/Models/HeartRateData.swift` - use AppColors
- `HypeRateOnMac/Services/HeartRateService.swift` - add OSLog, network check, fix thread safety
- `HypeRateOnMac/ViewModels/HeartRateViewModel.swift` - use protocol dependency
- `HypeRateOnMac/Views/MenuBarView.swift` - use AppColors
- 7 test files - updates for new architecture

**Deleted files (-14):**
- Project backup files, unused mocks, system files, temporary logs

#### Breaking Changes
None - all changes are internal refactoring

#### Migration
No migration needed - existing functionality preserved

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
