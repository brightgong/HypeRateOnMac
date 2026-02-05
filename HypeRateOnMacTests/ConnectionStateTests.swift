import XCTest
@testable import HypeRateOnMac

final class ConnectionStateTests: XCTestCase {

    // MARK: - Description Tests

    func testDisconnectedDescription() {
        // Given
        let state = ConnectionState.disconnected

        // When & Then
        XCTAssertEqual(state.description, "已断开")
    }

    func testConnectingDescription() {
        // Given
        let state = ConnectionState.connecting

        // When & Then
        XCTAssertEqual(state.description, "连接中...")
    }

    func testConnectedDescription() {
        // Given
        let state = ConnectionState.connected

        // When & Then
        XCTAssertEqual(state.description, "已连接")
    }

    func testErrorDescription() {
        // Given
        let errorMessage = "网络连接失败"
        let state = ConnectionState.error(errorMessage)

        // When & Then
        XCTAssertEqual(state.description, "错误: 网络连接失败")
    }

    func testErrorDescriptionWithEmptyMessage() {
        // Given
        let state = ConnectionState.error("")

        // When & Then
        XCTAssertEqual(state.description, "错误: ")
    }

    // MARK: - Color Tests

    func testDisconnectedColor() {
        // Given
        let state = ConnectionState.disconnected

        // When & Then
        XCTAssertEqual(state.color, "#8E8E93")
    }

    func testConnectingColor() {
        // Given
        let state = ConnectionState.connecting

        // When & Then
        XCTAssertEqual(state.color, "#FF9500")
    }

    func testConnectedColor() {
        // Given
        let state = ConnectionState.connected

        // When & Then
        XCTAssertEqual(state.color, "#34C759")
    }

    func testErrorColor() {
        // Given
        let state = ConnectionState.error("Some error")

        // When & Then
        XCTAssertEqual(state.color, "#FF3B30")
    }

    // MARK: - Equatable Tests

    func testDisconnectedEquality() {
        // Given
        let state1 = ConnectionState.disconnected
        let state2 = ConnectionState.disconnected

        // When & Then
        XCTAssertEqual(state1, state2)
    }

    func testConnectingEquality() {
        // Given
        let state1 = ConnectionState.connecting
        let state2 = ConnectionState.connecting

        // When & Then
        XCTAssertEqual(state1, state2)
    }

    func testConnectedEquality() {
        // Given
        let state1 = ConnectionState.connected
        let state2 = ConnectionState.connected

        // When & Then
        XCTAssertEqual(state1, state2)
    }

    func testErrorEquality() {
        // Given
        let state1 = ConnectionState.error("Error 1")
        let state2 = ConnectionState.error("Error 1")

        // When & Then
        XCTAssertEqual(state1, state2)
    }

    func testErrorInequality() {
        // Given
        let state1 = ConnectionState.error("Error 1")
        let state2 = ConnectionState.error("Error 2")

        // When & Then
        XCTAssertNotEqual(state1, state2)
    }

    func testDifferentStatesInequality() {
        // Given
        let states = [
            ConnectionState.disconnected,
            ConnectionState.connecting,
            ConnectionState.connected,
            ConnectionState.error("Error")
        ]

        // When & Then
        for i in 0..<states.count {
            for j in 0..<states.count where i != j {
                XCTAssertNotEqual(states[i], states[j], "State \(i) should not equal state \(j)")
            }
        }
    }

    // MARK: - Edge Cases

    func testMultipleErrorStatesWithDifferentMessages() {
        // Test that different error messages create different states
        let errors = [
            "Network timeout",
            "Invalid credentials",
            "Server error",
            "Unknown error",
            ""
        ]

        for (index, errorMsg) in errors.enumerated() {
            let state = ConnectionState.error(errorMsg)
            XCTAssertEqual(state.description, "错误: \(errorMsg)")
            XCTAssertEqual(state.color, "#FF3B30")

            // Verify each error state is different from others
            for (otherIndex, otherMsg) in errors.enumerated() where index != otherIndex {
                let otherState = ConnectionState.error(otherMsg)
                XCTAssertNotEqual(state, otherState)
            }
        }
    }
}
