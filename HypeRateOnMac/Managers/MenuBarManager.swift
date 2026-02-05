import AppKit
import SwiftUI
import Combine

/// Menu bar manager: responsible for menu bar icon display and interaction
class MenuBarManager {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private weak var viewModel: HeartRateViewModel?
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: HeartRateViewModel) {
        self.viewModel = viewModel
        setupMenuBar()
        setupPopover()
        setupObservers()
    }

    // MARK: - Setup

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.action = #selector(togglePopover)
            button.target = self
            updateDisplay()
        }
    }

    private func setupPopover() {
        guard let viewModel = viewModel else { return }

        popover = NSPopover()
        popover?.contentSize = NSSize(width: 320, height: 300)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(
            rootView: MenuBarView(viewModel: viewModel)
        )
    }

    private func setupObservers() {
        // Listen to heart rate changes to update menu bar
        viewModel?.onHeartRateChange = { [weak self] in
            self?.updateDisplay()
        }

        // Listen to connection state changes to update menu bar
        viewModel?.$connectionState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateDisplay()
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    @objc func togglePopover() {
        guard let button = statusItem?.button,
              let popover = popover else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    func updateDisplay() {
        guard let button = statusItem?.button,
              let viewModel = viewModel else { return }

        let (icon, text, color) = getDisplayComponents(for: viewModel.connectionState,
                                                        heartRate: viewModel.currentHeartRate)

        let font = NSFont.systemFont(ofSize: 14, weight: .medium)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]

        let attributedString = NSMutableAttributedString(string: icon, attributes: attributes)
        attributedString.append(NSAttributedString(string: text, attributes: attributes))

        button.attributedTitle = attributedString
    }

    // MARK: - Private Methods

    /// 根据连接状态和心率获取显示组件
    private func getDisplayComponents(for state: ConnectionState, heartRate: Int?) -> (icon: String, text: String, color: NSColor) {
        switch state {
        case .connected:
            let icon = "❤️ "
            let text = heartRate.map { "\($0)" } ?? "--"
            let color = NSColor.textColor
            return (icon, text, color)

        case .connecting:
            let icon = "❤️ "
            let text = "--"
            let color = NSColor.orange
            return (icon, text, color)

        case .disconnected:
            let icon = "💔 "
            let text = "--"
            let color = NSColor.secondaryLabelColor
            return (icon, text, color)

        case .error:
            let icon = "💔 "
            let text = "--"
            let color = NSColor.red
            return (icon, text, color)
        }
    }
}
