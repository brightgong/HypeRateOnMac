import Foundation

protocol HeartRateServiceProtocol {
    var currentHeartRate: Int? { get }
    var connectionState: ConnectionState { get }
    var onHeartRateUpdate: ((Int) -> Void)? { get set }
    var onConnectionStateChange: ((ConnectionState) -> Void)? { get set }
    
    func connect(deviceId: String)
    func disconnect()
}

class HeartRateService: HeartRateServiceProtocol, ObservableObject {
    @Published var currentHeartRate: Int?
    @Published var connectionState: ConnectionState = .disconnected
    
    var onHeartRateUpdate: ((Int) -> Void)?
    var onConnectionStateChange: ((ConnectionState) -> Void)?
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var deviceId: String = ""
    private var reconnectAttempts = 0
    private var maxReconnectAttempts = 10
    private var reconnectTimer: Timer?
    private var heartbeatTimer: Timer?
    private var messageRef = 0
    
    private let webSocketURL = URL(string: "wss://app.hyperate.io/socket/websocket")!
    
    func connect(deviceId: String) {
        self.deviceId = deviceId
        disconnect()
        
        connectionState = .connecting
        onConnectionStateChange?(.connecting)
        
        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: webSocketURL)
        webSocketTask?.delegate = self
        
        webSocketTask?.resume()
        receiveMessage()
    }
    
    func disconnect() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
        
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        
        connectionState = .disconnected
        onConnectionStateChange?(.disconnected)
        currentHeartRate = nil
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                self.handleMessage(message)
                self.receiveMessage() // 继续接收下一条消息
                
            case .failure(let error):
                self.handleError(error.localizedDescription)
            }
        }
    }
    
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            handleTextMessage(text)
        case .data(let data):
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
            let message = try JSONDecoder().decode(PhoenixMessage.self, from: data)
            
            switch message.event {
            case PhoenixEvent.reply:
                // 连接成功响应
                if message.topic == ChannelTopic.heartRate(deviceId: deviceId) {
                    connectionState = .connected
                    onConnectionStateChange?(.connected)
                    reconnectAttempts = 0
                    startHeartbeat()
                }
                
            case PhoenixEvent.heartRateUpdate:
                // 心率更新
                if let payload = message.payload,
                   let heartRateValue = payload["heartrate"]?.value as? Int {
                    DispatchQueue.main.async { [weak self] in
                        self?.currentHeartRate = heartRateValue
                        self?.onHeartRateUpdate?(heartRateValue)
                    }
                }
                
            case PhoenixEvent.error:
                let errorMsg = message.payload?["reason"]?.value as? String ?? "未知错误"
                handleError(errorMsg)
                
            case PhoenixEvent.close:
                handleDisconnect()
                
            default:
                break
            }
            
        } catch {
            print("解析消息失败: \(error)")
        }
    }
    
    private func joinChannel() {
        let topic = ChannelTopic.heartRate(deviceId: deviceId)
        messageRef += 1
        
        let joinMessage = PhoenixMessage(
            topic: topic,
            event: PhoenixEvent.join,
            payload: [:],
            ref: String(messageRef)
        )
        
        sendMessage(joinMessage)
    }
    
    private func sendHeartbeat() {
        messageRef += 1
        
        let heartbeatMessage = PhoenixMessage(
            topic: "phoenix",
            event: PhoenixEvent.heartbeat,
            payload: [:],
            ref: String(messageRef)
        )
        
        sendMessage(heartbeatMessage)
    }
    
    private func sendMessage(_ message: PhoenixMessage) {
        do {
            let data = try JSONEncoder().encode(message)
            if let text = String(data: data, encoding: .utf8) {
                webSocketTask?.send(.string(text)) { error in
                    if let error = error {
                        print("发送消息失败: \(error)")
                    }
                }
            }
        } catch {
            print("编码消息失败: \(error)")
        }
    }
    
    private func startHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.sendHeartbeat()
        }
    }
    
    private func handleError(_ error: String) {
        DispatchQueue.main.async { [weak self] in
            self?.connectionState = .error(error)
            self?.onConnectionStateChange?(.error(error))
            self?.scheduleReconnect()
        }
    }
    
    private func handleDisconnect() {
        DispatchQueue.main.async { [weak self] in
            self?.connectionState = .disconnected
            self?.onConnectionStateChange?(.disconnected)
            self?.scheduleReconnect()
        }
    }
    
    private func scheduleReconnect() {
        guard reconnectAttempts < maxReconnectAttempts else {
            connectionState = .error("达到最大重连次数")
            onConnectionStateChange?(.error("达到最大重连次数"))
            return
        }
        
        reconnectAttempts += 1
        let delay = min(Double(reconnectAttempts) * 2.0, 30.0) // 指数退避，最大30秒
        
        reconnectTimer?.invalidate()
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            guard let self = self, !self.deviceId.isEmpty else { return }
            self.connect(deviceId: self.deviceId)
        }
    }
}

// MARK: - URLSessionWebSocketDelegate
extension HeartRateService: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        DispatchQueue.main.async { [weak self] in
            self?.joinChannel()
        }
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        DispatchQueue.main.async { [weak self] in
            self?.handleDisconnect()
        }
    }
}
