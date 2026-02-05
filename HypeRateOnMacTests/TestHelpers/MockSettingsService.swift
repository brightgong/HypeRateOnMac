import Foundation
import Combine
@testable import HypeRateOnMac

// MARK: - Protocol Definitions

/// Protocol for SettingsService to enable mocking without modifying source code
protocol SettingsServiceProtocol: AnyObject, ObservableObject {
    var deviceId: String { get set }
    func validateDeviceId(_ id: String) -> Bool
    func updateDeviceId(_ newId: String) -> Bool
}

// MARK: - Real Service Adapter

/// Adapter to make the real SettingsService conform to the protocol
extension SettingsService: SettingsServiceProtocol {
    // Already implements all required methods
}

// MARK: - Mock Implementation

/// Mock implementation of SettingsService for testing
class MockSettingsService: ObservableObject, SettingsServiceProtocol {
    @Published var deviceId: String = ""

    func validateDeviceId(_ id: String) -> Bool {
        let pattern = "^[a-zA-Z0-9]{3,6}$"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: id.utf16.count)
        return regex?.firstMatch(in: id, options: [], range: range) != nil
    }

    func updateDeviceId(_ newId: String) -> Bool {
        let trimmedId = newId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard validateDeviceId(trimmedId) else {
            return false
        }
        deviceId = trimmedId
        return true
    }
}
