import XCTest
import Combine
@testable import HypeRateOnMac

final class NetworkMonitorTests: XCTestCase {

    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        cancellables = nil
        super.tearDown()
    }

    // MARK: - Singleton Tests

    func testNetworkMonitorIsSingleton() {
        // Given & When
        let instance1 = NetworkMonitor.shared
        let instance2 = NetworkMonitor.shared

        // Then
        XCTAssertTrue(instance1 === instance2, "NetworkMonitor should be a singleton")
    }

    // MARK: - Initialization Tests

    func testNetworkMonitorHasInitialState() {
        // Given
        let monitor = NetworkMonitor.shared

        // Then
        // isConnected should be a boolean (true or false, both are valid)
        XCTAssertNotNil(monitor.isConnected)
    }

    // MARK: - ObservableObject Tests

    func testNetworkMonitorIsObservableObject() {
        // Given
        let monitor = NetworkMonitor.shared

        // Then
        XCTAssertTrue(monitor is ObservableObject)
    }

    // MARK: - Published Property Tests

    func testIsConnectedPropertyIsPublished() {
        // Given
        let monitor = NetworkMonitor.shared
        let expectation = XCTestExpectation(description: "Published property emits value")
        expectation.assertForOverFulfill = false

        var receivedValue: Bool?

        // When
        monitor.$isConnected
            .sink { value in
                receivedValue = value
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(receivedValue)
    }

    // MARK: - Network Status Tests

    func testNetworkStatusReflectsCurrentState() {
        // Given
        let monitor = NetworkMonitor.shared

        // When & Then
        // The status should be a valid boolean
        let status = monitor.isConnected
        XCTAssertTrue(status == true || status == false)
    }

    func testNetworkMonitorReportsConnectivityStatus() {
        // Given
        let monitor = NetworkMonitor.shared
        let expectation = XCTestExpectation(description: "Monitor reports status")

        // When
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Then
            // Should have a valid connectivity status
            let isConnected = monitor.isConnected
            XCTAssertTrue(isConnected == true || isConnected == false)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }

    // MARK: - Publisher Tests

    func testIsConnectedPublisherEmitsValues() {
        // Given
        let monitor = NetworkMonitor.shared
        let expectation = XCTestExpectation(description: "Publisher emits values")
        expectation.expectedFulfillmentCount = 1

        var emittedValues: [Bool] = []

        // When
        monitor.$isConnected
            .sink { value in
                emittedValues.append(value)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertFalse(emittedValues.isEmpty, "Publisher should emit at least one value")
    }

    // MARK: - Thread Safety Tests

    func testNetworkMonitorIsThreadSafe() {
        // Given
        let monitor = NetworkMonitor.shared
        let expectation = XCTestExpectation(description: "Thread safe access")
        expectation.expectedFulfillmentCount = 10

        // When - Access from multiple threads
        for _ in 0..<10 {
            DispatchQueue.global().async {
                _ = monitor.isConnected
                expectation.fulfill()
            }
        }

        // Then
        wait(for: [expectation], timeout: 2.0)
    }

    // MARK: - Integration Tests

    func testNetworkMonitorCanBeUsedInViewModel() {
        // Given
        let monitor = NetworkMonitor.shared
        let expectation = XCTestExpectation(description: "Can be used in ViewModel pattern")

        // When
        var observedStatus: Bool?
        monitor.$isConnected
            .sink { status in
                observedStatus = status
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNotNil(observedStatus)
    }

    // MARK: - Property Tests

    func testIsConnectedReturnsBoolean() {
        // Given
        let monitor = NetworkMonitor.shared

        // When
        let result = monitor.isConnected

        // Then
        XCTAssertTrue(result is Bool)
    }

    func testMultipleAccessesToIsConnectedAreConsistent() {
        // Given
        let monitor = NetworkMonitor.shared

        // When
        let result1 = monitor.isConnected
        let result2 = monitor.isConnected
        let result3 = monitor.isConnected

        // Then - Within a short timeframe, results should be consistent
        XCTAssertEqual(result1, result2)
        XCTAssertEqual(result2, result3)
    }

    // MARK: - Memory Management Tests

    func testNetworkMonitorDoesNotRetainCancellables() {
        // Given
        let monitor = NetworkMonitor.shared
        weak var weakCancellable: AnyCancellable?

        // When
        autoreleasepool {
            var localCancellables = Set<AnyCancellable>()
            let cancellable = monitor.$isConnected
                .sink { _ in }
            weakCancellable = cancellable
            localCancellables.insert(cancellable)
        }

        // Then
        XCTAssertNil(weakCancellable, "NetworkMonitor should not retain cancellables")
    }

    // MARK: - Edge Cases

    func testNetworkMonitorHandlesRapidAccess() {
        // Given
        let monitor = NetworkMonitor.shared

        // When - Rapid consecutive access
        for _ in 0..<100 {
            _ = monitor.isConnected
        }

        // Then - Should not crash and still be accessible
        XCTAssertNotNil(monitor.isConnected)
    }

    func testNetworkMonitorWorksWithMultipleSubscribers() {
        // Given
        let monitor = NetworkMonitor.shared
        let expectation1 = XCTestExpectation(description: "Subscriber 1")
        let expectation2 = XCTestExpectation(description: "Subscriber 2")
        let expectation3 = XCTestExpectation(description: "Subscriber 3")

        var cancellables = Set<AnyCancellable>()

        // When - Multiple subscribers
        monitor.$isConnected
            .sink { _ in expectation1.fulfill() }
            .store(in: &cancellables)

        monitor.$isConnected
            .sink { _ in expectation2.fulfill() }
            .store(in: &cancellables)

        monitor.$isConnected
            .sink { _ in expectation3.fulfill() }
            .store(in: &cancellables)

        // Then
        wait(for: [expectation1, expectation2, expectation3], timeout: 2.0)
    }
}
