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

        // Initialize deviceId
        self.deviceId = settingsService.deviceId
        self.deviceIdInput = settingsService.deviceId

        // Listen to settings changes
        settingsService.$deviceId
            .receive(on: DispatchQueue.main)
            .assign(to: &$deviceId)

        // Listen to service state changes
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
        // Check if configured
        guard !deviceId.isEmpty else {
            connectionState = .error("Please enter device ID")
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

        // Use SettingsService validation and update logic
        guard settingsService.updateDeviceId(trimmedId) else {
            return false
        }

        // Sync state
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
