import Foundation

struct HeartRateData: Codable {
    let heartRate: Int
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case heartRate = "heartrate"
        case timestamp
    }
    
    init(heartRate: Int, timestamp: Date = Date()) {
        self.heartRate = heartRate
        self.timestamp = timestamp
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        heartRate = try container.decode(Int.self, forKey: .heartRate)

        // Handle timestamp (may be Unix timestamp in seconds)
        if let timestampInt = try? container.decode(Int.self, forKey: .timestamp) {
            timestamp = Date(timeIntervalSince1970: TimeInterval(timestampInt))
        } else {
            timestamp = Date()
        }
    }
}

enum ConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case error(String)

    var description: String {
        switch self {
        case .disconnected:
            return "Disconnected"
        case .connecting:
            return "Connecting..."
        case .connected:
            return "Connected"
        case .error(let message):
            return "Error: \(message)"
        }
    }
    
    var color: String {
        switch self {
        case .disconnected:
            return "#8E8E93"
        case .connecting:
            return "#FF9500"
        case .connected:
            return "#34C759"
        case .error:
            return "#FF3B30"
        }
    }
}
