import Foundation
import Combine

/// Protocol for heart rate monitoring service
/// Allows dependency injection and easier testing
protocol HeartRateServiceProtocol: AnyObject {
    var currentHeartRate: Int? { get }
    var connectionState: ConnectionState { get }
    var currentHeartRatePublisher: Published<Int?>.Publisher { get }
    var connectionStatePublisher: Published<ConnectionState>.Publisher { get }

    func connect(deviceId: String)
    func disconnect()
}
