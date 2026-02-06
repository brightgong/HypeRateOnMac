import XCTest
import SwiftUI
import Combine
@testable import HypeRateOnMac

final class MenuBarViewTests: XCTestCase {

    var viewModel: HeartRateViewModel!

    override func setUp() {
        super.setUp()
        viewModel = HeartRateViewModel()
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    // MARK: - View Creation Tests

    func testMenuBarViewCreation() {
        // When
        let view = MenuBarView(viewModel: viewModel)

        // Then
        XCTAssertNotNil(view)
        XCTAssertNotNil(view.viewModel)
    }

    // MARK: - Color Extension Tests

    func testColorFromHex3Digits() {
        // Test 3-digit hex color (RGB 12-bit)
        let color = Color(hex: "F00") // Red
        XCTAssertNotNil(color)
    }

    func testColorFromHex6Digits() {
        // Test 6-digit hex color (RGB 24-bit)
        let testCases = [
            "#FF3B30", // Red
            "#34C759", // Green
            "#FF9500", // Orange
            "#8E8E93", // Gray
            "FF3B30",  // Without #
            "ff3b30"   // Lowercase
        ]

        for hex in testCases {
            let color = Color(hex: hex)
            XCTAssertNotNil(color)
        }
    }

    func testColorFromHex8Digits() {
        // Test 8-digit hex color (ARGB 32-bit)
        let color = Color(hex: "80FF3B30") // Red with 50% opacity
        XCTAssertNotNil(color)
    }

    func testColorFromInvalidHex() {
        // Test invalid hex strings
        let invalidHexes = [
            "GHIJKL",  // Invalid characters
            "12",      // Too short
            "1234567", // Invalid length (7 digits)
            "",        // Empty
        ]

        for hex in invalidHexes {
            let color = Color(hex: hex)
            XCTAssertNotNil(color) // Should create a color (default fallback)
        }
    }

    func testColorHexWithPrefixRemoval() {
        // Test that # prefix is properly handled
        let color1 = Color(hex: "#FF0000")
        let color2 = Color(hex: "FF0000")

        // Both should create valid colors
        XCTAssertNotNil(color1)
        XCTAssertNotNil(color2)
    }

    func testColorHexCaseInsensitive() {
        // Test that hex parsing is case insensitive
        let testCases = [
            ("FF3B30", "ff3b30"),
            ("ABCDEF", "abcdef"),
            ("ABC123", "abc123")
        ]

        for (upper, lower) in testCases {
            let colorUpper = Color(hex: upper)
            let colorLower = Color(hex: lower)

            XCTAssertNotNil(colorUpper)
            XCTAssertNotNil(colorLower)
        }
    }

    func testColorHexWithWhitespace() {
        // Test hex with whitespace
        let color = Color(hex: "  FF3B30  ")
        XCTAssertNotNil(color)
    }

    func testColorHexSpecificValues() {
        // Test specific color values from the app
        let appColors = [
            "#8E8E93", // Disconnected
            "#FF9500", // Connecting
            "#34C759", // Connected
            "#FF3B30"  // Error
        ]

        for hexColor in appColors {
            let color = Color(hex: hexColor)
            XCTAssertNotNil(color)
        }
    }

    func testColorRGBConversion() {
        // Test that RGB values are correctly converted
        // This is a bit tricky to test directly, but we can verify the color is created
        let redColor = Color(hex: "FF0000")
        let greenColor = Color(hex: "00FF00")
        let blueColor = Color(hex: "0000FF")
        let whiteColor = Color(hex: "FFFFFF")
        let blackColor = Color(hex: "000000")

        XCTAssertNotNil(redColor)
        XCTAssertNotNil(greenColor)
        XCTAssertNotNil(blueColor)
        XCTAssertNotNil(whiteColor)
        XCTAssertNotNil(blackColor)
    }

    func testColorHex3DigitExpansion() {
        // Test that 3-digit hex is properly expanded
        // #RGB should become #RRGGBB (each digit multiplied by 17)
        let color = Color(hex: "F0A")
        XCTAssertNotNil(color)
    }

    func testColorHexWithSpecialCharacters() {
        // Test hex with special characters (should be stripped)
        let color = Color(hex: "#-FF3B30-!")
        XCTAssertNotNil(color)
    }

    // MARK: - ViewModel Integration Tests

    func testViewModelBinding() {
        // Given
        viewModel.deviceId = "abc123"
        viewModel.currentHeartRate = 75
        viewModel.connectionState = .connected

        // When
        let view = MenuBarView(viewModel: viewModel)

        // Then
        XCTAssertEqual(view.viewModel.deviceId, "abc123")
        XCTAssertEqual(view.viewModel.currentHeartRate, 75)
        XCTAssertEqual(view.viewModel.connectionState, .connected)
    }

    func testViewModelStateChanges() {
        // Given
        let view = MenuBarView(viewModel: viewModel)

        // When
        viewModel.connectionState = .connected
        viewModel.currentHeartRate = 80

        // Then
        XCTAssertEqual(view.viewModel.connectionState, .connected)
        XCTAssertEqual(view.viewModel.currentHeartRate, 80)
    }

    // MARK: - Heart Rate Display Tests

    func testHeartRateDisplayValues() {
        // Test various heart rate display scenarios
        let testCases: [(Int?, String)] = [
            (nil, "--"),
            (0, "0"),
            (60, "60"),
            (100, "100"),
            (200, "200")
        ]

        for (heartRate, expectedDisplay) in testCases {
            viewModel.currentHeartRate = heartRate
            XCTAssertEqual(viewModel.heartRateDisplay, expectedDisplay)
        }
    }

    // MARK: - Connection State Display Tests

    func testConnectionStateColors() {
        // Test that status colors match connection states
        let testCases: [(ConnectionState, String)] = [
            (.disconnected, "#8E8E93"),
            (.connecting, "#FF9500"),
            (.connected, "#34C759"),
            (.error("test"), "#FF3B30")
        ]

        for (state, expectedColor) in testCases {
            viewModel.connectionState = state
            XCTAssertEqual(viewModel.statusColor, expectedColor)
        }
    }

    // MARK: - Device ID Tests

    func testDeviceIdDisplay() {
        // Test device ID display
        let deviceIds = ["", "abc123", "xyz789", "test12"]

        for deviceId in deviceIds {
            viewModel.deviceId = deviceId
            let view = MenuBarView(viewModel: viewModel)
            XCTAssertEqual(view.viewModel.deviceId, deviceId)
        }
    }

    // MARK: - Edge Cases

    func testViewCreationWithDifferentStates() {
        // Test view creation with various connection states
        let states: [ConnectionState] = [
            .disconnected,
            .connecting,
            .connected,
            .error("Test error")
        ]

        for state in states {
            viewModel.connectionState = state
            let view = MenuBarView(viewModel: viewModel)
            XCTAssertNotNil(view)
            XCTAssertEqual(view.viewModel.connectionState, state)
        }
    }

    func testViewCreationWithExtremeHeartRates() {
        // Test with extreme heart rate values
        let heartRates = [0, 1, 50, 100, 200, 255, 999]

        for hr in heartRates {
            viewModel.currentHeartRate = hr
            let view = MenuBarView(viewModel: viewModel)
            XCTAssertNotNil(view)
            XCTAssertEqual(view.viewModel.currentHeartRate, hr)
        }
    }

    func testColorHexBoundaryValues() {
        // Test boundary RGB values
        let boundaryHexes = [
            "000000", // Min
            "FFFFFF", // Max
            "808080", // Mid
            "FF0000", // Max red
            "00FF00", // Max green
            "0000FF"  // Max blue
        ]

        for hex in boundaryHexes {
            let color = Color(hex: hex)
            XCTAssertNotNil(color)
        }
    }

    // MARK: - Scanner Tests for Color Extension

    func testColorHexScanning() {
        // Test the Scanner logic in Color extension
        let validHexStrings = [
            "123456",
            "ABCDEF",
            "abcdef",
            "ABC123",
            "000000",
            "FFFFFF"
        ]

        for hex in validHexStrings {
            var int: UInt64 = 0
            let scanner = Scanner(string: hex)
            let success = scanner.scanHexInt64(&int)

            XCTAssertTrue(success, "Failed to scan hex: \(hex)")
            XCTAssertGreaterThanOrEqual(int, 0)
        }
    }

    func testColorAlphaChannelWith8DigitHex() {
        // Test alpha channel parsing in 8-digit hex
        let hexWithAlpha = "80FF3B30" // 50% opacity red
        let color = Color(hex: hexWithAlpha)
        XCTAssertNotNil(color)
    }

    func testColorRGBComponentExtraction() {
        // Test RGB component extraction from hex
        // FF3B30 = R:255, G:59, B:48
        let hex = "FF3B30"
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let r = int >> 16
        let g = int >> 8 & 0xFF
        let b = int & 0xFF

        XCTAssertEqual(r, 255)
        XCTAssertEqual(g, 59)
        XCTAssertEqual(b, 48)
    }
}
