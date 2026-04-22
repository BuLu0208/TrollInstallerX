//
//  KamiVerifyView.swift
//  TrollInstallerX
//

import SwiftUI

struct KamiVerifyView: View {
    @State private var kamiInput: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
    @State private var shimmer: Bool = false
    @State private var copiedMsg: String = ""
    @State private var copiedTimer: Timer?
    
    let onVerified: () -> Void
    
    private var deviceCode: String {
        var buf = [UInt8](repeating: 0, count: 256)
        var size = buf.count
        sysctlbyname("hw.serialnumber", &buf, &size, nil, 0)
        var serial = String(cString: buf).trimmingCharacters(in: .controlCharacters)
        
        if serial.isEmpty {
            var utsinfo = utsname()
            uname(&utsinfo)
            serial = String(bytes: Data(bytes: &utsinfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii)!.trimmingCharacters(in: .controlCharacters)
        }
        return serial
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
                        
                        Text("免挂梯子巨魔安装器")
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
                        
                        Rectangle()
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 1)
                            .padding(.horizontal, 24)
                        
                        VStack(spacing: 10) {
                            Text("🎮 游戏科技 王者 和平可联系下方微信")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Link(destination: URL(string: "https://www.820faka.cn//details/180476F2")!) {
                                HStack(spacing: 6) {
                                    Image(systemName: "cart.badge.plus")
                                        .font(.system(size: 11))
                                        .foregroundColor(Color(hex: 0x533483))
                                    Text("点此购买卡密")
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .underline()
                                        .foregroundColor(Color(hex: 0x533483))
                                }
                            }
                        }
                        
                        Rectangle()
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 1)
                            .padding(.horizontal, 24)
                        
                        VStack(spacing: 10) {
                            HStack(spacing: 6) {
                                Image(systemName: "bag.badge.plus")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(hex: 0x533483))
                                Text("获取卡密 TB：老司机巨魔 丸 IOS巨魔王")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.55))
                            }
                            
                            Button(action: {
                                UIPasteboard.general.string = "BuLu-0208"
                                showCopied(msg: "BuLu-0208")
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "message.fill")
                                        .font(.system(size: 11))
                                        .foregroundColor(Color.green.opacity(0.6))
                                    Text("开发者微信：BuLu-0208（点击复制）")
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundColor(.white.opacity(0.55))
                                }
                            }
                            
                            Button(action: {
                                UIPasteboard.general.string = "jiesuo66688"
                                showCopied(msg: "jiesuo66688")
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "headphones")
                                        .font(.system(size: 11))
                                        .foregroundColor(Color.orange.opacity(0.6))
                                    Text("联系微信：jiesuo66688（点击复制）")
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundColor(.white.opacity(0.55))
                                }
                            }
                        }
                        
                        if !copiedMsg.isEmpty {
                            Text(copiedMsg)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(Color.green.opacity(0.9))
                                .transition(.opacity)
                                .padding(.bottom, 24)
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
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    shimmer.toggle()
                }
            }
        }
    }
    
    private func showCopied(msg: String) {
        copiedMsg = "已复制 \(msg)，前往微信搜索添加"
        copiedTimer?.invalidate()
        copiedTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { _ in
            DispatchQueue.main.async {
                copiedMsg = ""
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
        
        var components = URLComponents(string: "http://124.221.171.80/api.php")!
        components.queryItems = [
            URLQueryItem(name: "api", value: "kmlogon"),
            URLQueryItem(name: "app", value: "10002"),
            URLQueryItem(name: "kami", value: kami),
            URLQueryItem(name: "markcode", value: deviceCode)
        ]
        
        guard let url = components.url else {
            errorMessage = "请求构建失败"
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url, timeoutInterval: 10)
        request.setValue("TrollInstallerX/1.0", forHTTPHeaderField: "User-Agent")
        
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
                
                if let code = json["code"] as? Int, code == 200 {
                    self.onVerified()
                } else {
                    self.errorMessage = json["msg"] as? String ?? "卡密验证失败"
                    self.kamiInput = ""
                }
            }
        }.resume()
    }
}
