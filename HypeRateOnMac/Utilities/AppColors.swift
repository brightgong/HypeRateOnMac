import Foundation

enum AppColors {
    // MARK: - Connection Status Colors
    static let connected = "#34C759"      // Green
    static let connecting = "#FF9500"     // Orange
    static let disconnected = "#8E8E93"   // Gray
    static let error = "#FF3B30"          // Red

    // MARK: - Heart Rate Colors
    static let heartRateNormal = "#34C759"    // <100 BPM
    static let heartRateElevated = "#FF9500"  // 100-120 BPM
    static let heartRateHigh = "#FF3B30"      // >120 BPM

    // MARK: - UI Colors
    static let buttonPrimary = "#007AFF"
}
