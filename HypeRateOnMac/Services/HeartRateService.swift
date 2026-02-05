import Foundation
import Combine

class HeartRateService: NSObject, ObservableObject {
    @Published var currentHeartRate: Int?
    @Published var connectionState: ConnectionState = .disconnected

    private var webSocketTask: URLSessionWebSocketTask?
    private var heartbeatTimer: DispatchSourceTimer?
    private var reconnectTimer: DispatchSourceTimer?

    private var deviceId: String = ""
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 10
    private let reconnectDelayBase: TimeInterval = 2.0

    private let heartbeatInterval: TimeInterval = 10.0
    private let heartbeatQueue = DispatchQueue(label: "com.hyperate.heartbeat", qos: .userInteractive)

    // 格式化当前时间戳
    private func logTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: Date())
    }

    // MARK: - Connection

    func connect(deviceId: String) {
        self.deviceId = deviceId

        print("[\(logTimestamp())] 🔵 [HypeRate] 开始连接...")
        print("[\(logTimestamp())] 🔵 [HypeRate] 设备 ID: \(deviceId)")

        // 断开现有连接
        disconnect()

        // 更新状态
        DispatchQueue.main.async {
            self.connectionState = .connecting
        }

        // 构建 WebSocket URL
        let urlString = "wss://app.hyperate.io/ws/\(deviceId)?token=YOUR_TOKEN_HERE"
        print("[\(logTimestamp())] 🔵 [HypeRate] 连接 URL: wss://app.hyperate.io/ws/\(deviceId)")

        guard let url = URL(string: urlString) else {
            let errorMsg = "无效的 URL"
            print("[\(logTimestamp())] 🔴 [HypeRate] 错误: \(errorMsg)")
            DispatchQueue.main.async {
                self.connectionState = .error(errorMsg)
            }
            return
        }

        // 创建 WebSocket 连接
        let request = URLRequest(url: url)
        webSocketTask = URLSession.shared.webSocketTask(with: request)
        webSocketTask?.delegate = self

        // 开始接收消息
        receiveMessage()

        // 启动连接
        print("[\(logTimestamp())] 🔵 [HypeRate] 启动 WebSocket 握手...")
        webSocketTask?.resume()
    }

    func disconnect() {
        // 停止定时器
        stopHeartbeat()
        stopReconnectTimer()

        // 发送离开消息
        if connectionState == .connected {
            sendLeaveMessage()
        }

        // 关闭 WebSocket
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil

        // 重置状态
        DispatchQueue.main.async {
            self.connectionState = .disconnected
            self.currentHeartRate = nil
        }

        reconnectAttempts = 0
    }

    // MARK: - WebSocket Messages

    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let message):
                self.handleWebSocketMessage(message)
                // 继续接收下一条消息
                self.receiveMessage()

            case .failure(let error):
                let nsError = error as NSError
                print("[\(self.logTimestamp())] 🔴 [HypeRate] 接收消息失败")
                print("[\(self.logTimestamp())] 🔴 [HypeRate] 错误码: \(nsError.code)")
                print("[\(self.logTimestamp())] 🔴 [HypeRate] 错误描述: \(error.localizedDescription)")
                print("[\(self.logTimestamp())] 🔴 [HypeRate] 错误域: \(nsError.domain)")

                if let failingURL = nsError.userInfo[NSURLErrorFailingURLErrorKey] as? URL {
                    print("[\(self.logTimestamp())] 🔴 [HypeRate] 失败的 URL: \(failingURL.absoluteString)")
                }

                DispatchQueue.main.async {
                    self.connectionState = .error("接收消息失败: \(error.localizedDescription)")
                }
                self.scheduleReconnect()
            }
        }
    }

    private func handleWebSocketMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            handleTextMessage(text)
        case .data(let data):
            // 处理二进制数据（如果有的话）
            if let text = String(data: data, encoding: .utf8) {
                handleTextMessage(text)
            }
        @unknown default:
            break
        }
    }

    private func handleTextMessage(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }

        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let event = json["event"] as? String ?? ""
                print("[\(logTimestamp())] 📨 [HypeRate] 收到消息: event=\(event)")

                // 忽略系统回复消息
                if event == "phx_reply" {
                    print("[\(logTimestamp())] ✅ [HypeRate] 收到加入确认")
                    DispatchQueue.main.async {
                        if self.connectionState != .connected {
                            self.connectionState = .connected
                            self.reconnectAttempts = 0
                            self.startHeartbeat()
                        }
                    }
                    return
                }

                // 处理心率更新
                if event == "hr_update" {
                    if let payload = json["payload"] as? [String: Any],
                       let hr = payload["hr"] as? Int {
                        print("[\(logTimestamp())] ❤️ [HypeRate] 心率更新: \(hr) BPM")
                        DispatchQueue.main.async {
                            self.currentHeartRate = hr
                        }
                    }
                }
            }
        } catch {
            print("[\(logTimestamp())] 🔴 [HypeRate] 解析消息失败: \(error)")
            print("[\(logTimestamp())] 🔴 [HypeRate] 消息内容: \(text)")
        }
    }

    // MARK: - Send Messages

    private func sendJoinMessage() {
        print("[\(logTimestamp())] 📤 [HypeRate] 发送加入消息: hr:\(deviceId)")
        let message: [String: Any] = [
            "topic": "hr:\(deviceId)",
            "event": "phx_join",
            "payload": [:],
            "ref": "1"
        ]
        sendMessage(message)
    }

    private func sendLeaveMessage() {
        print("[\(logTimestamp())] 📤 [HypeRate] 发送离开消息: hr:\(deviceId)")
        let message: [String: Any] = [
            "topic": "hr:\(deviceId)",
            "event": "phx_leave",
            "payload": [:],
            "ref": Date().timeIntervalSince1970.description
        ]
        sendMessage(message)

        // 100ms 后关闭连接
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.webSocketTask?.cancel(with: .normalClosure, reason: nil)
        }
    }

    private func sendHeartbeat() {
        print("[\(logTimestamp())] 💓 [HypeRate] 发送心跳")
        let message: [String: Any] = [
            "event": "ping",
            "payload": ["timestamp": Int(Date().timeIntervalSince1970 * 1000)]
        ]
        sendMessage(message)
    }

    private func sendMessage(_ message: [String: Any]) {
        do {
            let data = try JSONSerialization.data(withJSONObject: message)
            if let text = String(data: data, encoding: .utf8) {
                print("[\(logTimestamp())] 📤 [HypeRate] 发送: \(text)")
                webSocketTask?.send(.string(text)) { [weak self] error in
                    if let error = error {
                        print("[\(self?.logTimestamp() ?? "")] 🔴 [HypeRate] 发送消息失败: \(error)")
                    } else {
                        print("[\(self?.logTimestamp() ?? "")] ✅ [HypeRate] 发送成功")
                    }
                }
            }
        } catch {
            print("[\(logTimestamp())] 🔴 [HypeRate] 编码消息失败: \(error)")
        }
    }

    // MARK: - Heartbeat

    private func startHeartbeat() {
        stopHeartbeat()
        print("[\(logTimestamp())] 💓 [HypeRate] 启动心跳定时器 (间隔: \(heartbeatInterval)s)")

        // 立即发送一次加入消息
        sendJoinMessage()

        // 创建 DispatchSourceTimer
        heartbeatTimer = DispatchSource.makeTimerSource(queue: heartbeatQueue)
        heartbeatTimer?.schedule(deadline: .now() + heartbeatInterval, repeating: heartbeatInterval)
        heartbeatTimer?.setEventHandler { [weak self] in
            self?.sendHeartbeat()
        }
        heartbeatTimer?.resume()

        print("[\(logTimestamp())] 💓 [HypeRate] 心跳定时器已启动")
    }

    private func stopHeartbeat() {
        heartbeatTimer?.cancel()
        heartbeatTimer = nil
    }

    // MARK: - Reconnection

    private func scheduleReconnect() {
        guard reconnectAttempts < maxReconnectAttempts else {
            print("[\(logTimestamp())] 🔴 [HypeRate] 重连次数超过限制 (\(maxReconnectAttempts) 次)")
            DispatchQueue.main.async {
                self.connectionState = .error("重连次数超过限制")
            }
            return
        }

        reconnectAttempts += 1
        let delay = min(reconnectDelayBase * pow(2.0, Double(reconnectAttempts - 1)), 60.0)

        print("[\(logTimestamp())] 🔄 [HypeRate] 计划重连 (第 \(reconnectAttempts) 次)，\(delay) 秒后重试")
        DispatchQueue.main.async {
            self.connectionState = .connecting
        }

        // 使用 DispatchSourceTimer 进行重连
        let reconnectQueue = DispatchQueue(label: "com.hyperate.reconnect", qos: .userInitiated)
        reconnectTimer = DispatchSource.makeTimerSource(queue: reconnectQueue)
        reconnectTimer?.schedule(deadline: .now() + delay, repeating: .never)
        reconnectTimer?.setEventHandler { [weak self] in
            guard let self = self else { return }
            print("[\(self.logTimestamp())] 🔄 [HypeRate] 开始重连...")
            self.connect(deviceId: self.deviceId)
        }
        reconnectTimer?.resume()
    }

    private func stopReconnectTimer() {
        reconnectTimer?.cancel()
        reconnectTimer = nil
    }
}

// MARK: - URLSessionWebSocketDelegate

extension HeartRateService: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol subprotocol: String?) {
        print("[\(logTimestamp())] ✅ [HypeRate] WebSocket 握手成功")
        if let subprotocol = subprotocol {
            print("[\(logTimestamp())] ✅ [HypeRate] 协议: \(subprotocol)")
        }

        DispatchQueue.main.async {
            self.connectionState = .connected
            self.reconnectAttempts = 0
        }

        // 连接成功后发送加入消息并启动心跳
        sendJoinMessage()
        startHeartbeat()
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("[\(logTimestamp())] 🔴 [HypeRate] WebSocket 连接关闭")
        print("[\(logTimestamp())] 🔴 [HypeRate] 关闭码: \(closeCode.rawValue)")

        if let reason = reason, let reasonString = String(data: reason, encoding: .utf8) {
            print("[\(logTimestamp())] 🔴 [HypeRate] 关闭原因: \(reasonString)")
        }

        DispatchQueue.main.async {
            self.connectionState = .disconnected
        }
        stopHeartbeat()
        scheduleReconnect()
    }
}
