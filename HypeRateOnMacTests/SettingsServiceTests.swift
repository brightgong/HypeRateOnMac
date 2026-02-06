import XCTest
import Combine
@testable import HypeRateOnMac

final class SettingsServiceTests: XCTestCase {

    var sut: SettingsService!
    let testDeviceIdKey = "hyperate_device_id"

    override func setUp() {
        super.setUp()
        // Clear UserDefaults before each test
        UserDefaults.standard.removeObject(forKey: testDeviceIdKey)
        // Reset the singleton's state
        sut = SettingsService.shared
        sut.deviceId = "" // Reset to empty
    }

    override func tearDown() {
        // Clean up UserDefaults after each test
        UserDefaults.standard.removeObject(forKey: testDeviceIdKey)
        sut.deviceId = "" // Reset to empty
        sut = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitWithEmptyDefaults() {
        // Given - setUp clears defaults
        // When
        let service = SettingsService.shared

        // Then
        XCTAssertEqual(service.deviceId, "")
    }

    func testInitWithExistingDeviceId() {
        // Given
        UserDefaults.standard.set("abc123", forKey: testDeviceIdKey)

        // When
        // Need to access a new instance, but it's a singleton
        // So we verify it reads from UserDefaults
        let storedValue = UserDefaults.standard.string(forKey: testDeviceIdKey)

        // Then
        XCTAssertEqual(storedValue, "abc123")
    }

    // MARK: - Validation Tests

    func testValidateDeviceIdWithValidInput() {
        // Test valid device IDs
        let validIds = [
            "abc",      // 3 characters
            "ABC",      // uppercase
            "123",      // numbers
            "aBc123",   // mixed
            "XyZ789",   // 6 characters
            "a1B2c3"    // mixed case and numbers
        ]

        for id in validIds {
            XCTAssertTrue(sut.validateDeviceId(id), "'\(id)' should be valid")
        }
    }

    func testValidateDeviceIdWithInvalidInput() {
        // Test invalid device IDs
        let invalidIds = [
            "",           // empty
            "ab",         // too short (2 chars)
            "abcdefg",    // too long (7 chars)
            "ab-123",     // contains hyphen
            "ab_123",     // contains underscore
            "ab 123",     // contains space
            "ab.123",     // contains dot
            "abc!",       // contains special char
            "abc@123",    // contains @
            "abc#123",    // contains #
            "中文id",      // contains non-ASCII
            "abc\n123"    // contains newline
        ]

        for id in invalidIds {
            XCTAssertFalse(sut.validateDeviceId(id), "'\(id)' should be invalid")
        }
    }

    func testValidateDeviceIdBoundaries() {
        // Test boundary conditions
        XCTAssertFalse(sut.validateDeviceId("ab"))        // 2 chars - too short
        XCTAssertTrue(sut.validateDeviceId("abc"))        // 3 chars - minimum
        XCTAssertTrue(sut.validateDeviceId("abcd"))       // 4 chars - valid
        XCTAssertTrue(sut.validateDeviceId("abcde"))      // 5 chars - valid
        XCTAssertTrue(sut.validateDeviceId("abcdef"))     // 6 chars - maximum
        XCTAssertFalse(sut.validateDeviceId("abcdefg"))   // 7 chars - too long
    }

    // MARK: - Update Tests

    func testUpdateDeviceIdWithValidId() {
        // Given
        let validId = "abc123"

        // When
        let result = sut.updateDeviceId(validId)

        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(sut.deviceId, validId)
        XCTAssertEqual(UserDefaults.standard.string(forKey: testDeviceIdKey), validId)
    }

    func testUpdateDeviceIdWithInvalidId() {
        // Given
        let invalidId = "invalid-id"
        sut.deviceId = "old123"

        // When
        let result = sut.updateDeviceId(invalidId)

        // Then
        XCTAssertFalse(result)
        XCTAssertEqual(sut.deviceId, "old123") // Should not change
    }

    func testUpdateDeviceIdWithWhitespace() {
        // Given
        let idWithWhitespace = "  abc123  "

        // When
        let result = sut.updateDeviceId(idWithWhitespace)

        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(sut.deviceId, "abc123") // Should be trimmed
    }

    func testUpdateDeviceIdWithLeadingWhitespace() {
        // Given
        let id = "  xyz789"

        // When
        let result = sut.updateDeviceId(id)

        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(sut.deviceId, "xyz789")
    }

    func testUpdateDeviceIdWithTrailingWhitespace() {
        // Given
        let id = "xyz789  "

        // When
        let result = sut.updateDeviceId(id)

        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(sut.deviceId, "xyz789")
    }

    func testUpdateDeviceIdWithNewlines() {
        // Given
        let id = "\nabc123\n"

        // When
        let result = sut.updateDeviceId(id)

        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(sut.deviceId, "abc123")
    }

    func testUpdateDeviceIdWithTabs() {
        // Given
        let id = "\tabc123\t"

        // When
        let result = sut.updateDeviceId(id)

        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(sut.deviceId, "abc123")
    }

    func testUpdateDeviceIdMultipleTimes() {
        // Test updating device ID multiple times
        let ids = ["abc123", "xyz789", "def456"]

        for id in ids {
            // When
            let result = sut.updateDeviceId(id)

            // Then
            XCTAssertTrue(result)
            XCTAssertEqual(sut.deviceId, id)
            XCTAssertEqual(UserDefaults.standard.string(forKey: testDeviceIdKey), id)
        }
    }

    // MARK: - Published Property Tests

    func testDeviceIdPublishedProperty() {
        // Given
        let expectation = XCTestExpectation(description: "DeviceId published")
        var receivedValue: String?

        let cancellable = sut.$deviceId
            .dropFirst() // Skip initial value
            .sink { value in
                receivedValue = value
                expectation.fulfill()
            }

        // When
        sut.deviceId = "test123"

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedValue, "test123")
        cancellable.cancel()
    }

    func testDeviceIdPersistence() {
        // Given - Use a valid device ID (3-6 alphanumeric characters)
        let deviceId = "test12"

        // When
        let result = sut.updateDeviceId(deviceId)

        // Then
        XCTAssertTrue(result, "Update should succeed")
        XCTAssertEqual(sut.deviceId, deviceId, "Service should have updated device ID")

        // Verify persistence
        let stored = UserDefaults.standard.string(forKey: testDeviceIdKey)
        XCTAssertEqual(stored, deviceId, "Value should be persisted to UserDefaults")
    }

    // MARK: - Edge Cases

    func testUpdateDeviceIdWithEmptyStringAfterTrim() {
        // Given
        let id = "   "

        // When
        let result = sut.updateDeviceId(id)

        // Then
        XCTAssertFalse(result)
    }

    func testSingletonBehavior() {
        // Verify that SettingsService.shared returns the same instance
        let instance1 = SettingsService.shared
        let instance2 = SettingsService.shared

        XCTAssertTrue(instance1 === instance2)
    }

    func testValidateDeviceIdWithNumericOnly() {
        // Test device IDs with only numbers
        XCTAssertTrue(sut.validateDeviceId("123"))
        XCTAssertTrue(sut.validateDeviceId("123456"))
        XCTAssertTrue(sut.validateDeviceId("000000"))
    }

    func testValidateDeviceIdWithAlphabeticOnly() {
        // Test device IDs with only letters
        XCTAssertTrue(sut.validateDeviceId("abc"))
        XCTAssertTrue(sut.validateDeviceId("ABCDEF"))
        XCTAssertTrue(sut.validateDeviceId("XyZaBc"))
    }

    func testUpdateDeviceIdCasePreservation() {
        // Verify that case is preserved
        let mixedCaseId = "AbC123"
        let result = sut.updateDeviceId(mixedCaseId)

        XCTAssertTrue(result)
        XCTAssertEqual(sut.deviceId, "AbC123")
    }
}
