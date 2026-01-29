import SwiftUI

struct MenuBarView: View {
    @ObservedObject var viewModel: HeartRateViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // 心率显示区域
            heartRateDisplay
            
            Divider()
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            
            // 状态显示
            statusView
            
            Divider()
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            
            // 操作按钮
            actionButtons
        }
        .padding(.vertical, 12)
        .frame(width: 260)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - 心率显示
    private var heartRateDisplay: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 32))
                    .foregroundColor(heartRateColor)
                    .symbolEffect(.pulse, options: .repeating, isActive: viewModel.isConnected && viewModel.currentHeartRate != nil)
                
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
    
    // MARK: - 操作按钮
    private var actionButtons: some View {
        VStack(spacing: 0) {
            Button(action: {
                viewModel.isSettingsPresented = true
            }) {
                HStack {
                    Image(systemName: "gear")
                        .font(.system(size: 14))
                    Text("设置")
                        .font(.system(size: 14))
                    Spacer()
                }
                .foregroundColor(.primary)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(Color.primary.opacity(0.0001)) // 确保可点击
            .onHover { isHovered in
                if isHovered {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
            
            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                HStack {
                    Image(systemName: "power")
                        .font(.system(size: 14))
                    Text("退出")
                        .font(.system(size: 14))
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
        .sheet(isPresented: $viewModel.isSettingsPresented) {
            SettingsView(viewModel: viewModel)
        }
    }
    
    // MARK: - 心率颜色
    private var heartRateColor: Color {
        guard let heartRate = viewModel.currentHeartRate else {
            return .gray
        }
        
        if heartRate > 120 {
            return Color(hex: "#FF3B30") // 高心率红色
        } else if heartRate > 100 {
            return Color(hex: "#FF9500") // 偏高心率橙色
        } else {
            return Color(hex: "#FF3B30") // 正常心率红色
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
