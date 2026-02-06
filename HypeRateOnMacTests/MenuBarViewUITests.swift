import XCTest
import SwiftUI
import Combine
@testable import HypeRateOnMac

final class MenuBarViewUITests: XCTestCase {

    var viewModel: HeartRateViewModel!
    var mockService: MockHeartRateService!

    override func setUp() {
        super.setUp()
        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: "hyperate_device_id")
        SettingsService.shared.deviceId = ""

        mockService = MockHeartRateService()
        viewModel = HeartRateViewModel(
            heartRateService: mockService,
            settingsService: .shared
        )
    }

    override func tearDown() {
        // Clean up
        UserDefaults.standard.removeObject(forKey: "hyperate_device_id")
        SettingsService.shared.deviceId = ""
        viewModel = nil
        mockService = nil
        super.tearDown()
    }

    // MARK: - UI State Tests

    func testViewCreationWithDifferentHeartRates() {
        // Test UI creation with various heart rate values
        let heartRates = [0, 50, 75, 100, 120, 150, 200]

        for hr in heartRates {
            // Given
            viewModel.currentHeartRate = hr

            // When
            let view = MenuBarView(viewModel: viewModel)

            // Then
            XCTAssertNotNil(view)
            XCTAssertEqual(view.viewModel.currentHeartRate, hr)
            XCTAssertEqual(view.viewModel.heartRateDisplay, "\(hr)")
        }
    }

    func testViewCreationWithAllConnectionStates() {
        // Given
        let states: [ConnectionState] = [
            .disconnected,
            .connecting,
            .connected,
            .error("Test error")
        ]

        for state in states {
            // When
            viewModel.connectionState = state
            let view = MenuBarView(viewModel: viewModel)

            // Then
            XCTAssertNotNil(view)
            XCTAssertEqual(view.viewModel.connectionState, state)
        }
    }

    func testHeartRateColorLogic() {
        // Test the statusColor (connection state color), not heart rate display color
        let testCases: [(ConnectionState, Int?, String)] = [
            (.connected, 80, AppColors.connected),      // Connected state
            (.connected, 110, AppColors.connected),     // Connected state
            (.connected, 130, AppColors.connected),     // Connected state
            (.connected, nil, AppColors.connected),     // Connected state
            (.connecting, nil, AppColors.connecting),   // Connecting: orange
            (.disconnected, nil, AppColors.disconnected), // Disconnected: gray
            (.error("test"), nil, AppColors.error)      // Error: red
        ]

        for (state, heartRate, expectedColor) in testCases {
            // When
            viewModel.connectionState = state
            viewModel.currentHeartRate = heartRate

            // Then
            let statusColor = viewModel.statusColor
            XCTAssertEqual(statusColor, expectedColor, "Failed for state: \(state), HR: \(String(describing: heartRate))")
        }
    }

    func testHeartRateDisplayLogicWithVariousStates() {
        // Test display logic combinations
        let combinations: [(ConnectionState, Int?, String)] = [
            (.connected, 75, "75"),
            (.connected, 0, "0"),
            (.connected, 999, "999"),
            (.connected, nil, "--"),
            (.connecting, 80, "80"),
            (.connecting, nil, "--"),
            (.disconnected, 70, "70"),
            (.disconnected, nil, "--"),
            (.error("test"), 90, "90"),
            (.error("test"), nil, "--")
        ]

        for (state, heartRate, expectedDisplay) in combinations {
            // When
            viewModel.connectionState = state
            viewModel.currentHeartRate = heartRate

            // Then
            XCTAssertEqual(viewModel.heartRateDisplay, expectedDisplay)
        }
    }

    // MARK: - Device ID UI Tests

    func testDeviceIdDisplayInView() {
        // Given
        let deviceIds = ["abc123", "xyz789", "", "test12"]

        for deviceId in deviceIds {
            // When
            viewModel.deviceId = deviceId
            let view = MenuBarView(viewModel: viewModel)

            // Then
            XCTAssertEqual(view.viewModel.deviceId, deviceId)
        }
    }

    func testDeviceIdUpdateValidation() {
        // Test valid IDs
        let validIds = ["abc123", "xyz", "ABC", "123456"]

        for id in validIds {
            // When
            let result = viewModel.updateDeviceId(id)

            // Then
            XCTAssertTrue(result, "'\(id)' should be valid")
        }
    }

    func testDeviceIdUpdateInvalidation() {
        // Test invalid IDs
        let invalidIds = ["ab", "abcdefg", "ab-123", ""]

        for id in invalidIds {
            // When
            let result = viewModel.updateDeviceId(id)

            // Then
            XCTAssertFalse(result, "'\(id)' should be invalid")
        }
    }

    // MARK: - Connection Toggle UI Tests

    func testIsConnectedPropertyInDifferentStates() {
        // Test all connection states
        let testCases: [(ConnectionState, Bool)] = [
            (.disconnected, false),
            (.connecting, false),
            (.connected, true),
            (.error("test"), false)
        ]

        for (state, expectedIsConnected) in testCases {
            // When
            viewModel.connectionState = state

            // Then
            XCTAssertEqual(viewModel.isConnected, expectedIsConnected)
        }
    }

    func testConnectionToggleFromDifferentStates() {
        // Given - Set device ID first
        viewModel.deviceId = "abc123"

        // Test from disconnected
        viewModel.connectionState = .disconnected
        viewModel.toggleConnection()
        XCTAssertTrue(mockService.connectCalled)

        // Reset
        mockService.connectCalled = false
        mockService.disconnectCalled = false

        // Test from connected
        viewModel.connectionState = .connected
        viewModel.toggleConnection()
        XCTAssertTrue(mockService.disconnectCalled)

        // Reset
        mockService.connectCalled = false
        mockService.disconnectCalled = false

        // Test from error
        viewModel.connectionState = .error("test")
        viewModel.toggleConnection()
        XCTAssertTrue(mockService.connectCalled)

        // Test from connecting - should not do anything
        mockService.connectCalled = false
        mockService.disconnectCalled = false
        viewModel.connectionState = .connecting
        viewModel.toggleConnection()
        XCTAssertFalse(mockService.connectCalled)
        XCTAssertFalse(mockService.disconnectCalled)
    }

    // MARK: - View Hierarchy Tests

    func testViewCreationDoesNotCrash() {
        // Test that view creation doesn't crash with various states
        let heartRates: [Int?] = [nil, 0, 75, 150, 999]
        let states: [ConnectionState] = [.disconnected, .connecting, .connected, .error("test")]
        let deviceIds = ["", "abc123"]

        for hr in heartRates {
            for state in states {
                for deviceId in deviceIds {
                    // When
                    viewModel.currentHeartRate = hr
                    viewModel.connectionState = state
                    viewModel.deviceId = deviceId

                    // Then - Should not crash
                    let view = MenuBarView(viewModel: viewModel)
                    XCTAssertNotNil(view)
                }
            }
        }
    }

    func testMultipleViewInstancesWithSameViewModel() {
        // Given
        viewModel.currentHeartRate = 80
        viewModel.connectionState = .connected

        // When - Create multiple views
        let view1 = MenuBarView(viewModel: viewModel)
        let view2 = MenuBarView(viewModel: viewModel)
        let view3 = MenuBarView(viewModel: viewModel)

        // Then - All should reference the same view model
        XCTAssertTrue(view1.viewModel === view2.viewModel)
        XCTAssertTrue(view2.viewModel === view3.viewModel)
    }

    // MARK: - Computed Properties Tests

    func testHeartRateDisplayWithEdgeCases() {
        // Given
        let testCases: [(Int?, String)] = [
            (nil, "--"),
            (0, "0"),
            (1, "1"),
            (-1, "-1"),
            (Int.max, "\(Int.max)"),
            (Int.min, "\(Int.min)")
        ]

        for (heartRate, expectedDisplay) in testCases {
            // When
            viewModel.currentHeartRate = heartRate

            // Then
            XCTAssertEqual(viewModel.heartRateDisplay, expectedDisplay)
        }
    }

    func testStatusColorForAllStates() {
        // Test that each state has a valid color
        let states: [ConnectionState] = [
            .disconnected,
            .connecting,
            .connected,
            .error("test1"),
            .error("test2"),
            .error("")
        ]

        for state in states {
            // When
            viewModel.connectionState = state

            // Then
            let color = viewModel.statusColor
            XCTAssertFalse(color.isEmpty)
            XCTAssertTrue(color.hasPrefix("#"))
        }
    }

    // MARK: - State Synchronization Tests

    func testHeartRateUpdateTriggersCallback() {
        // Given
        var callbackTriggered = false
        viewModel.onHeartRateChange = {
            callbackTriggered = true
        }

        // When
        mockService.currentHeartRate = 85
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        // Then
        XCTAssertTrue(callbackTriggered)
        XCTAssertEqual(viewModel.currentHeartRate, 85)
    }

    func testConnectionStateUpdatesSynchronously() {
        // Given
        let expectation = XCTestExpectation(description: "State updated")

        // When
        mockService.connectionState = .connected

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Then
            XCTAssertEqual(self.viewModel.connectionState, .connected)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Error State UI Tests

    func testErrorStateDisplay() {
        // Given
        let errorMessages = [
            "Network timeout",
            "Invalid device ID",
            "Connection refused",
            ""
        ]

        for errorMsg in errorMessages {
            // When
            viewModel.connectionState = .error(errorMsg)
            let view = MenuBarView(viewModel: viewModel)

            // Then
            XCTAssertNotNil(view)
            if case .error(let msg) = view.viewModel.connectionState {
                XCTAssertEqual(msg, errorMsg)
            } else {
                XCTFail("Expected error state")
            }
        }
    }

    // MARK: - Reconnect UI Tests

    func testReconnectCallsBothDisconnectAndConnect() {
        // Given
        viewModel.deviceId = "test123"
        mockService.connectCalled = false
        mockService.disconnectCalled = false

        // When
        viewModel.reconnect()

        // Then
        XCTAssertTrue(mockService.disconnectCalled)
        XCTAssertTrue(mockService.connectCalled)
    }

    // MARK: - Device ID Validation UI Feedback

    func testUpdateDeviceIdWithWhitespaceTrimsCorrectly() {
        // Given
        let idsWithWhitespace = [
            "  abc123  ",
            "\tabc123\t",
            "\nabc123\n",
            "  abc123"
        ]

        for id in idsWithWhitespace {
            // When
            let result = viewModel.updateDeviceId(id)

            // Then
            XCTAssertTrue(result)
            XCTAssertEqual(viewModel.deviceId, "abc123")
        }
    }

    func testUpdateDeviceIdRejectsInvalidFormats() {
        // Given
        let invalidIds = [
            "a",           // Too short
            "abcdefgh",    // Too long
            "abc-123",     // Invalid char
            "abc 123",     // Space
            "abc@123"      // Special char
        ]

        for id in invalidIds {
            // When
            let oldId = viewModel.deviceId
            let result = viewModel.updateDeviceId(id)

            // Then
            XCTAssertFalse(result, "'\(id)' should be rejected")
            XCTAssertEqual(viewModel.deviceId, oldId, "Device ID should not change")
        }
    }

    // MARK: - Integration Tests

    func testCompleteUIWorkflow() {
        // Simulate a complete user workflow

        // 1. Initial state
        XCTAssertEqual(viewModel.connectionState, .disconnected)
        XCTAssertNil(viewModel.currentHeartRate)

        // 2. Update device ID
        let updateResult = viewModel.updateDeviceId("abc123")
        XCTAssertTrue(updateResult)
        XCTAssertEqual(viewModel.deviceId, "abc123")

        // 3. Connect
        viewModel.connect()
        XCTAssertTrue(mockService.connectCalled)

        // 4. Simulate connection success with proper async handling
        let expectation1 = XCTestExpectation(description: "Connection state updated")
        mockService.simulateConnectionState(.connected)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 1.0)

        // 5. Simulate heart rate update with proper async handling
        let expectation2 = XCTestExpectation(description: "Heart rate updated")
        mockService.simulateHeartRateUpdate(75)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            expectation2.fulfill()
        }
        wait(for: [expectation2], timeout: 1.0)

        // 6. Verify UI state
        XCTAssertEqual(viewModel.heartRateDisplay, "75")
        XCTAssertEqual(viewModel.connectionState, .connected)
        XCTAssertTrue(viewModel.isConnected)

        // 7. Disconnect
        viewModel.disconnect()
        XCTAssertTrue(mockService.disconnectCalled)
    }

    func testViewStateConsistencyAfterMultipleUpdates() {
        // Given
        let view = MenuBarView(viewModel: viewModel)

        // When - Perform multiple state updates
        viewModel.deviceId = "test1"
        viewModel.connectionState = .connecting
        viewModel.currentHeartRate = 60

        viewModel.deviceId = "test2"
        viewModel.connectionState = .connected
        viewModel.currentHeartRate = 75

        viewModel.deviceId = "test3"
        viewModel.connectionState = .disconnected
        viewModel.currentHeartRate = nil

        // Then - View model should reflect final state
        XCTAssertEqual(view.viewModel.deviceId, "test3")
        XCTAssertEqual(view.viewModel.connectionState, .disconnected)
        XCTAssertNil(view.viewModel.currentHeartRate)
        XCTAssertEqual(view.viewModel.heartRateDisplay, "--")
    }
}
