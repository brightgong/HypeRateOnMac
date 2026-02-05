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
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var viewModel: HeartRateViewModel!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 初始化 ViewModel
        viewModel = HeartRateViewModel()

        // 创建菜单栏图标
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.action = #selector(togglePopover)
            button.target = self
            updateMenuBarDisplay()
        }

        // 创建 Popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 280, height: 220)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: MenuBarView(viewModel: viewModel)
        )

        // 监听心率变化更新菜单栏
        viewModel.onHeartRateChange = { [weak self] in
            self?.updateMenuBarDisplay()
        }

        // 检查是否已配置，如果已配置则自动连接
        if !viewModel.deviceId.isEmpty {
            viewModel.connect()
        }
    }

    @objc func togglePopover() {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }

    func updateMenuBarDisplay() {
        guard let button = statusItem.button else { return }

        let heartRateText: String
        let heartRateIcon: String

        switch viewModel.connectionState {
        case .connected:
            heartRateIcon = "❤️ "
            if let heartRate = viewModel.currentHeartRate {
                heartRateText = "\(heartRate)"
            } else {
                heartRateText = "--"
            }
        case .connecting:
            heartRateIcon = "❤️ "
            heartRateText = "--"
        case .disconnected:
            heartRateIcon = "💔 "
            heartRateText = "--"
        case .error:
            heartRateIcon = "💔 "
            heartRateText = "--"
        }

        // 创建带图标的 attributed string
        let font = NSFont.systemFont(ofSize: 14, weight: .medium)
        let textColor: NSColor
        switch viewModel.connectionState {
        case .connected:
            textColor = NSColor.textColor
        case .connecting:
            textColor = NSColor.orange
        case .disconnected:
            textColor = NSColor.secondaryLabelColor
        case .error:
            textColor = NSColor.red
        }

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]

        let attributedString = NSMutableAttributedString(string: heartRateIcon, attributes: attributes)
        attributedString.append(NSAttributedString(string: heartRateText, attributes: attributes))

        button.attributedTitle = attributedString
    }
}
