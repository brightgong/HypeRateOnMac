import Foundation
import OSLog

/// Configuration manager for loading sensitive values from xcconfig
enum AppConfig {

    private static let logger = Logger(subsystem: "com.hyperate.HypeRateOnMac", category: "AppConfig")

    /// HypeRate API key loaded from Secrets.xcconfig
    /// Falls back to environment variable or empty string if not configured
    static var hyperateApiKey: String {
        // First try to read from Info.plist (set via xcconfig)
        if let key = Bundle.main.infoDictionary?["HYPERATE_API_KEY"] as? String,
           !key.isEmpty,
           key != "$(HYPERATE_API_KEY)" {
            logger.debug("API key loaded from Info.plist")
            return key
        }

        // Fallback to environment variable
        if let key = ProcessInfo.processInfo.environment["HYPERATE_API_KEY"],
           !key.isEmpty {
            logger.debug("API key loaded from environment variable")
            return key
        }

        // Fallback to reading from config file directly (for development)
        if let key = loadFromSecretsFile() {
            logger.debug("API key loaded from Secrets.xcconfig file")
            return key
        }

        logger.warning("API key not found in any configuration source")
        return ""
    }

    /// Check if API key is configured
    static var isApiKeyConfigured: Bool {
        !hyperateApiKey.isEmpty
    }

    /// Load API key from Secrets.xcconfig file directly (development fallback)
    private static func loadFromSecretsFile() -> String? {
        let fileManager = FileManager.default

        // Build a list of possible paths where Secrets.xcconfig might be located
        var possiblePaths: [URL] = []

        // 1. Check SOURCE_ROOT if available (set during build)
        if let sourceRoot = ProcessInfo.processInfo.environment["SOURCE_ROOT"] {
            possiblePaths.append(URL(fileURLWithPath: sourceRoot).appendingPathComponent("Secrets.xcconfig"))
        }

        // 2. Try common development paths
        let homeDir = FileManager.default.homeDirectoryForCurrentUser

        // Check CodeBuddy directory (common development location)
        possiblePaths.append(homeDir.appendingPathComponent("CodeBuddy/HypeRateOnMac/Secrets.xcconfig"))

        // Check Desktop and Documents
        possiblePaths.append(homeDir.appendingPathComponent("Desktop/HypeRateOnMac/Secrets.xcconfig"))
        possiblePaths.append(homeDir.appendingPathComponent("Documents/HypeRateOnMac/Secrets.xcconfig"))
        possiblePaths.append(homeDir.appendingPathComponent("Developer/HypeRateOnMac/Secrets.xcconfig"))

        // 3. Try paths relative to the app bundle (for production builds)
        let bundlePath = Bundle.main.bundlePath
        let bundleURL = URL(fileURLWithPath: bundlePath)

        // When running from DerivedData, go up to find the project
        // DerivedData/.../Build/Products/Debug/App.app -> need to find project elsewhere
        possiblePaths.append(bundleURL.appendingPathComponent("Contents/Resources/Secrets.xcconfig"))

        // 4. Try current working directory
        let currentDir = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        possiblePaths.append(currentDir.appendingPathComponent("Secrets.xcconfig"))

        for path in possiblePaths {
            logger.debug("Checking for config at: \(path.path)")
            if fileManager.fileExists(atPath: path.path),
               let contents = try? String(contentsOf: path, encoding: .utf8) {
                logger.debug("Found config file at: \(path.path)")
                // Parse xcconfig format: KEY = VALUE
                let lines = contents.components(separatedBy: .newlines)
                for line in lines {
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    // Skip comments
                    if trimmed.hasPrefix("//") { continue }
                    if trimmed.hasPrefix("HYPERATE_API_KEY") {
                        let parts = trimmed.components(separatedBy: "=")
                        if parts.count >= 2 {
                            let value = parts.dropFirst().joined(separator: "=").trimmingCharacters(in: .whitespaces)
                            if !value.isEmpty && value != "YOUR_API_KEY_HERE" {
                                return value
                            }
                        }
                    }
                }
            }
        }

        return nil
    }
}
