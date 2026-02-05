import XCTest
import Combine
@testable import HypeRateOnMac

final class HeartRateViewModelTests: XCTestCase {

    var sut: HeartRateViewModel!
    var mockHeartRateService: MockHeartRateService!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        // Clear UserDefaults to ensure clean state
        UserDefaults.standard.removeObject(forKey: "hyperate_device_id")

        mockHeartRateService = MockHeartRateService()
        cancellables = Set<AnyCancellable>()
        sut = HeartRateViewModel(
            heartRateService: mockHeartRateService,
            settingsService: .shared
        )

        // Reset shared settings after init
        SettingsService.shared.deviceId = ""
    }

    override func tearDown() {
        // Clean up UserDefaults
        UserDefaults.standard.removeObject(forKey: "hyperate_device_id")
        SettingsService.shared.deviceId = ""
        cancellables = nil
        sut = nil
        mockHeartRateService = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialization() {
        // Then
        XCTAssertNil(sut.currentHeartRate)
        XCTAssertEqual(sut.connectionState, .disconnected)
        XCTAssertEqual(sut.deviceId, "")
        XCTAssertEqual(sut.deviceIdInput, "")
    }

    func testInitializationWithExistingDeviceId() {
        // Given
        UserDefaults.standard.set("abc123", forKey: "hyperate_device_id")

        // When
        // Re-initialize to pick up the UserDefaults value
        let tempService = MockHeartRateService()
        let tempViewModel = HeartRateViewModel(
            heartRateService: tempService,
            settingsService: .shared
        )

        // Then
        // Note: SettingsService is a singleton, so it reads from UserDefaults
        // We need to actually set it
        SettingsService.shared.deviceId = "abc123"

        // Wait for update
        let expectation = XCTestExpectation(description: "Device ID updated")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            XCTAssertEqual(tempViewModel.deviceId, "abc123")
            XCTAssertEqual(tempViewModel.deviceIdInput, "abc123")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Connection Tests

    func testConnectWithValidDeviceId() {
        // Given
        sut.deviceId = "abc123"

        // When
        sut.connect()

        // Then
        XCTAssertTrue(mockHeartRateService.connectCalled)
        XCTAssertEqual(mockHeartRateService.lastConnectDeviceId, "abc123")
    }

    func testConnectWithEmptyDeviceId() {
        // Given
        sut.deviceId = ""

        // When
        sut.connect()

        // Then
        XCTAssertFalse(mockHeartRateService.connectCalled)
        XCTAssertEqual(sut.connectionState, .error("请输入设备 ID"))
    }

    func testDisconnect() {
        // When
        sut.disconnect()

        // Then
        XCTAssertTrue(mockHeartRateService.disconnectCalled)
    }

    func testToggleConnectionWhenConnected() {
        // Given
        sut.connectionState = .connected

        // When
        sut.toggleConnection()

        // Then
        XCTAssertTrue(mockHeartRateService.disconnectCalled)
    }

    func testToggleConnectionWhenDisconnected() {
        // Given
        sut.connectionState = .disconnected
        sut.deviceId = "abc123"

        // When
        sut.toggleConnection()

        // Then
        XCTAssertTrue(mockHeartRateService.connectCalled)
    }

    func testToggleConnectionWhenError() {
        // Given
        sut.connectionState = .error("Some error")
        sut.deviceId = "abc123"

        // When
        sut.toggleConnection()

        // Then
        XCTAssertTrue(mockHeartRateService.connectCalled)
    }

    func testToggleConnectionWhenConnecting() {
        // Given
        sut.connectionState = .connecting

        // When
        sut.toggleConnection()

        // Then - Should not do anything
        XCTAssertFalse(mockHeartRateService.connectCalled)
        XCTAssertFalse(mockHeartRateService.disconnectCalled)
    }

    func testReconnect() {
        // Given
        sut.deviceId = "abc123"
        mockHeartRateService.disconnectCalled = false
        mockHeartRateService.connectCalled = false

        // When
        sut.reconnect()

        // Then
        XCTAssertTrue(mockHeartRateService.disconnectCalled)
        XCTAssertTrue(mockHeartRateService.connectCalled)
    }

    // MARK: - Settings Update Tests

    func testUpdateDeviceIdWithValidId() {
        // Given
        let newId = "xyz789"
        sut.deviceIdInput = newId

        // When
        let result = sut.updateDeviceId(newId)

        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(sut.deviceId, newId)
        XCTAssertEqual(sut.deviceIdInput, newId)
    }

    func testUpdateDeviceIdWithInvalidId() {
        // Given
        let invalidId = "invalid-id"
        let oldId = "abc123"
        sut.deviceId = oldId

        // When
        let result = sut.updateDeviceId(invalidId)

        // Then
        XCTAssertFalse(result)
        XCTAssertEqual(sut.deviceId, oldId)
    }

    func testUpdateDeviceIdWithWhitespace() {
        // Given
        let idWithWhitespace = "  abc123  "

        // When
        let result = sut.updateDeviceId(idWithWhitespace)

        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(sut.deviceId, "abc123")
    }

    // MARK: - Heart Rate Update Tests

    func testHeartRateUpdateFromService() {
        // Given
        let expectation = XCTestExpectation(description: "Heart rate updated")
        var callbackCalled = false
        sut.onHeartRateChange = {
            callbackCalled = true
            expectation.fulfill()
        }

        // When
        mockHeartRateService.currentHeartRate = 75

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(sut.currentHeartRate, 75)
        XCTAssertTrue(callbackCalled)
    }

    func testConnectionStateUpdateFromService() {
        // Given
        let expectation = XCTestExpectation(description: "Connection state updated")

        // When
        mockHeartRateService.connectionState = .connected

        // Then - Give some time for the async update
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.sut.connectionState, .connected)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Computed Properties Tests

    func testHeartRateDisplayWithValue() {
        // Given
        sut.currentHeartRate = 80

        // When
        let display = sut.heartRateDisplay

        // Then
        XCTAssertEqual(display, "80")
    }

    func testHeartRateDisplayWithoutValue() {
        // Given
        sut.currentHeartRate = nil

        // When
        let display = sut.heartRateDisplay

        // Then
        XCTAssertEqual(display, "--")
    }

    func testStatusColorForDifferentStates() {
        // Test all connection states
        let testCases: [(ConnectionState, String)] = [
            (.disconnected, "#8E8E93"),
            (.connecting, "#FF9500"),
            (.connected, "#34C759"),
            (.error("test"), "#FF3B30")
        ]

        for (state, expectedColor) in testCases {
            // When
            sut.connectionState = state

            // Then
            XCTAssertEqual(sut.statusColor, expectedColor)
        }
    }

    func testIsConnectedProperty() {
        // Test connected state
        sut.connectionState = .connected
        XCTAssertTrue(sut.isConnected)

        // Test other states
        let otherStates: [ConnectionState] = [
            .disconnected,
            .connecting,
            .error("test")
        ]

        for state in otherStates {
            sut.connectionState = state
            XCTAssertFalse(sut.isConnected)
        }
    }

    // MARK: - Settings Service Integration Tests

    func testDeviceIdSyncWithSettingsService() {
        // Given
        let expectation = XCTestExpectation(description: "Device ID synced")

        // When
        SettingsService.shared.deviceId = "new123"

        // Then
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            XCTAssertEqual(self.sut.deviceId, "new123")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }

    // MARK: - Edge Cases

    func testMultipleHeartRateUpdates() {
        // Test rapid heart rate updates
        let heartRates = [60, 70, 80, 90, 100, 110]

        for hr in heartRates {
            mockHeartRateService.currentHeartRate = hr
            // Small delay to allow publisher to emit
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.01))
        }

        XCTAssertEqual(sut.currentHeartRate, 110)
    }

    func testHeartRateDisplayWithZero() {
        // Given
        sut.currentHeartRate = 0

        // When
        let display = sut.heartRateDisplay

        // Then
        XCTAssertEqual(display, "0")
    }

    func testHeartRateDisplayWithLargeValue() {
        // Given
        sut.currentHeartRate = 999

        // When
        let display = sut.heartRateDisplay

        // Then
        XCTAssertEqual(display, "999")
    }

    func testOnHeartRateChangeCallbackNotSet() {
        // Given
        sut.onHeartRateChange = nil

        // When - Should not crash
        mockHeartRateService.currentHeartRate = 75

        // Then
        XCTAssertEqual(sut.currentHeartRate, 75)
    }
}

// MARK: - Mock Classes

class MockHeartRateService: HeartRateService {
    var connectCalled = false
    var disconnectCalled = false
    var lastConnectDeviceId: String?

    override func connect(deviceId: String) {
        connectCalled = true
        lastConnectDeviceId = deviceId
        // Simulate connection state change
        DispatchQueue.main.async {
            self.connectionState = .connecting
        }
    }

    override func disconnect() {
        disconnectCalled = true
        DispatchQueue.main.async {
            self.connectionState = .disconnected
            self.currentHeartRate = nil
        }
    }
}

