import Foundation
import Combine
import OSLog

class HeartRateService: NSObject, ObservableObject, HeartRateServiceProtocol {
    @Published var currentHeartRate: Int?
    @Published var connectionState: ConnectionState = .disconnected

    var currentHeartRatePublisher: Published<Int?>.Publisher { $currentHeartRate }
    var connectionStatePublisher: Published<ConnectionState>.Publisher { $connectionState }

    private var webSocketTask: URLSessionWebSocketTask?
    private var heartbeatTimer: DispatchSourceTimer?
    private var reconnectTimer: DispatchSourceTimer?

    private var deviceId: String = ""
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 10
    private var isManualDisconnect = false
    private let reconnectDelayBase: TimeInterval = 2.0

    private let heartbeatInterval: TimeInterval = 15.0
    private let heartbeatQueue = DispatchQueue(label: "com.hyperate.heartbeat", qos: .userInteractive)

    // OSLog logger
    private let logger = Logger(subsystem: "com.hyperate.HypeRateOnMac", category: "HeartRateService")

    // MARK: - Connection

    func connect(deviceId: String) {
        // Check network connectivity first
        guard NetworkMonitor.shared.isConnected else {
            logger.error("Connection failed: No network connection")
            DispatchQueue.main.async {
                self.connectionState = .error("No network connection")
            }
            return
        }

        self.deviceId = deviceId

        logger.debug("Starting connection...")
        logger.debug("Device ID: \(deviceId)")

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
        logger.debug("Connection URL: wss://app.hyperate.io/ws/\(deviceId)")

        guard let url = URL(string: urlString) else {
            let errorMsg = "Invalid URL"
            logger.error("Error: \(errorMsg)")
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
        logger.debug("Starting WebSocket handshake...")
        webSocketTask?.resume()
    }

    func disconnect() {
        logger.debug("Starting manual disconnect")

        isManualDisconnect = true

        // Stop timers
        stopHeartbeat()
        stopReconnectTimer()

        logger.debug("Stopped heartbeat and reconnect timers")

        // Save current connection state for judgment
        let wasConnected = connectionState == .connected

        // Async update UI state
        DispatchQueue.main.async {
            self.connectionState = .disconnected
            self.currentHeartRate = nil
        }

        logger.debug("Requested state update to disconnected")

        // Only send close message when WebSocket is running
        if let task = webSocketTask, task.state == .running {
            if wasConnected {
                logger.debug("Sending leave message")
                sendLeaveMessage()
            } else {
                logger.debug("Close WebSocket directly")
                task.cancel(with: .normalClosure, reason: nil)
                webSocketTask = nil
            }
        } else {
            logger.debug("WebSocket not running, no need to close")
            webSocketTask = nil
        }

        reconnectAttempts = 0
        logger.info("Disconnect complete")
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
                self.logger.error("Message receive failed")
                self.logger.error("Error code: \(nsError.code)")
                self.logger.error("Error description: \(error.localizedDescription)")
                self.logger.debug("Error domain: \(nsError.domain)")

                if let failingURL = nsError.userInfo[NSURLErrorFailingURLErrorKey] as? URL {
                    self.logger.debug("Failed URL: \(failingURL.absoluteString)")
                }

                // Check if manual disconnect
                if self.isManualDisconnect {
                    self.logger.debug("Error from manual disconnect, ignore")
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
                logger.debug("Received message: event=\(event)")

                // Ignore system reply message
                if event == "phx_reply" {
                    logger.info("Received join confirmation")
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
                        logger.info("Heart rate update: \(hr) BPM")
                        DispatchQueue.main.async {
                            self.currentHeartRate = hr
                        }
                    }
                }
            }
        } catch {
            logger.error("Message parse failed: \(error.localizedDescription)")
            logger.debug("Message content: \(text)")

            // Update state to give user feedback
            DispatchQueue.main.async {
                self.connectionState = .error("Data format error")
            }

            // Try to reconnect
            self.scheduleReconnect()
        }
    }

    // MARK: - Send Messages

    private func sendJoinMessage() {
        logger.debug("Sending join message: hr:\(self.deviceId)")
        let message: [String: Any] = [
            "topic": "hr:\(deviceId)",
            "event": "phx_join",
            "payload": [:],
            "ref": "1"
        ]
        sendMessage(message)
    }

    private func sendLeaveMessage() {
        logger.debug("Sending leave message: hr:\(self.deviceId)")
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
            self.logger.debug("Closing WebSocket")
            self.webSocketTask?.cancel(with: .normalClosure, reason: nil)
            self.webSocketTask = nil
        }
    }

    private func sendHeartbeat() {
        logger.debug("Sending heartbeat")
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
                logger.debug("Sending: \(text)")
                webSocketTask?.send(.string(text)) { [weak self] error in
                    if let error = error {
                        self?.logger.error("Send message failed: \(error.localizedDescription)")
                    } else {
                        self?.logger.debug("Send success")
                    }
                }
            }
        } catch {
            logger.error("Message encoding failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Heartbeat

    private func startHeartbeat() {
        stopHeartbeat()
        logger.debug("Starting heartbeat timer (interval: \(self.heartbeatInterval)s)")

        // Create DispatchSourceTimer
        heartbeatTimer = DispatchSource.makeTimerSource(queue: heartbeatQueue)
        heartbeatTimer?.schedule(deadline: .now() + heartbeatInterval, repeating: heartbeatInterval)
        heartbeatTimer?.setEventHandler { [weak self] in
            self?.sendHeartbeat()
        }
        heartbeatTimer?.resume()

        logger.debug("Heartbeat timer started")
    }

    private func stopHeartbeat() {
        heartbeatTimer?.cancel()
        heartbeatTimer = nil
    }

    // MARK: - Reconnection

    private func scheduleReconnect() {
        // Move to main thread to ensure thread safety
        DispatchQueue.main.async {
            // Manual disconnect doesn't trigger auto-reconnect
            guard !self.isManualDisconnect else {
                self.logger.debug("Manual disconnect, don't trigger reconnect")
                return
            }

            // Prevent duplicate reconnect scheduling
            if self.connectionState == .connecting {
                self.logger.debug("Already in reconnecting state, skip duplicate call")
                return
            }

            guard self.reconnectAttempts < self.maxReconnectAttempts else {
                self.logger.warning("Reconnect attempts exceeded limit (\(self.maxReconnectAttempts) times)")
                self.connectionState = .error("Reconnect attempts exceeded")
                return
            }

            self.reconnectAttempts += 1
            let delay = min(self.reconnectDelayBase * pow(2.0, Double(self.reconnectAttempts - 1)), 60.0)

            self.logger.info("Scheduling reconnect (attempt \(self.reconnectAttempts)), \(delay) seconds until retry")
            self.connectionState = .connecting

            // Use DispatchSourceTimer for reconnect
            let reconnectQueue = DispatchQueue(label: "com.hyperate.reconnect", qos: .userInitiated)
            self.reconnectTimer = DispatchSource.makeTimerSource(queue: reconnectQueue)
            self.reconnectTimer?.schedule(deadline: .now() + delay, repeating: .never)
            self.reconnectTimer?.setEventHandler { [weak self] in
                guard let self = self else { return }
                self.logger.info("Starting reconnect...")
                self.connect(deviceId: self.deviceId)
            }
            self.reconnectTimer?.resume()
        }
    }

    private func stopReconnectTimer() {
        reconnectTimer?.cancel()
        reconnectTimer = nil
    }
}

// MARK: - URLSessionWebSocketDelegate

extension HeartRateService: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol subprotocol: String?) {
        logger.info("WebSocket handshake successful")
        if let subprotocol = subprotocol {
            logger.debug("Protocol: \(subprotocol)")
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
        logger.warning("WebSocket connection closed")
        logger.debug("Close code: \(closeCode.rawValue)")

        if let reason = reason, let reasonString = String(data: reason, encoding: .utf8) {
            logger.debug("Close reason: \(reasonString)")
        }

        // Check if manual disconnect
        if isManualDisconnect {
            logger.debug("Manual disconnect, keep disconnected state")
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
