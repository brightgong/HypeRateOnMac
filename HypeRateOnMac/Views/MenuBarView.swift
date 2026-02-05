import SwiftUI

struct MenuBarView: View {
    @ObservedObject var viewModel: HeartRateViewModel
    @State private var showDeviceIdEdit: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // 心率显示区域
            heartRateDisplay

            Divider()
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

            // 设备 ID 配置
            deviceIdSection

            Divider()
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

            // 连接开关
            connectionToggle

            Divider()
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

            // 状态显示
            statusView

            Divider()
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

            // 退出按钮
            quitButton
        }
        .padding(.vertical, 12)
        .frame(width: 300)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - 心率显示
    private var heartRateDisplay: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: heartRateIcon)
                    .font(.system(size: 32))
                    .foregroundColor(heartRateColor)

                Text(viewModel.heartRateDisplay)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(heartRateColor)
                    .frame(minWidth: 80, alignment: .leading)
            }

            Text("BPM")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
    
    // MARK: - 状态显示
    private var statusView: some View {
        HStack {
            Circle()
                .fill(Color(hex: viewModel.statusColor))
                .frame(width: 8, height: 8)
            
            Text(viewModel.connectionState.description)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("ID: \(viewModel.deviceId)")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(4)
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - 设备 ID 配置
    private var deviceIdSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("设备 ID")
                    .font(.system(size: 13, weight: .medium))
                Spacer()
                Button(action: { showDeviceIdEdit.toggle() }) {
                    Image(systemName: showDeviceIdEdit ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }

            if showDeviceIdEdit {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "#FF3B30"))

                        TextField("例如: abc123", text: $viewModel.deviceIdInput)
                            .font(.system(size: 13))
                            .textFieldStyle(PlainTextFieldStyle())
                            .onSubmit {
                                saveDeviceId()
                            }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.secondary.opacity(0.1))
                    )

                    HStack(spacing: 8) {
                        Button(action: saveDeviceId) {
                            Text("保存")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(Color(hex: "#007AFF"))
                                .cornerRadius(6)
                        }
                        .buttonStyle(PlainButtonStyle())

                        Spacer()
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
                Text(viewModel.deviceId.isEmpty ? "未设置" : viewModel.deviceId)
                    .font(.system(size: 13))
                    .foregroundColor(viewModel.deviceId.isEmpty ? .secondary : .primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.secondary.opacity(0.05))
                    )
            }
        }
        .padding(.horizontal, 16)
    }

    private func saveDeviceId() {
        if viewModel.updateDeviceId(viewModel.deviceIdInput) {
            if viewModel.isConnected {
                viewModel.reconnect()
            }
            showDeviceIdEdit = false
        }
    }

    // MARK: - 连接开关
    private var connectionToggle: some View {
        HStack {
            Text("连接")
                .font(.system(size: 13))

            Spacer()

            Button(action: { viewModel.toggleConnection() }) {
                HStack(spacing: 6) {
                    Image(systemName: viewModel.isConnected ? "power" : "power")
                        .font(.system(size: 12))
                    Text(viewModel.isConnected ? "断开" : "连接")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(viewModel.isConnected ? .white : .white)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(viewModel.isConnected ? Color(hex: "#FF3B30") : Color(hex: "#34C759"))
                .cornerRadius(6)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - 退出按钮
    private var quitButton: some View {
        Button(action: {
            NSApplication.shared.terminate(nil)
        }) {
            HStack {
                Image(systemName: "power")
                    .font(.system(size: 13))
                Text("退出")
                    .font(.system(size: 13))
                Spacer()
            }
            .foregroundColor(.red)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(Color.primary.opacity(0.0001))
        .onHover { isHovered in
            if isHovered {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }

    // MARK: - 心率图标
    private var heartRateIcon: String {
        switch viewModel.connectionState {
        case .connected:
            return "heart.fill"
        case .connecting:
            return "heart.fill"
        case .disconnected:
            return "heart.slash"
        case .error:
            return "heart.slash"
        }
    }

    // MARK: - 心率颜色
    private var heartRateColor: Color {
        switch viewModel.connectionState {
        case .connected:
            guard let heartRate = viewModel.currentHeartRate else {
                return Color(hex: "#8E8E93")
            }
            if heartRate > 120 {
                return Color(hex: "#FF3B30")
            } else if heartRate > 100 {
                return Color(hex: "#FF9500")
            } else {
                return Color(hex: "#FF3B30")
            }
        case .connecting:
            return Color(hex: "#FF9500")
        case .disconnected:
            return Color(hex: "#8E8E93")
        case .error:
            return Color(hex: "#FF3B30")
        }
    }
}

// MARK: - Color 扩展
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
