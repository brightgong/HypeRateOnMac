import Foundation
import Combine

class HeartRateViewModel: ObservableObject {
    @Published var currentHeartRate: Int?
    @Published var connectionState: ConnectionState = .disconnected
    @Published var deviceId: String = ""
    @Published var isSettingsPresented = false
    
    var onHeartRateChange: (() -> Void)?
    
    private let heartRateService: HeartRateServiceProtocol
    private let settingsService: SettingsService
    private var cancellables = Set<AnyCancellable>()
    
    init(heartRateService: HeartRateServiceProtocol = HeartRateService(),
         settingsService: SettingsService = .shared) {
        self.heartRateService = heartRateService
        self.settingsService = settingsService
        
        // 初始化 deviceId
        self.deviceId = settingsService.deviceId
        
        // 设置回调
        setupCallbacks()
        
        // 监听服务状态变化（如果是 ObservableObject）
        if let service = heartRateService as? HeartRateService {
            service.$currentHeartRate
                .receive(on: DispatchQueue.main)
                .sink { [weak self] heartRate in
                    self?.currentHeartRate = heartRate
                    self?.onHeartRateChange?()
                }
                .store(in: &cancellables)
            
            service.$connectionState
                .receive(on: DispatchQueue.main)
                .sink { [weak self] state in
                    self?.connectionState = state
                }
                .store(in: &cancellables)
        }
    }
    
    private func setupCallbacks() {
        heartRateService.onHeartRateUpdate = { [weak self] heartRate in
            DispatchQueue.main.async {
                self?.currentHeartRate = heartRate
                self?.onHeartRateChange?()
            }
        }
        
        heartRateService.onConnectionStateChange = { [weak self] state in
            DispatchQueue.main.async {
                self?.connectionState = state
            }
        }
    }
    
    func connect() {
        let id = settingsService.deviceId
        deviceId = id
        heartRateService.connect(deviceId: id)
    }
    
    func disconnect() {
        heartRateService.disconnect()
    }
    
    func reconnect() {
        disconnect()
        connect()
    }
    
    func updateDeviceId(_ newId: String) -> Bool {
        guard settingsService.updateDeviceId(newId) else {
            return false
        }
        deviceId = settingsService.deviceId
        reconnect()
        return true
    }
    
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
