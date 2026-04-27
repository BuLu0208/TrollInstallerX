//
//  KamiVerifyView.swift
//  TrollInstallerX
//

import SwiftUI
import CryptoKit

struct KamiVerifyView: View {
    @State private var kamiInput: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
    @State private var shimmer: Bool = false

    private func showCopyAlert(_ title: String, message: String) {
        guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else { return }
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好的", style: .cancel))
        window.rootViewController?.present(alert, animated: true)
    }
    
    let onVerified: () -> Void
    
    private var deviceCode: String {
        // Device fingerprint: combine multiple public hardware/software properties
        // Both TrollInstallerX and persistence helper can read these identically
        var parts: [String] = []

        // Hardware model
        var utsinfo = utsname()
        uname(&utsinfo)
        let machine = withUnsafePointer(to: &utsinfo.machine) { ptr in
            String(cString: UnsafeRawPointer(ptr).assumingMemoryBound(to: CChar.self))
        }.trimmingCharacters(in: .controlCharacters)
        parts.append(machine)

        // System version
        parts.append(UIDevice.current.systemVersion)

        // Physical memory (MB)
        let mem = ProcessInfo.processInfo.physicalMemory / (1024 * 1024)
        parts.append("\(mem)")

        // Screen size + scale
        let screen = UIScreen.main
        let w = Int(screen.nativeBounds.width)
        let h = Int(screen.nativeBounds.height)
        parts.append("\(w)x\(h)")
        parts.append("\(screen.scale)")

        // Processor count
        parts.append("\(ProcessInfo.processInfo.processorCount)")

        let raw = parts.joined(separator: "|")

        // SHA256 hash via CryptoKit, take first 16 chars
        let data = Data(raw.utf8)
        let digest = SHA256.hash(data: data)
        let hex = digest.prefix(8).map { String(format: "%02x", $0) }.joined()
        return hex
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    colors: [Color(hex: 0x1a1a2e), Color(hex: 0x16213e), Color(hex: 0x0f3460)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                Circle()
                    .fill(Color(hex: 0x533483).opacity(0.15))
                    .frame(width: 300, height: 300)
                    .blur(radius: 80)
                    .offset(y: -100)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: 0x533483), Color(hex: 0x0f3460)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 90, height: 90)
                                .shadow(color: Color(hex: 0x533483).opacity(0.5), radius: 20)
                            
                            Image("Icon")
                                .resizable()
                                .cornerRadius(20)
                                .frame(width: 70, height: 70)
                                .shadow(radius: 5)
                        }
                        
                        Text("免梯子巨魔安装器")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: Color.white.opacity(0.3), radius: 10)
                        
                        Text("请输入卡密以激活使用")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.bottom, 30)
                    
                    VStack(spacing: 20) {
                        Text("输入卡密以激活使用")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.top, 24)
                        
                        HStack(spacing: 12) {
                            TextField("请输入卡密", text: $kamiInput)
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                )
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 24)
                        
                        Button(action: {
                            verifyKami()
                        }) {
                            HStack(spacing: 8) {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.85)
                                } else {
                                    Image(systemName: "shield.checkered")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("验证激活")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                LinearGradient(
                                    colors: shimmer ? [Color(hex: 0x533483), Color(hex: 0x0f3460)] : [Color(hex: 0x0f3460), Color(hex: 0x533483)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .shadow(color: Color(hex: 0x533483).opacity(0.4), radius: 15)
                        }
                        .padding(.horizontal, 24)
                        .disabled(isLoading || kamiInput.trimmingCharacters(in: .whitespaces).isEmpty)
                        .opacity(isLoading || kamiInput.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1.0)
                        
                        if !errorMessage.isEmpty {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 12))
                                Text(errorMessage)
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                            }
                            .foregroundColor(.red.opacity(0.9))
                            .padding(.horizontal, 24)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                        
                        // ========== 广告区域 ==========
                        VStack(spacing: 12) {
                            Button(action: {
                                UIPasteboard.general.string = "BuLu-0208"
                                showCopyAlert("已复制", message: "微信号 BuLu-0208 已复制，去微信添加好友（备注问题）")
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "person.badge.key.fill")
                                        .font(.system(size: 13))
                                    Text("开发者冷夜~招收代理 · 定制巨魔开发")
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                        .foregroundColor(.white.opacity(0.85))
                                    Spacer()
                                    Image(systemName: "doc.on.doc")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color(hex: 0x533483).opacity(0.25))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color(hex: 0x533483).opacity(0.4), lineWidth: 1)
                                )
                            }

                            HStack(spacing: 6) {
                                Image(systemName: "tag.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color.orange.opacity(0.8))
                                Text("闲鱼搜：巨魔工作室 定制")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.7))
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.orange.opacity(0.08))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 24)

                        Rectangle()
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 1)
                            .padding(.horizontal, 24)
                        
                        Rectangle()
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 1)
                            .padding(.horizontal, 24)
                        
                        VStack(spacing: 10) {
                            HStack(spacing: 6) {
                                Image(systemName: "bag.badge.plus")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(hex: 0x533483))
                                Text("版 本 ：1.0")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.55))
                            }
                            
                            HStack(spacing: 6) {
                                Image(systemName: "bag.badge.plus")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color.green.opacity(0.6))
                                Text(" 基于TrollInstallerX项目开发实现免挂加速器安装巨魔 ")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.55))
                            }
                            
                            HStack(spacing: 6) {
                                Image(systemName: "bag.badge.plus")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color.orange.opacity(0.6))
                                Text("请确保给予WiFi和流量权限")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.55))
                            }
                        }
                        .padding(.bottom, 24)
                    }
                    .frame(maxWidth: geometry.size.width / 1.15)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.3), radius: 20)
                    .padding(.horizontal)
                    
                    Text("设备标识：\(deviceCode)")
                        .font(.system(size: 10, weight: .regular, design: .monospaced))
                        .foregroundColor(.white.opacity(0.2))
                        .padding(.top, 20)
                        .padding(.bottom, 16)
                    
                    Spacer()
                }
            }
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .onAppear { URLSession.shared.dataTask(with: URLRequest(url: URL(string: "http://captive.apple.com/hotspot-detect.html")!)) { _, _, _ in }.resume()
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    shimmer.toggle()
                }
            }
        }
    }
    
    private func verifyKami() {
        let kami = kamiInput.trimmingCharacters(in: .whitespaces)
        guard !kami.isEmpty else {
            errorMessage = "请输入卡密！"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        guard let url = URL(string: "https://kami.lengye.top/api/login") else {
            errorMessage = "请求构建失败"
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url, timeoutInterval: 10)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("TrollInstallerX/1.0", forHTTPHeaderField: "User-Agent")
        
        let body: [String: String] = [
            "appkey": "9VRZ0ATE1YKM",
            "card": kami,
            "device_id": deviceCode
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    if (error as NSError).code == NSURLErrorTimedOut {
                        self.errorMessage = "服务器连接超时，请检查网络"
                    } else if (error as NSError).code == NSURLErrorNotConnectedToInternet {
                        self.errorMessage = "无法连接服务器，请检查网络"
                    } else {
                        self.errorMessage = "网络请求失败：\(error.localizedDescription)"
                    }
                    return
                }
                
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    self.errorMessage = "服务器返回数据格式错误"
                    return
                }
                
                let code = json["code"] as? Int ?? -1
                let msg = json["msg"] as? String ?? ""
                
                if code == 0 {
                    reportAppOpen()
                    self.onVerified()
                } else if code == 1001 {
                    self.errorMessage = "设备不匹配，请先解绑后再验证"
                    self.kamiInput = ""
                } else if code == 1002 {
                    self.errorMessage = "卡密已过期，请续费或购买新卡密"
                    self.kamiInput = ""
                } else {
                    var errMsg = msg.isEmpty ? "卡密验证失败" : msg
                    if errMsg == "卡密不存在" { errMsg = "卡密无效，请检查后重试" }
                    else if errMsg == "卡密已禁用" { errMsg = "卡密已被禁用，请联系管理员" }
                    else if errMsg == "卡密已使用" { errMsg = "此卡密已使用，请获取新卡密" }
                    self.errorMessage = errMsg
                    self.kamiInput = ""
                }
            }
        }.resume()
    }
}
