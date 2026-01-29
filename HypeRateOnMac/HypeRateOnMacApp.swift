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
        statusItem = NSStatusBar.shared.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.action = #selector(togglePopover)
            button.target = self
            updateMenuBarDisplay()
        }
        
        // 创建 Popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 280, height: 200)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: MenuBarView(viewModel: viewModel)
        )
        
        // 监听心率变化更新菜单栏
        viewModel.onHeartRateChange = { [weak self] in
            self?.updateMenuBarDisplay()
        }
        
        // 初始连接
        viewModel.connect()
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
        if let heartRate = viewModel.currentHeartRate {
            heartRateText = "\(heartRate)"
        } else {
            heartRateText = "--"
        }
        
        // 创建带图标的 attributed string
        let font = NSFont.systemFont(ofSize: 14, weight: .medium)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: viewModel.connectionState == .connected ? NSColor.label : NSColor.secondaryLabelColor
        ]
        
        let attributedString = NSMutableAttributedString(string: "❤️ ", attributes: attributes)
        attributedString.append(NSAttributedString(string: heartRateText, attributes: attributes))
        
        button.attributedTitle = attributedString
    }
}
