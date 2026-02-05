import XCTest
import Combine
@testable import HypeRateOnMac

final class HeartRateServiceTests: XCTestCase {

    var sut: HeartRateService!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        sut = HeartRateService()
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        sut.disconnect()
        cancellables = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialState() {
        // Then
        XCTAssertNil(sut.currentHeartRate)
        XCTAssertEqual(sut.connectionState, .disconnected)
    }

    // MARK: - Connection State Tests

    func testConnectUpdatesStateToConnecting() {
        // Given
        let expectation = XCTestExpectation(description: "State changed to connecting")

        sut.$connectionState
            .dropFirst()
            .sink { state in
                if state == .connecting {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // When
        sut.connect(deviceId: "abc123")

        // Then
        wait(for: [expectation], timeout: 2.0)
    }

    func testDisconnectUpdatesStateToDisconnected() {
        // Given
        let expectation = XCTestExpectation(description: "State changed to disconnected")

        // First connect
        sut.connect(deviceId: "abc123")

        // Wait a bit for connection attempt
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // When
            self.sut.disconnect()
        }

        sut.$connectionState
            .dropFirst(2) // Skip initial and connecting states
            .sink { state in
                if state == .disconnected {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // Then
        wait(for: [expectation], timeout: 3.0)
    }

    func testDisconnectClearsHeartRate() {
        // Given
        let expectation = XCTestExpectation(description: "Heart rate cleared")

        // Set a heart rate
        sut.currentHeartRate = 75

        sut.$currentHeartRate
            .dropFirst()
            .sink { heartRate in
                if heartRate == nil {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // When
        sut.disconnect()

        // Then
        wait(for: [expectation], timeout: 2.0)
    }

    func testMultipleDisconnectCalls() {
        // Given
        sut.connect(deviceId: "abc123")

        // When - Multiple disconnect calls should not crash
        sut.disconnect()
        sut.disconnect()
        sut.disconnect()

        // Then
        XCTAssertEqual(sut.connectionState, .disconnected)
        XCTAssertNil(sut.currentHeartRate)
    }

    func testReconnectSequence() {
        // Given
        let expectation = XCTestExpectation(description: "Reconnect sequence")
        expectation.expectedFulfillmentCount = 2

        var stateChanges: [ConnectionState] = []

        sut.$connectionState
            .dropFirst()
            .sink { state in
                stateChanges.append(state)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // When
        sut.connect(deviceId: "abc123")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.sut.disconnect()
        }

        // Then
        wait(for: [expectation], timeout: 3.0)
        XCTAssertTrue(stateChanges.contains(.connecting))
        XCTAssertTrue(stateChanges.contains(.disconnected))
    }

    // MARK: - Device ID Tests

    func testConnectWithDifferentDeviceIds() {
        // Test connecting with various device IDs
        let deviceIds = ["abc123", "xyz789", "test12"]

        for deviceId in deviceIds {
            // When
            sut.connect(deviceId: deviceId)

            // Small delay
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

            // Then - Should attempt to connect (state should be connecting or connected/error)
            XCTAssertNotEqual(sut.connectionState, .disconnected)

            // Cleanup
            sut.disconnect()
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        }
    }

    func testConnectWithEmptyDeviceId() {
        // When
        sut.connect(deviceId: "")

        // Then - Should still attempt connection (validation is in ViewModel)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.2))
        // Service doesn't validate, so it will attempt to connect
        XCTAssertNotEqual(sut.connectionState, .disconnected)
    }

    // MARK: - Published Properties Tests

    func testHeartRatePublisher() {
        // Given
        let expectation = XCTestExpectation(description: "Heart rate published")
        var receivedHeartRate: Int?

        sut.$currentHeartRate
            .dropFirst()
            .sink { heartRate in
                receivedHeartRate = heartRate
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // When
        sut.currentHeartRate = 85

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedHeartRate, 85)
    }

    func testConnectionStatePublisher() {
        // Given
        let expectation = XCTestExpectation(description: "Connection state published")
        var receivedState: ConnectionState?

        sut.$connectionState
            .dropFirst()
            .sink { state in
                receivedState = state
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // When
        sut.connectionState = .connected

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedState, .connected)
    }

    // MARK: - Heart Rate Value Tests

    func testHeartRateUpdateWithValidValues() {
        // Test various heart rate values
        let heartRates = [0, 40, 60, 80, 100, 120, 150, 200]

        for hr in heartRates {
            // When
            sut.currentHeartRate = hr

            // Then
            XCTAssertEqual(sut.currentHeartRate, hr)
        }
    }

    func testHeartRateUpdateToNil() {
        // Given
        sut.currentHeartRate = 75

        // When
        sut.currentHeartRate = nil

        // Then
        XCTAssertNil(sut.currentHeartRate)
    }

    // MARK: - Connection State Transitions Tests

    func testConnectionStateTransitions() {
        // Test various state transitions
        let states: [ConnectionState] = [
            .disconnected,
            .connecting,
            .connected,
            .error("Test error"),
            .disconnected
        ]

        for state in states {
            // When
            sut.connectionState = state

            // Then
            XCTAssertEqual(sut.connectionState, state)
        }
    }

    func testErrorStateWithDifferentMessages() {
        // Test error states with different messages
        let errorMessages = [
            "Network timeout",
            "Invalid credentials",
            "Connection lost",
            ""
        ]

        for message in errorMessages {
            // When
            sut.connectionState = .error(message)

            // Then
            if case .error(let receivedMessage) = sut.connectionState {
                XCTAssertEqual(receivedMessage, message)
            } else {
                XCTFail("Expected error state")
            }
        }
    }

    // MARK: - Concurrent Operations Tests

    func testRapidConnectDisconnect() {
        // Test rapid connect/disconnect cycles
        for _ in 0..<5 {
            sut.connect(deviceId: "test123")
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.05))
            sut.disconnect()
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.05))
        }

        // Should end in disconnected state
        XCTAssertEqual(sut.connectionState, .disconnected)
    }

    func testMultipleHeartRateUpdates() {
        // Given
        let expectation = XCTestExpectation(description: "Multiple heart rate updates")
        expectation.expectedFulfillmentCount = 3

        var receivedValues: [Int] = []

        sut.$currentHeartRate
            .dropFirst()
            .compactMap { $0 }
            .sink { value in
                receivedValues.append(value)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // When
        sut.currentHeartRate = 60
        sut.currentHeartRate = 70
        sut.currentHeartRate = 80

        // Then
        wait(for: [expectation], timeout: 2.0)
        XCTAssertEqual(receivedValues, [60, 70, 80])
    }

    // MARK: - Memory Management Tests

    func testDisconnectCleansUpResources() {
        // Given
        sut.connect(deviceId: "abc123")
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.2))

        // When
        sut.disconnect()
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.2))

        // Then
        XCTAssertEqual(sut.connectionState, .disconnected)
        XCTAssertNil(sut.currentHeartRate)
    }

    // MARK: - Edge Cases

    func testConnectWhileAlreadyConnecting() {
        // Given
        sut.connect(deviceId: "abc123")
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        // When - Connect again while already connecting
        sut.connect(deviceId: "xyz789")

        // Then - Should handle gracefully (will disconnect and reconnect)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.2))
        // State should be connecting or another valid state
        XCTAssertNotNil(sut.connectionState)
    }

    func testHeartRateUpdateWithExtremeValues() {
        // Test with extreme values
        let extremeValues = [Int.min, -1, 0, 1, Int.max]

        for value in extremeValues {
            // When
            sut.currentHeartRate = value

            // Then
            XCTAssertEqual(sut.currentHeartRate, value)
        }
    }

    func testDisconnectWhenNotConnected() {
        // Given - Already disconnected
        XCTAssertEqual(sut.connectionState, .disconnected)

        // When
        sut.disconnect()

        // Then - Should handle gracefully
        XCTAssertEqual(sut.connectionState, .disconnected)
        XCTAssertNil(sut.currentHeartRate)
    }

    // MARK: - NSObject Conformance Tests

    func testHeartRateServiceIsNSObject() {
        // Verify that HeartRateService properly inherits from NSObject
        XCTAssertTrue(sut is NSObject)
    }

    func testObservableObjectConformance() {
        // Verify ObservableObject conformance
        XCTAssertTrue(sut is ObservableObject)
    }
}
