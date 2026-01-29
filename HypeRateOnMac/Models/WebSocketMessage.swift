import Foundation

// Phoenix Channel 消息结构
struct PhoenixMessage: Codable {
    let topic: String
    let event: String
    let payload: [String: AnyCodable]?
    let ref: String?
    
    init(topic: String, event: String, payload: [String: AnyCodable]? = nil, ref: String? = nil) {
        self.topic = topic
        self.event = event
        self.payload = payload
        self.ref = ref
    }
}

// 用于处理动态 JSON 值的类型
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array
        } else {
            value = NSNull()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let string as String:
            try container.encode(string)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let bool as Bool:
            try container.encode(bool)
        case let dict as [String: AnyCodable]:
            try container.encode(dict)
        case let array as [AnyCodable]:
            try container.encode(array)
        default:
            try container.encodeNil()
        }
    }
}

// 心率更新消息载荷
struct HeartRatePayload: Codable {
    let heartRate: Int
    let timestamp: Int?
    
    enum CodingKeys: String, CodingKey {
        case heartRate = "heartrate"
        case timestamp
    }
}

// Phoenix Channel 事件类型
enum PhoenixEvent {
    static let join = "phx_join"
    static let leave = "phx_leave"
    static let heartbeat = "heartbeat"
    static let reply = "phx_reply"
    static let error = "phx_error"
    static let close = "phx_close"
    
    // HypeRate 自定义事件
    static let heartRateUpdate = "hr:update"
}

// Phoenix Channel 主题
enum ChannelTopic {
    static func heartRate(deviceId: String) -> String {
        return "hr:\(deviceId)"
    }
}
