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
        
        // 处理时间戳（可能是秒级 Unix 时间戳）
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
            return "已断开"
        case .connecting:
            return "连接中..."
        case .connected:
            return "已连接"
        case .error(let message):
            return "错误: \(message)"
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
