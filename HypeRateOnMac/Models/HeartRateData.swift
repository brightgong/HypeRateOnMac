import Foundation

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
            return AppColors.disconnected
        case .connecting:
            return AppColors.connecting
        case .connected:
            return AppColors.connected
        case .error:
            return AppColors.error
        }
    }
}
