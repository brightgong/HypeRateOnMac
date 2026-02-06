import XCTest
@testable import HypeRateOnMac

final class AppColorsTests: XCTestCase {

    // MARK: - Connection Status Colors Tests

    func testConnectionStateColors() {
        // Test that all connection state colors are defined
        XCTAssertEqual(AppColors.connected, "#34C759")
        XCTAssertEqual(AppColors.connecting, "#FF9500")
        XCTAssertEqual(AppColors.disconnected, "#8E8E93")
        XCTAssertEqual(AppColors.error, "#FF3B30")
    }

    func testConnectedColor() {
        // Given & When
        let color = AppColors.connected

        // Then
        XCTAssertEqual(color, "#34C759")
        XCTAssertFalse(color.isEmpty)
        XCTAssertTrue(color.hasPrefix("#"))
    }

    func testConnectingColor() {
        // Given & When
        let color = AppColors.connecting

        // Then
        XCTAssertEqual(color, "#FF9500")
        XCTAssertFalse(color.isEmpty)
        XCTAssertTrue(color.hasPrefix("#"))
    }

    func testDisconnectedColor() {
        // Given & When
        let color = AppColors.disconnected

        // Then
        XCTAssertEqual(color, "#8E8E93")
        XCTAssertFalse(color.isEmpty)
        XCTAssertTrue(color.hasPrefix("#"))
    }

    func testErrorColor() {
        // Given & When
        let color = AppColors.error

        // Then
        XCTAssertEqual(color, "#FF3B30")
        XCTAssertFalse(color.isEmpty)
        XCTAssertTrue(color.hasPrefix("#"))
    }

    // MARK: - Heart Rate Colors Tests

    func testHeartRateColors() {
        // Test that all heart rate colors are defined
        XCTAssertEqual(AppColors.heartRateNormal, "#34C759")
        XCTAssertEqual(AppColors.heartRateElevated, "#FF9500")
        XCTAssertEqual(AppColors.heartRateHigh, "#FF3B30")
    }

    func testHeartRateNormalColor() {
        // Given & When
        let color = AppColors.heartRateNormal

        // Then
        XCTAssertEqual(color, "#34C759")
        XCTAssertFalse(color.isEmpty)
        XCTAssertTrue(color.hasPrefix("#"))
    }

    func testHeartRateElevatedColor() {
        // Given & When
        let color = AppColors.heartRateElevated

        // Then
        XCTAssertEqual(color, "#FF9500")
        XCTAssertFalse(color.isEmpty)
        XCTAssertTrue(color.hasPrefix("#"))
    }

    func testHeartRateHighColor() {
        // Given & When
        let color = AppColors.heartRateHigh

        // Then
        XCTAssertEqual(color, "#FF3B30")
        XCTAssertFalse(color.isEmpty)
        XCTAssertTrue(color.hasPrefix("#"))
    }

    // MARK: - UI Colors Tests

    func testUIColors() {
        // Test that UI colors are defined
        XCTAssertEqual(AppColors.buttonPrimary, "#007AFF")
    }

    func testButtonPrimaryColor() {
        // Given & When
        let color = AppColors.buttonPrimary

        // Then
        XCTAssertEqual(color, "#007AFF")
        XCTAssertFalse(color.isEmpty)
        XCTAssertTrue(color.hasPrefix("#"))
    }

    // MARK: - Color Format Tests

    func testAllColorsHaveHashPrefix() {
        // Test that all colors start with #
        let allColors = [
            AppColors.connected,
            AppColors.connecting,
            AppColors.disconnected,
            AppColors.error,
            AppColors.heartRateNormal,
            AppColors.heartRateElevated,
            AppColors.heartRateHigh,
            AppColors.buttonPrimary
        ]

        for color in allColors {
            XCTAssertTrue(color.hasPrefix("#"), "Color \(color) should start with #")
        }
    }

    func testAllColorsAreValidHex() {
        // Test that all colors are valid hex format
        let allColors = [
            AppColors.connected,
            AppColors.connecting,
            AppColors.disconnected,
            AppColors.error,
            AppColors.heartRateNormal,
            AppColors.heartRateElevated,
            AppColors.heartRateHigh,
            AppColors.buttonPrimary
        ]

        for color in allColors {
            // Remove # prefix
            let hexString = String(color.dropFirst())

            // Check length (should be 6 for RGB or 8 for RGBA)
            XCTAssertTrue(hexString.count == 6 || hexString.count == 8,
                         "Color \(color) should have 6 or 8 hex characters")

            // Check that all characters are valid hex
            let hexCharacters = CharacterSet(charactersIn: "0123456789ABCDEFabcdef")
            XCTAssertTrue(hexString.unicodeScalars.allSatisfy { hexCharacters.contains($0) },
                         "Color \(color) should only contain valid hex characters")
        }
    }

    // MARK: - Color Consistency Tests

    func testConnectedAndNormalHavesSameColor() {
        // Connected state and normal heart rate should use same color
        XCTAssertEqual(AppColors.connected, AppColors.heartRateNormal)
    }

    func testErrorAndHighHaveSameColor() {
        // Error state and high heart rate should use same color
        XCTAssertEqual(AppColors.error, AppColors.heartRateHigh)
    }

    func testConnectingAndElevatedHaveSameColor() {
        // Connecting state and elevated heart rate should use same color
        XCTAssertEqual(AppColors.connecting, AppColors.heartRateElevated)
    }

    // MARK: - Color Uniqueness Tests

    func testConnectionStateColorsAreUnique() {
        // All connection state colors should be different
        let colors = [
            AppColors.connected,
            AppColors.connecting,
            AppColors.disconnected,
            AppColors.error
        ]

        let uniqueColors = Set(colors)
        XCTAssertEqual(colors.count, uniqueColors.count,
                      "Connection state colors should all be unique")
    }

    func testHeartRateColorsAreUnique() {
        // All heart rate colors should be different
        let colors = [
            AppColors.heartRateNormal,
            AppColors.heartRateElevated,
            AppColors.heartRateHigh
        ]

        let uniqueColors = Set(colors)
        XCTAssertEqual(colors.count, uniqueColors.count,
                      "Heart rate colors should all be unique")
    }
}
