import Foundation

class SettingsService: ObservableObject {
    static let shared = SettingsService()

    private let defaults = UserDefaults.standard
    private let deviceIdKey = "hyperate_device_id"

    @Published var deviceId: String {
        didSet {
            defaults.set(deviceId, forKey: deviceIdKey)
        }
    }

    private init() {
        self.deviceId = defaults.string(forKey: deviceIdKey) ?? ""
    }

    // MARK: - Validation

    func validateDeviceId(_ id: String) -> Bool {
        let pattern = "^[a-zA-Z0-9]{3,6}$"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: id.utf16.count)
        return regex?.firstMatch(in: id, options: [], range: range) != nil
    }

    // MARK: - Update Methods

    func updateDeviceId(_ newId: String) -> Bool {
        let trimmedId = newId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard validateDeviceId(trimmedId) else {
            return false
        }
        deviceId = trimmedId
        return true
    }
}
