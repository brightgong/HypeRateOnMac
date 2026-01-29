import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: HeartRateViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var tempDeviceId: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var showSuccess: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            // 标题
            HStack {
                Text("设置")
                    .font(.system(size: 18, weight: .semibold))
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            // 说明文字
            VStack(alignment: .leading, spacing: 8) {
                Text("HypeRate 设备 ID")
                    .font(.system(size: 14, weight: .medium))
                
                Text("请输入你的 HypeRate 设备 ID（4位大写字母或数字）")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            
            // 输入框
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: "#FF3B30"))
                    
                    TextField("例如: EE6C", text: $tempDeviceId)
                        .font(.system(size: 16, weight: .medium))
                        .textFieldStyle(PlainTextFieldStyle())
                        .onChange(of: tempDeviceId) { newValue in
                            // 自动转换为大写
                            tempDeviceId = newValue.uppercased()
                            showError = false
                        }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(showError ? Color.red : Color.clear, lineWidth: 1)
                )
                
                if showError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                        Text(errorMessage)
                            .font(.system(size: 12))
                        Spacer()
                    }
                    .foregroundColor(.red)
                    .padding(.horizontal, 4)
                }
                
                if showSuccess {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                        Text("设置已保存，正在重新连接...")
                            .font(.system(size: 12))
                        Spacer()
                    }
                    .foregroundColor(Color(hex: "#34C759"))
                    .padding(.horizontal, 4)
                }
            }
            .padding(.horizontal, 20)
            
            // 当前 ID 显示
            HStack {
                Text("当前 ID:")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                Text(viewModel.deviceId)
                    .font(.system(size: 13, weight: .medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color(hex: "#007AFF").opacity(0.1))
                    .foregroundColor(Color(hex: "#007AFF"))
                    .cornerRadius(4)
                Spacer()
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // 按钮
            HStack(spacing: 12) {
                Button(action: { dismiss() }) {
                    Text("取消")
                        .font(.system(size: 14, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(PlainButtonStyle())
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
                
                Button(action: saveSettings) {
                    Text("保存")
                        .font(.system(size: 14, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(PlainButtonStyle())
                .background(Color(hex: "#007AFF"))
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .frame(width: 320, height: 280)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            tempDeviceId = viewModel.deviceId
        }
    }
    
    private func saveSettings() {
        showError = false
        showSuccess = false
        
        let trimmedId = tempDeviceId.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 验证输入
        if trimmedId.isEmpty {
            showError = true
            errorMessage = "请输入设备 ID"
            return
        }
        
        if trimmedId == viewModel.deviceId {
            dismiss()
            return
        }
        
        // 更新设置
        if viewModel.updateDeviceId(trimmedId) {
            showSuccess = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                dismiss()
            }
        } else {
            showError = true
            errorMessage = "ID 格式不正确，请输入 4 位大写字母或数字"
        }
    }
}
