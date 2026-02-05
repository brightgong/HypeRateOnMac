import XCTest
@testable import HypeRateOnMac

final class HeartRateDataTests: XCTestCase {

    // MARK: - Initialization Tests

    func testHeartRateDataInitWithDefaults() {
        // Given
        let heartRate = 75

        // When
        let data = HeartRateData(heartRate: heartRate)

        // Then
        XCTAssertEqual(data.heartRate, heartRate)
        XCTAssertNotNil(data.timestamp)
        // Timestamp should be within 1 second of now
        XCTAssertLessThan(abs(data.timestamp.timeIntervalSinceNow), 1.0)
    }

    func testHeartRateDataInitWithCustomTimestamp() {
        // Given
        let heartRate = 85
        let timestamp = Date(timeIntervalSince1970: 1609459200) // 2021-01-01 00:00:00 UTC

        // When
        let data = HeartRateData(heartRate: heartRate, timestamp: timestamp)

        // Then
        XCTAssertEqual(data.heartRate, heartRate)
        XCTAssertEqual(data.timestamp, timestamp)
    }

    // MARK: - Codable Tests

    func testHeartRateDataEncoding() throws {
        // Given
        let heartRate = 90
        let timestamp = Date(timeIntervalSince1970: 1609459200)
        let data = HeartRateData(heartRate: heartRate, timestamp: timestamp)

        // When
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(data)
        let jsonString = String(data: jsonData, encoding: .utf8)

        // Then
        XCTAssertNotNil(jsonString)
        XCTAssertTrue(jsonString!.contains("\"heartrate\":90"))
    }

    func testHeartRateDataDecodingWithIntTimestamp() throws {
        // Given
        let jsonString = """
        {
            "heartrate": 95,
            "timestamp": 1609459200
        }
        """
        let jsonData = jsonString.data(using: .utf8)!

        // When
        let decoder = JSONDecoder()
        let data = try decoder.decode(HeartRateData.self, from: jsonData)

        // Then
        XCTAssertEqual(data.heartRate, 95)
        XCTAssertEqual(data.timestamp.timeIntervalSince1970, 1609459200)
    }

    func testHeartRateDataDecodingWithMissingTimestamp() throws {
        // Given
        let jsonString = """
        {
            "heartrate": 100
        }
        """
        let jsonData = jsonString.data(using: .utf8)!

        // When
        let decoder = JSONDecoder()
        let data = try decoder.decode(HeartRateData.self, from: jsonData)

        // Then
        XCTAssertEqual(data.heartRate, 100)
        // Should default to current date
        XCTAssertLessThan(abs(data.timestamp.timeIntervalSinceNow), 1.0)
    }

    func testHeartRateDataDecodingWithVariousHeartRates() throws {
        // Test various heart rate values
        let testCases = [0, 40, 60, 80, 100, 120, 150, 200, 255]

        for heartRate in testCases {
            // Given
            let jsonString = """
            {
                "heartrate": \(heartRate),
                "timestamp": 1609459200
            }
            """
            let jsonData = jsonString.data(using: .utf8)!

            // When
            let decoder = JSONDecoder()
            let data = try decoder.decode(HeartRateData.self, from: jsonData)

            // Then
            XCTAssertEqual(data.heartRate, heartRate, "Failed for heart rate: \(heartRate)")
        }
    }

    // MARK: - Edge Cases

    func testHeartRateDataWithZeroHeartRate() {
        // Given & When
        let data = HeartRateData(heartRate: 0)

        // Then
        XCTAssertEqual(data.heartRate, 0)
    }

    func testHeartRateDataWithMaxHeartRate() {
        // Given & When
        let data = HeartRateData(heartRate: Int.max)

        // Then
        XCTAssertEqual(data.heartRate, Int.max)
    }
}
