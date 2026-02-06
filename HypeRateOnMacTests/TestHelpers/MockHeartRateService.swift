import Foundation
import Combine
@testable import HypeRateOnMac

/// Mock implementation of HeartRateServiceProtocol for testing
class MockHeartRateService: HeartRateServiceProtocol, ObservableObject {

    // MARK: - Protocol Properties

    @Published var currentHeartRate: Int?
    @Published var connectionState: ConnectionState = .disconnected

    var currentHeartRatePublisher: Published<Int?>.Publisher { $currentHeartRate }
    var connectionStatePublisher: Published<ConnectionState>.Publisher { $connectionState }

    // MARK: - Test Tracking Properties

    var connectCalled = false
    var disconnectCalled = false
    var lastConnectDeviceId: String?

    // MARK: - Protocol Methods

    func connect(deviceId: String) {
        connectCalled = true
        lastConnectDeviceId = deviceId
        // Simulate connection state change
        DispatchQueue.main.async {
            self.connectionState = .connecting
        }
    }

    func disconnect() {
        disconnectCalled = true
        DispatchQueue.main.async {
            self.connectionState = .disconnected
            self.currentHeartRate = nil
        }
    }

    // MARK: - Test Helper Methods

    func reset() {
        connectCalled = false
        disconnectCalled = false
        lastConnectDeviceId = nil
        currentHeartRate = nil
        connectionState = .disconnected
    }

    func simulateHeartRateUpdate(_ heartRate: Int) {
        DispatchQueue.main.async {
            self.currentHeartRate = heartRate
        }
    }

    func simulateConnectionState(_ state: ConnectionState) {
        DispatchQueue.main.async {
            self.connectionState = state
        }
    }
}
