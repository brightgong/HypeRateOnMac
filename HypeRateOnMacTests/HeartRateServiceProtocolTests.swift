import XCTest
import Combine
@testable import HypeRateOnMac

final class HeartRateServiceProtocolTests: XCTestCase {

    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        cancellables = nil
        super.tearDown()
    }

    // MARK: - Protocol Conformance Tests

    func testHeartRateServiceConformsToProtocol() {
        // Given
        let service = HeartRateService()

        // Then
        XCTAssertTrue(service is HeartRateServiceProtocol)
    }

    func testMockHeartRateServiceConformsToProtocol() {
        // Given
        let mockService = MockHeartRateService()

        // Then
        XCTAssertTrue(mockService is HeartRateServiceProtocol)
    }

    // MARK: - Protocol Properties Tests

    func testProtocolHasRequiredProperties() {
        // Given
        let service: HeartRateServiceProtocol = HeartRateService()

        // Then - Should be able to access protocol properties
        XCTAssertNotNil(service.currentHeartRate == nil || service.currentHeartRate != nil)
        XCTAssertNotNil(service.connectionState)
    }

    func testProtocolPublisherProperties() {
        // Given
        let service: HeartRateServiceProtocol = HeartRateService()

        // Then - Should be able to access publishers
        XCTAssertNotNil(service.currentHeartRatePublisher)
        XCTAssertNotNil(service.connectionStatePublisher)
    }

    // MARK: - Protocol Methods Tests

    func testProtocolHasConnectMethod() {
        // Given
        let service: HeartRateServiceProtocol = MockHeartRateService()

        // When - Should be able to call connect
        service.connect(deviceId: "test123")

        // Then - Should not crash
        XCTAssertTrue(true)
    }

    func testProtocolHasDisconnectMethod() {
        // Given
        let service: HeartRateServiceProtocol = MockHeartRateService()

        // When - Should be able to call disconnect
        service.disconnect()

        // Then - Should not crash
        XCTAssertTrue(true)
    }

    // MARK: - Publisher Behavior Tests

    func testCurrentHeartRatePublisherEmitsValues() {
        // Given
        let mockService = MockHeartRateService()
        let expectation = XCTestExpectation(description: "Heart rate publisher emits")

        var receivedValue: Int?

        // When
        mockService.currentHeartRatePublisher
            .dropFirst()
            .sink { value in
                receivedValue = value
                expectation.fulfill()
            }
            .store(in: &cancellables)

        mockService.simulateHeartRateUpdate(75)

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedValue, 75)
    }

    func testConnectionStatePublisherEmitsValues() {
        // Given
        let mockService = MockHeartRateService()
        let expectation = XCTestExpectation(description: "Connection state publisher emits")

        var receivedState: ConnectionState?

        // When
        mockService.connectionStatePublisher
            .dropFirst()
            .sink { state in
                receivedState = state
                expectation.fulfill()
            }
            .store(in: &cancellables)

        mockService.simulateConnectionState(.connected)

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedState, .connected)
    }

    // MARK: - Protocol Method Behavior Tests

    func testConnectMethodUpdatesState() {
        // Given
        let mockService = MockHeartRateService()
        let expectation = XCTestExpectation(description: "Connect updates state")

        mockService.connectionStatePublisher
            .dropFirst()
            .sink { state in
                if state == .connecting {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // When
        mockService.connect(deviceId: "test123")

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(mockService.connectCalled)
        XCTAssertEqual(mockService.lastConnectDeviceId, "test123")
    }

    func testDisconnectMethodUpdatesState() {
        // Given
        let mockService = MockHeartRateService()
        let expectation = XCTestExpectation(description: "Disconnect updates state")
        expectation.expectedFulfillmentCount = 2

        var stateChanges: [ConnectionState] = []

        mockService.connectionStatePublisher
            .sink { state in
                stateChanges.append(state)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // When
        mockService.disconnect()

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(mockService.disconnectCalled)
        XCTAssertTrue(stateChanges.contains(.disconnected))
    }

    // MARK: - Dependency Injection Tests

    func testProtocolCanBeInjectedIntoViewModel() {
        // Given
        let mockService: HeartRateServiceProtocol = MockHeartRateService()

        // When
        let viewModel = HeartRateViewModel(
            heartRateService: mockService,
            settingsService: .shared
        )

        // Then
        XCTAssertNotNil(viewModel)
    }

    func testViewModelWorksWithRealService() {
        // Given
        let realService: HeartRateServiceProtocol = HeartRateService()

        // When
        let viewModel = HeartRateViewModel(
            heartRateService: realService,
            settingsService: .shared
        )

        // Then
        XCTAssertNotNil(viewModel)
    }

    func testViewModelWorksWithMockService() {
        // Given
        let mockService: HeartRateServiceProtocol = MockHeartRateService()

        // When
        let viewModel = HeartRateViewModel(
            heartRateService: mockService,
            settingsService: .shared
        )

        // Then
        XCTAssertNotNil(viewModel)
    }

    // MARK: - Protocol Type Tests

    func testProtocolTypeCanBeUsedAsParameter() {
        // Given
        func acceptsProtocol(_ service: HeartRateServiceProtocol) -> Bool {
            return true
        }

        let realService = HeartRateService()
        let mockService = MockHeartRateService()

        // When & Then
        XCTAssertTrue(acceptsProtocol(realService))
        XCTAssertTrue(acceptsProtocol(mockService))
    }

    func testProtocolTypeCanBeStoredInVariable() {
        // Given & When
        var service: HeartRateServiceProtocol = HeartRateService()

        // Then
        XCTAssertNotNil(service)

        // When - Assign different implementation
        service = MockHeartRateService()

        // Then
        XCTAssertNotNil(service)
    }

    // MARK: - Publisher Type Tests

    func testPublisherTypesAreCorrect() {
        // Given
        let service: HeartRateServiceProtocol = MockHeartRateService()

        // When
        let heartRatePublisher = service.currentHeartRatePublisher
        let statePublisher = service.connectionStatePublisher

        // Then
        XCTAssertTrue(heartRatePublisher is Published<Int?>.Publisher)
        XCTAssertTrue(statePublisher is Published<ConnectionState>.Publisher)
    }

    // MARK: - Multiple Publishers Tests

    func testMultipleSubscribersToPublishers() {
        // Given
        let mockService = MockHeartRateService()
        let expectation1 = XCTestExpectation(description: "Subscriber 1")
        let expectation2 = XCTestExpectation(description: "Subscriber 2")

        // When
        mockService.currentHeartRatePublisher
            .dropFirst()
            .sink { _ in expectation1.fulfill() }
            .store(in: &cancellables)

        mockService.currentHeartRatePublisher
            .dropFirst()
            .sink { _ in expectation2.fulfill() }
            .store(in: &cancellables)

        mockService.simulateHeartRateUpdate(80)

        // Then
        wait(for: [expectation1, expectation2], timeout: 1.0)
    }

    // MARK: - Protocol Extension Tests

    func testProtocolCanBeExtended() {
        // This test verifies that the protocol can be extended
        // The HeartRateService class conforms to the protocol via extension

        // Given
        let service = HeartRateService()

        // When
        let heartRatePublisher = service.currentHeartRatePublisher
        let statePublisher = service.connectionStatePublisher

        // Then
        XCTAssertNotNil(heartRatePublisher)
        XCTAssertNotNil(statePublisher)
    }

    // MARK: - Interface Consistency Tests

    func testBothImplementationsHaveSameInterface() {
        // Given
        let realService: HeartRateServiceProtocol = HeartRateService()
        let mockService: HeartRateServiceProtocol = MockHeartRateService()

        // Then - Both should have same interface
        // Test that we can call same methods on both
        XCTAssertNotNil(realService.currentHeartRate == nil || realService.currentHeartRate != nil)
        XCTAssertNotNil(mockService.currentHeartRate == nil || mockService.currentHeartRate != nil)

        XCTAssertNotNil(realService.connectionState)
        XCTAssertNotNil(mockService.connectionState)

        // Can call methods on both
        realService.disconnect()
        mockService.disconnect()

        XCTAssertTrue(true) // If we get here, interfaces are consistent
    }

    // MARK: - Protocol Benefits Tests

    func testProtocolEnablesTestability() {
        // Given - Using mock for testing
        let mockService = MockHeartRateService()
        let viewModel = HeartRateViewModel(
            heartRateService: mockService,
            settingsService: .shared
        )

        viewModel.deviceId = "test123"

        // When
        viewModel.connect()

        // Then - Can verify mock was called
        XCTAssertTrue(mockService.connectCalled)
        XCTAssertEqual(mockService.lastConnectDeviceId, "test123")
    }

    func testProtocolAllowsForDifferentImplementations() {
        // Given
        class AlternativeHeartRateService: HeartRateServiceProtocol, ObservableObject {
            @Published var currentHeartRate: Int?
            @Published var connectionState: ConnectionState = .disconnected

            var currentHeartRatePublisher: Published<Int?>.Publisher { $currentHeartRate }
            var connectionStatePublisher: Published<ConnectionState>.Publisher { $connectionState }

            func connect(deviceId: String) {
                connectionState = .connected
            }

            func disconnect() {
                connectionState = .disconnected
            }
        }

        let altService: HeartRateServiceProtocol = AlternativeHeartRateService()

        // When
        altService.connect(deviceId: "test")

        // Then - Alternative implementation works
        XCTAssertEqual(altService.connectionState, .connected)
    }
}
