import SwiftUI
import AppKit

@main
struct HypeRateOnMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarManager: MenuBarManager?
    private var viewModel: HeartRateViewModel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize ViewModel
        viewModel = HeartRateViewModel()

        // Initialize menu bar manager
        if let viewModel = viewModel {
            menuBarManager = MenuBarManager(viewModel: viewModel)
        }

        // Check if configured, if so auto-connect
        if let deviceId = viewModel?.deviceId, !deviceId.isEmpty {
            viewModel?.connect()
        }
    }
}
