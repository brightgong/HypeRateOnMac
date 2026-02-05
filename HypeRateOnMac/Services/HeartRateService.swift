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
    private var isManualDisconnect = false // Flag for manual disconnect
    private let reconnectDelayBase: TimeInterval = 2.0

    private let heartbeatInterval: TimeInterval = 15.0
    private let heartbeatQueue = DispatchQueue(label: "com.hyperate.heartbeat", qos: .userInteractive)

    // Static DateFormatter to avoid repeated creation
    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    // Format current timestamp
    private func logTimestamp() -> String {
        return Self.timestampFormatter.string(from: Date())
    }

    // MARK: - Connection

    func connect(deviceId: String) {
        self.deviceId = deviceId

        print("[\(logTimestamp())] 🔵 [HypeRate] Starting connection...")
        print("[\(logTimestamp())] 🔵 [HypeRate] Device ID: \(deviceId)")

        // Disconnect existing connection (not marked as manual)
        if webSocketTask != nil {
            stopHeartbeat()
            stopReconnectTimer()
            webSocketTask?.cancel(with: .normalClosure, reason: nil)
            webSocketTask = nil
        }

        // Reset state, mark as non-manual disconnect
        self.isManualDisconnect = false
        reconnectAttempts = 0

        // Update state
        DispatchQueue.main.async {
            self.connectionState = .connecting
        }

        // Build WebSocket URL
        let urlString = "wss://app.hyperate.io/ws/\(deviceId)?token=YOUR_TOKEN_HERE"
        print("[\(logTimestamp())] 🔵 [HypeRate] Connection URL: wss://app.hyperate.io/ws/\(deviceId)")

        guard let url = URL(string: urlString) else {
            let errorMsg = "Invalid URL"
            print("[\(logTimestamp())] 🔴 [HypeRate] Error: \(errorMsg)")
            DispatchQueue.main.async {
                self.connectionState = .error(errorMsg)
            }
            return
        }

        // Create WebSocket connection
        let request = URLRequest(url: url)
        webSocketTask = URLSession.shared.webSocketTask(with: request)
        webSocketTask?.delegate = self

        // Start receiving messages
        receiveMessage()

        // Start connection
        print("[\(logTimestamp())] 🔵 [HypeRate] Starting WebSocket handshake...")
        webSocketTask?.resume()
    }

    func disconnect() {
        print("[\(logTimestamp())] 🔵 [HypeRate] Starting manual disconnect")

        isManualDisconnect = true // Mark as manual disconnect

        // Stop timers
        stopHeartbeat()
        stopReconnectTimer()

        print("[\(logTimestamp())] 🔵 [HypeRate] Stopped heartbeat and reconnect timers")

        // Save current connection state for judgment (before update)
        let wasConnected = connectionState == .connected

        // Async update UI state (avoid deadlock)
        DispatchQueue.main.async {
            self.connectionState = .disconnected
            self.currentHeartRate = nil
        }

        print("[\(logTimestamp())] 🔵 [HypeRate] Requested state update to disconnected")

        // Only send close message when WebSocket is running
        if let task = webSocketTask, task.state == .running {
            if wasConnected {
                print("[\(logTimestamp())] 🔵 [HypeRate] Sending leave message")
                sendLeaveMessage()
            } else {
                print("[\(logTimestamp())] 🔵 [HypeRate] Close WebSocket directly")
                task.cancel(with: .normalClosure, reason: nil)
                webSocketTask = nil
            }
        } else {
            print("[\(logTimestamp())] 🔵 [HypeRate] WebSocket not running, no need to close")
            webSocketTask = nil
        }

        // Note: if leave message sent, webSocketTask will close after 100ms
        // Otherwise already set to nil

        reconnectAttempts = 0
        print("[\(logTimestamp())] ✅ [HypeRate] Disconnect complete")
    }

    // MARK: - WebSocket Messages

    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let message):
                self.handleWebSocketMessage(message)
                // Continue receiving next message
                self.receiveMessage()

            case .failure(let error):
                let nsError = error as NSError
                print("[\(self.logTimestamp())] 🔴 [HypeRate] Message receive failed")
                print("[\(self.logTimestamp())] 🔴 [HypeRate] Error code: \(nsError.code)")
                print("[\(self.logTimestamp())] 🔴 [HypeRate] Error description: \(error.localizedDescription)")
                print("[\(self.logTimestamp())] 🔴 [HypeRate] Error domain: \(nsError.domain)")

                if let failingURL = nsError.userInfo[NSURLErrorFailingURLErrorKey] as? URL {
                    print("[\(self.logTimestamp())] 🔴 [HypeRate] Failed URL: \(failingURL.absoluteString)")
                }

                // Check if manual disconnect
                if self.isManualDisconnect {
                    print("[\(self.logTimestamp())] 🔵 [HypeRate] Error from manual disconnect, ignore")
                    // Don't set error state, don't trigger reconnect
                    return
                }

                DispatchQueue.main.async {
                    self.connectionState = .error(error.localizedDescription)
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
            // Handle binary data (if any)
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
                print("[\(logTimestamp())] 📨 [HypeRate] Received message: event=\(event)")

                // Ignore system reply message
                if event == "phx_reply" {
                    print("[\(logTimestamp())] ✅ [HypeRate] Received join confirmation")
                    DispatchQueue.main.async {
                        if self.connectionState != .connected {
                            self.connectionState = .connected
                            self.reconnectAttempts = 0
                            self.startHeartbeat()
                        }
                    }
                    return
                }

                // Handle heart rate update
                if event == "hr_update" {
                    if let payload = json["payload"] as? [String: Any],
                       let hr = payload["hr"] as? Int {
                        print("[\(logTimestamp())] ❤️ [HypeRate] Heart rate update: \(hr) BPM")
                        DispatchQueue.main.async {
                            self.currentHeartRate = hr
                        }
                    }
                }
            }
        } catch {
            print("[\(logTimestamp())] 🔴 [HypeRate] Message parse failed: \(error)")
            print("[\(logTimestamp())] 🔴 [HypeRate] Message content: \(text)")
        }
    }

    // MARK: - Send Messages

    private func sendJoinMessage() {
        print("[\(logTimestamp())] 📤 [HypeRate] Sending join message: hr:\(deviceId)")
        let message: [String: Any] = [
            "topic": "hr:\(deviceId)",
            "event": "phx_join",
            "payload": [:],
            "ref": "1"
        ]
        sendMessage(message)
    }

    private func sendLeaveMessage() {
        print("[\(logTimestamp())] 📤 [HypeRate] Sending leave message: hr:\(deviceId)")
        let message: [String: Any] = [
            "topic": "hr:\(deviceId)",
            "event": "phx_leave",
            "payload": [:],
            "ref": Date().timeIntervalSince1970.description
        ]
        sendMessage(message)

        // Close connection and cleanup webSocketTask after 100ms
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            print("[\(self.logTimestamp())] 🔵 [HypeRate] Closing WebSocket")
            self.webSocketTask?.cancel(with: .normalClosure, reason: nil)
            self.webSocketTask = nil
        }
    }

    private func sendHeartbeat() {
        print("[\(logTimestamp())] 💓 [HypeRate] Sending heartbeat")
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
                print("[\(logTimestamp())] 📤 [HypeRate] Sending: \(text)")
                webSocketTask?.send(.string(text)) { [weak self] error in
                    if let error = error {
                        print("[\(self?.logTimestamp() ?? "")] 🔴 [HypeRate] Send message failed: \(error)")
                    } else {
                        print("[\(self?.logTimestamp() ?? "")] ✅ [HypeRate] Send success")
                    }
                }
            }
        } catch {
            print("[\(logTimestamp())] 🔴 [HypeRate] Message encoding failed: \(error)")
        }
    }

    // MARK: - Heartbeat

    private func startHeartbeat() {
        stopHeartbeat()
        print("[\(logTimestamp())] 💓 [HypeRate] Starting heartbeat timer (interval: \(heartbeatInterval)s)")

        // Create DispatchSourceTimer
        heartbeatTimer = DispatchSource.makeTimerSource(queue: heartbeatQueue)
        heartbeatTimer?.schedule(deadline: .now() + heartbeatInterval, repeating: heartbeatInterval)
        heartbeatTimer?.setEventHandler { [weak self] in
            self?.sendHeartbeat()
        }
        heartbeatTimer?.resume()

        print("[\(logTimestamp())] 💓 [HypeRate] Heartbeat timer started")
    }

    private func stopHeartbeat() {
        heartbeatTimer?.cancel()
        heartbeatTimer = nil
    }

    // MARK: - Reconnection

    private func scheduleReconnect() {
        // Manual disconnect doesn't trigger auto-reconnect
        guard !isManualDisconnect else {
            print("[\(logTimestamp())] 🔵 [HypeRate] Manual disconnect, don't trigger reconnect")
            return
        }

        // Prevent duplicate reconnect scheduling
        if connectionState == .connecting {
            print("[\(logTimestamp())] 🔵 [HypeRate] Already in reconnecting state, skip duplicate call")
            return
        }

        guard reconnectAttempts < maxReconnectAttempts else {
            print("[\(logTimestamp())] 🔴 [HypeRate] Reconnect attempts exceeded limit (\(maxReconnectAttempts) times)")
            DispatchQueue.main.async {
                self.connectionState = .error("Reconnect attempts exceeded")
            }
            return
        }

        reconnectAttempts += 1
        let delay = min(reconnectDelayBase * pow(2.0, Double(reconnectAttempts - 1)), 60.0)

        print("[\(logTimestamp())] 🔄 [HypeRate] Scheduling reconnect (attempt \(reconnectAttempts)), \(delay) seconds until retry")
        DispatchQueue.main.async {
            self.connectionState = .connecting
        }

        // Use DispatchSourceTimer for reconnect
        let reconnectQueue = DispatchQueue(label: "com.hyperate.reconnect", qos: .userInitiated)
        reconnectTimer = DispatchSource.makeTimerSource(queue: reconnectQueue)
        reconnectTimer?.schedule(deadline: .now() + delay, repeating: .never)
        reconnectTimer?.setEventHandler { [weak self] in
            guard let self = self else { return }
            print("[\(self.logTimestamp())] 🔄 [HypeRate] Starting reconnect...")
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
        print("[\(logTimestamp())] ✅ [HypeRate] WebSocket handshake successful")
        if let subprotocol = subprotocol {
            print("[\(logTimestamp())] ✅ [HypeRate] Protocol: \(subprotocol)")
        }

        DispatchQueue.main.async {
            self.connectionState = .connected
            self.reconnectAttempts = 0
        }

        // Send join message and start heartbeat after connection
        sendJoinMessage()
        startHeartbeat()
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("[\(logTimestamp())] 🔴 [HypeRate] WebSocket connection closed")
        print("[\(logTimestamp())] 🔴 [HypeRate] Close code: \(closeCode.rawValue)")

        if let reason = reason, let reasonString = String(data: reason, encoding: .utf8) {
            print("[\(logTimestamp())] 🔴 [HypeRate] Close reason: \(reasonString)")
        }

        // Check if manual disconnect
        if isManualDisconnect {
            print("[\(logTimestamp())] 🔵 [HypeRate] Manual disconnect, keep disconnected state")
            // State already set in disconnect(), don't trigger reconnect
            stopHeartbeat()
            return
        }

        DispatchQueue.main.async {
            self.connectionState = .disconnected
        }
        stopHeartbeat()

        scheduleReconnect()
    }
}
