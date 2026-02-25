import Foundation
import Network
import Combine

/// Network connectivity monitor using NWPathMonitor
/// Provides real-time network status updates
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    @Published var isConnected = true  // Default to true, will be updated immediately
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = (path.status == .satisfied)
            }
        }
        monitor.start(queue: queue)

        // Get initial state synchronously
        // The pathUpdateHandler will fire almost immediately after start
        // but we also check the current path
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.isConnected = (self?.monitor.currentPath.status == .satisfied)
        }
    }

    deinit {
        monitor.cancel()
    }
}
