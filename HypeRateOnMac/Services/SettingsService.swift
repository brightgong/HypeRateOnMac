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
        // 默认使用 EE6C
        self.deviceId = defaults.string(forKey: deviceIdKey) ?? "EE6C"
    }
    
    func validateDeviceId(_ id: String) -> Bool {
        // 验证 ID 格式：4位大写字母或数字
        let pattern = "^[A-Z0-9]{4}$"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: id.utf16.count)
        return regex?.firstMatch(in: id, options: [], range: range) != nil
    }
    
    func updateDeviceId(_ newId: String) -> Bool {
        let trimmedId = newId.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard validateDeviceId(trimmedId) else {
            return false
        }
        deviceId = trimmedId
        return true
    }
}
