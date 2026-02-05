import Foundation
import Combine

class HeartRateViewModel: ObservableObject {
    @Published var currentHeartRate: Int?
    @Published var connectionState: ConnectionState = .disconnected
    @Published var deviceId: String = ""
    @Published var deviceIdInput: String = ""

    var onHeartRateChange: (() -> Void)?

    private let heartRateService: HeartRateService
    private let settingsService: SettingsService
    private var cancellables = Set<AnyCancellable>()

    init(heartRateService: HeartRateService = HeartRateService(),
         settingsService: SettingsService = .shared) {
        self.heartRateService = heartRateService
        self.settingsService = settingsService

        // 初始化 deviceId
        self.deviceId = settingsService.deviceId
        self.deviceIdInput = settingsService.deviceId

        // 监听设置变化
        settingsService.$deviceId
            .receive(on: DispatchQueue.main)
            .assign(to: &$deviceId)

        // 监听服务状态变化
        heartRateService.$currentHeartRate
            .receive(on: DispatchQueue.main)
            .sink { [weak self] heartRate in
                self?.currentHeartRate = heartRate
                self?.onHeartRateChange?()
            }
            .store(in: &cancellables)

        heartRateService.$connectionState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.connectionState = state
            }
            .store(in: &cancellables)
    }

    // MARK: - Connection

    func connect() {
        // 检查是否已配置
        guard !deviceId.isEmpty else {
            connectionState = .error("请输入设备 ID")
            return
        }

        heartRateService.connect(deviceId: deviceId)
    }

    func disconnect() {
        heartRateService.disconnect()
    }

    func toggleConnection() {
        switch connectionState {
        case .connected:
            disconnect()
        case .disconnected, .error:
            connect()
        default:
            break
        }
    }

    func reconnect() {
        disconnect()
        connect()
    }

    // MARK: - Settings Updates

    func updateDeviceId(_ newId: String) -> Bool {
        let trimmedId = newId.trimmingCharacters(in: .whitespacesAndNewlines)

        // 验证设备 ID 格式
        let pattern = "^[a-zA-Z0-9]{3,6}$"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: trimmedId.utf16.count)
        guard regex?.firstMatch(in: trimmedId, options: [], range: range) != nil else {
            return false
        }

        guard settingsService.updateDeviceId(trimmedId) else {
            return false
        }
        deviceId = settingsService.deviceId
        deviceIdInput = settingsService.deviceId
        return true
    }

    // MARK: - Computed Properties

    var heartRateDisplay: String {
        if let heartRate = currentHeartRate {
            return "\(heartRate)"
        } else {
            return "--"
        }
    }

    var statusColor: String {
        connectionState.color
    }

    var isConnected: Bool {
        connectionState == .connected
    }
}
