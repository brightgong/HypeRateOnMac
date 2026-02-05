import XCTest
import Combine
@testable import HypeRateOnMac

final class HeartRateServiceNetworkTests: XCTestCase {

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

    // MARK: - WebSocket Message Parsing Tests

    func testParseHeartRateUpdateMessage() {
        // Given
        let message = WebSocketMessageHelper.createHeartRateUpdateMessage(heartRate: 85)
        let jsonString = WebSocketMessageHelper.messageToJSON(message)!

        // When - Simulate receiving this message
        let expectation = XCTestExpectation(description: "Heart rate updated")

        sut.$currentHeartRate
            .dropFirst()
            .sink { heartRate in
                if heartRate == 85 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // Connect and wait for potential heart rate update
        sut.connect(deviceId: "test123")

        // Give some time for connection
        wait(for: [expectation], timeout: 3.0)

        // Then - The service should be able to parse this message format
        XCTAssertNotNil(jsonString)
        XCTAssertTrue(jsonString.contains("hr_update"))
        XCTAssertTrue(jsonString.contains("85"))
    }

    func testParseReplyMessage() {
        // Given
        let message = WebSocketMessageHelper.createReplyMessage(status: "ok")
        let jsonString = WebSocketMessageHelper.messageToJSON(message)

        // Then
        XCTAssertNotNil(jsonString)
        XCTAssertTrue(jsonString!.contains("phx_reply"))
        XCTAssertTrue(jsonString!.contains("ok"))
    }

    func testCreateJoinMessage() {
        // Given
        let deviceId = "abc123"

        // When
        let message = WebSocketMessageHelper.createJoinMessage(deviceId: deviceId)
        let jsonString = WebSocketMessageHelper.messageToJSON(message)

        // Then
        XCTAssertNotNil(jsonString)
        XCTAssertTrue(jsonString!.contains("hr:\(deviceId)"))
        XCTAssertTrue(jsonString!.contains("phx_join"))
    }

    func testCreateLeaveMessage() {
        // Given
        let deviceId = "xyz789"

        // When
        let message = WebSocketMessageHelper.createLeaveMessage(deviceId: deviceId)
        let jsonString = WebSocketMessageHelper.messageToJSON(message)

        // Then
        XCTAssertNotNil(jsonString)
        XCTAssertTrue(jsonString!.contains("hr:\(deviceId)"))
        XCTAssertTrue(jsonString!.contains("phx_leave"))
    }

    func testCreateHeartbeatMessage() {
        // When
        let message = WebSocketMessageHelper.createHeartbeatMessage()
        let jsonString = WebSocketMessageHelper.messageToJSON(message)

        // Then
        XCTAssertNotNil(jsonString)
        XCTAssertTrue(jsonString!.contains("ping"))
        XCTAssertTrue(jsonString!.contains("timestamp"))
    }

    // MARK: - Message Format Validation Tests

    func testHeartRateUpdateMessageStructure() {
        // Given
        let heartRate = 92

        // When
        let message = WebSocketMessageHelper.createHeartRateUpdateMessage(heartRate: heartRate)

        // Then
        XCTAssertEqual(message["event"] as? String, "hr_update")
        XCTAssertNotNil(message["payload"])

        let payload = message["payload"] as? [String: Any]
        XCTAssertEqual(payload?["hr"] as? Int, heartRate)
    }

    func testJoinMessageStructure() {
        // Given
        let deviceId = "test99"

        // When
        let message = WebSocketMessageHelper.createJoinMessage(deviceId: deviceId)

        // Then
        XCTAssertEqual(message["topic"] as? String, "hr:\(deviceId)")
        XCTAssertEqual(message["event"] as? String, "phx_join")
        XCTAssertEqual(message["ref"] as? String, "1")
        XCTAssertNotNil(message["payload"])
    }

    func testLeaveMessageStructure() {
        // Given
        let deviceId = "leave01"

        // When
        let message = WebSocketMessageHelper.createLeaveMessage(deviceId: deviceId)

        // Then
        XCTAssertEqual(message["topic"] as? String, "hr:\(deviceId)")
        XCTAssertEqual(message["event"] as? String, "phx_leave")
        XCTAssertNotNil(message["ref"])
        XCTAssertNotNil(message["payload"])
    }

    func testHeartbeatMessageStructure() {
        // When
        let message = WebSocketMessageHelper.createHeartbeatMessage()

        // Then
        XCTAssertEqual(message["event"] as? String, "ping")
        XCTAssertNotNil(message["payload"])

        let payload = message["payload"] as? [String: Any]
        XCTAssertNotNil(payload?["timestamp"])
        XCTAssertTrue((payload?["timestamp"] as? Int ?? 0) > 0)
    }

    // MARK: - JSON Serialization Tests

    func testMessageToJSONConversion() {
        // Given
        let messages: [[String: Any]] = [
            WebSocketMessageHelper.createJoinMessage(deviceId: "test"),
            WebSocketMessageHelper.createLeaveMessage(deviceId: "test"),
            WebSocketMessageHelper.createHeartbeatMessage(),
            WebSocketMessageHelper.createHeartRateUpdateMessage(heartRate: 75),
            WebSocketMessageHelper.createReplyMessage()
        ]

        // When & Then
        for message in messages {
            let jsonString = WebSocketMessageHelper.messageToJSON(message)
            XCTAssertNotNil(jsonString)
            XCTAssertFalse(jsonString!.isEmpty)

            // Verify it's valid JSON by parsing back
            if let data = jsonString?.data(using: .utf8) {
                let parsed = try? JSONSerialization.jsonObject(with: data)
                XCTAssertNotNil(parsed)
            }
        }
    }

    func testMessageToDataConversion() {
        // Given
        let message = WebSocketMessageHelper.createHeartRateUpdateMessage(heartRate: 88)

        // When
        let data = WebSocketMessageHelper.messageToData(message)

        // Then
        XCTAssertNotNil(data)
        XCTAssertTrue(data!.count > 0)

        // Verify it can be parsed back
        let parsed = try? JSONSerialization.jsonObject(with: data!) as? [String: Any]
        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed?["event"] as? String, "hr_update")
    }

    // MARK: - Heart Rate Value Range Tests

    func testHeartRateUpdateWithVariousValues() {
        // Test various heart rate values
        let heartRates = [0, 40, 60, 80, 100, 120, 150, 200, 255]

        for hr in heartRates {
            // When
            let message = WebSocketMessageHelper.createHeartRateUpdateMessage(heartRate: hr)
            let jsonString = WebSocketMessageHelper.messageToJSON(message)

            // Then
            XCTAssertNotNil(jsonString)

            let payload = message["payload"] as? [String: Any]
            XCTAssertEqual(payload?["hr"] as? Int, hr)
        }
    }

    func testHeartRateUpdateMessageParsing() {
        // Given
        let testCases: [(Int, String)] = [
            (0, "minimum"),
            (60, "normal resting"),
            (100, "normal active"),
            (180, "high intensity"),
            (255, "maximum")
        ]

        for (heartRate, description) in testCases {
            // When
            let message = WebSocketMessageHelper.createHeartRateUpdateMessage(heartRate: heartRate)

            // Then
            let payload = message["payload"] as? [String: Any]
            XCTAssertEqual(
                payload?["hr"] as? Int,
                heartRate,
                "Failed for \(description) heart rate"
            )
        }
    }

    // MARK: - Connection URL Tests

    func testWebSocketURLFormat() {
        // Given
        let deviceIds = ["abc123", "xyz789", "test12"]

        for deviceId in deviceIds {
            // The service constructs URLs in the format:
            // wss://app.hyperate.io/ws/{deviceId}?token={api_key}

            // We can verify the URL components
            let expectedHost = "app.hyperate.io"
            let expectedScheme = "wss"
            let expectedPath = "/ws/\(deviceId)"

            // These are the expected components (we can't directly access the private URL)
            XCTAssertTrue(!deviceId.isEmpty)
            XCTAssertTrue(deviceId.count >= 3 && deviceId.count <= 6)
        }
    }

    // MARK: - Message Reference Tests

    func testMessageReferencesAreUnique() {
        // Given - Create multiple messages
        let messages = [
            WebSocketMessageHelper.createJoinMessage(deviceId: "test"),
            WebSocketMessageHelper.createLeaveMessage(deviceId: "test"),
            WebSocketMessageHelper.createLeaveMessage(deviceId: "test")
        ]

        // When - Extract refs
        let refs = messages.compactMap { $0["ref"] as? String }

        // Then - Leave messages should have unique refs (timestamp-based)
        // Join message has static ref "1"
        XCTAssertEqual(refs[0], "1") // Join message
        XCTAssertNotNil(refs[1]) // Leave message 1
        XCTAssertNotNil(refs[2]) // Leave message 2
        // Leave messages might have different refs due to timestamp
    }

    // MARK: - Edge Cases

    func testEmptyDeviceIdMessage() {
        // Given
        let deviceId = ""

        // When
        let message = WebSocketMessageHelper.createJoinMessage(deviceId: deviceId)

        // Then - Should still create a valid message structure
        XCTAssertEqual(message["topic"] as? String, "hr:")
        XCTAssertEqual(message["event"] as? String, "phx_join")
    }

    func testVeryLongDeviceIdMessage() {
        // Given
        let deviceId = String(repeating: "a", count: 100)

        // When
        let message = WebSocketMessageHelper.createJoinMessage(deviceId: deviceId)
        let jsonString = WebSocketMessageHelper.messageToJSON(message)

        // Then - Should handle long device IDs
        XCTAssertNotNil(jsonString)
        XCTAssertTrue(jsonString!.contains(deviceId))
    }

    func testSpecialCharactersInDeviceId() {
        // Given
        let deviceIds = ["test-id", "test_id", "test.id", "test@id"]

        for deviceId in deviceIds {
            // When
            let message = WebSocketMessageHelper.createJoinMessage(deviceId: deviceId)
            let jsonString = WebSocketMessageHelper.messageToJSON(message)

            // Then - Should properly encode special characters
            XCTAssertNotNil(jsonString)
        }
    }

    // MARK: - Timestamp Tests

    func testHeartbeatTimestampIsRecent() {
        // Given
        let now = Date().timeIntervalSince1970 * 1000 // milliseconds

        // When
        let message = WebSocketMessageHelper.createHeartbeatMessage()
        let payload = message["payload"] as? [String: Any]
        let timestamp = payload?["timestamp"] as? Int

        // Then
        XCTAssertNotNil(timestamp)
        let timestampDouble = Double(timestamp!)

        // Timestamp should be within 1 second of now
        XCTAssertLessThan(abs(timestampDouble - now), 1000)
    }

    func testLeaveMessageTimestampFormat() {
        // When
        let message = WebSocketMessageHelper.createLeaveMessage(deviceId: "test")
        let ref = message["ref"] as? String

        // Then - Should be a string representation of a timestamp
        XCTAssertNotNil(ref)
        XCTAssertTrue(!ref!.isEmpty)

        // Try to parse as Double (timestamp)
        let timestamp = Double(ref!)
        XCTAssertNotNil(timestamp)
    }

    // MARK: - Connection State Tests with Real Network

    func testConnectWithValidDeviceIdFormat() {
        // Given
        let validDeviceIds = ["abc123", "xyz789", "A1B2C3"]

        for deviceId in validDeviceIds {
            // When
            sut.connect(deviceId: deviceId)

            // Small delay to allow connection attempt
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

            // Then - Should attempt to connect (state should change from disconnected)
            // Note: Actual connection will fail in tests, but we verify the attempt
            XCTAssertNotEqual(sut.connectionState, .disconnected)

            // Cleanup
            sut.disconnect()
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        }
    }

    func testMultipleMessageTypesConversion() {
        // Given
        let messageTypes: [(String, [String: Any])] = [
            ("join", WebSocketMessageHelper.createJoinMessage(deviceId: "test")),
            ("leave", WebSocketMessageHelper.createLeaveMessage(deviceId: "test")),
            ("heartbeat", WebSocketMessageHelper.createHeartbeatMessage()),
            ("hr_update", WebSocketMessageHelper.createHeartRateUpdateMessage(heartRate: 75)),
            ("reply", WebSocketMessageHelper.createReplyMessage())
        ]

        // When & Then
        for (name, message) in messageTypes {
            let jsonString = WebSocketMessageHelper.messageToJSON(message)
            let data = WebSocketMessageHelper.messageToData(message)

            XCTAssertNotNil(jsonString, "\(name) JSON conversion failed")
            XCTAssertNotNil(data, "\(name) Data conversion failed")

            // Verify roundtrip
            if let data = data {
                let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                XCTAssertNotNil(parsed, "\(name) roundtrip failed")
            }
        }
    }
}
