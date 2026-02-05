import SwiftUI

struct MenuBarView: View {
    @ObservedObject var viewModel: HeartRateViewModel
    @State private var showDeviceIdEditor: Bool = false

    var body: some View {
        VStack(spacing: 16) {
            // Heart rate status card
            HeartRateCard(viewModel: viewModel)

            // Control panel card
            ControlPanelCard(
                viewModel: viewModel,
                onEditDeviceId: { showDeviceIdEditor = true }
            )

            // Exit button
            ExitButton()
        }
        .padding(16)
        .frame(width: 320)
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: $showDeviceIdEditor) {
            DeviceIdEditorSheet(
                viewModel: viewModel,
                isPresented: $showDeviceIdEditor
            )
        }
    }
}

// MARK: - Heart Rate Card
struct HeartRateCard: View {
    @ObservedObject var viewModel: HeartRateViewModel

    var body: some View {
        VStack(spacing: 16) {
            // 心率显示
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: heartRateIcon)
                        .font(.system(size: 40))
                        .foregroundColor(heartRateColor)

                    Text(viewModel.heartRateDisplay)
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundColor(heartRateColor)
                }

                Text("BPM")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)

            // 状态指示器
            HStack(alignment: .top, spacing: 8) {
                Circle()
                    .fill(Color(hex: viewModel.statusColor))
                    .frame(width: 10, height: 10)
                    .padding(.top, 3)

                Text(viewModel.connectionState.description)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.secondary.opacity(0.06))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }

    private var heartRateIcon: String {
        switch viewModel.connectionState {
        case .connected: return "heart.fill"
        case .connecting: return "heart.fill"
        case .disconnected: return "heart.slash"
        case .error: return "heart.slash"
        }
    }

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
                return Color(hex: "#34C759")
            }
        case .connecting: return Color(hex: "#FF9500")
        case .disconnected: return Color(hex: "#8E8E93")
        case .error: return Color(hex: "#FF3B30")
        }
    }
}

// MARK: - Control Panel Card
struct ControlPanelCard: View {
    @ObservedObject var viewModel: HeartRateViewModel
    let onEditDeviceId: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title
            HStack {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)

                Text("Control Panel")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 4)

            // Device ID
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("DEVICE ID")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)

                    Text(viewModel.deviceId.isEmpty ? "Not set" : viewModel.deviceId)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(viewModel.deviceId.isEmpty ? .secondary : .primary)
                }

                Spacer()

                Button(action: onEditDeviceId) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.vertical, 8)

            // Connection button
            Button(action: { viewModel.toggleConnection() }) {
                HStack {
                    Image(systemName: viewModel.isConnected ? "bolt.slash.fill" : "bolt.fill")
                        .font(.system(size: 14))

                    Text(viewModel.isConnected ? "Disconnect" : "Connect")
                        .font(.system(size: 14, weight: .semibold))

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(viewModel.isConnected ? Color(hex: "#FF3B30") : Color(hex: "#34C759"))
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.secondary.opacity(0.06))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Exit Button
struct ExitButton: View {
    var body: some View {
        Button(action: {
            NSApplication.shared.terminate(nil)
        }) {
            HStack {
                Spacer()

                Image(systemName: "power")
                    .font(.system(size: 13))

                Text("Quit App")
                    .font(.system(size: 13, weight: .medium))

                Spacer()
            }
            .foregroundColor(.red)
            .padding(.vertical, 10)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { isHovered in
            if isHovered {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

// MARK: - Device ID Editor Sheet
struct DeviceIdEditorSheet: View {
    @ObservedObject var viewModel: HeartRateViewModel
    @Binding var isPresented: Bool
    @State private var localDeviceId: String = ""
    @State private var showError: Bool = false

    var body: some View {
        VStack(spacing: 24) {
            // Title section
            VStack(spacing: 8) {
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 48))
                    .foregroundColor(Color(hex: "#FF3B30"))

                Text("Set Device ID")
                    .font(.system(size: 20, weight: .bold))

                Text("Enter your HypeRate device ID to start monitoring")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 8)

            // Input field
            VStack(alignment: .leading, spacing: 8) {
                TextField("e.g.: abc123", text: $localDeviceId)
                    .font(.system(size: 16))
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.secondary.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(showError ? Color.red : Color.clear, lineWidth: 2)
                            )
                    )

                if showError {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 12))
                        Text("Please enter a valid device ID")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.red)
                }
            }

            // Button group
            VStack(spacing: 12) {
                Button(action: saveDeviceId) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                        Text("Save and Connect")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: "#007AFF"))
                    )
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: { isPresented = false }) {
                    Text("Cancel")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(32)
        .frame(width: 380)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(NSColor.windowBackgroundColor))
        )
        .onAppear {
            localDeviceId = viewModel.deviceId
        }
    }

    private func saveDeviceId() {
        showError = false
        if viewModel.updateDeviceId(localDeviceId) {
            if viewModel.isConnected {
                viewModel.reconnect()
            } else if !localDeviceId.isEmpty {
                viewModel.connect()
            }
            isPresented = false
        } else {
            showError = true
        }
    }
}

// MARK: - Color Extension
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
