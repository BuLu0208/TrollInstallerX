//
//  KamiVerifyView.swift
//  TrollInstallerX
//

import SwiftUI

struct KamiVerifyView: View {
    @State private var kamiInput: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
    
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
                LinearGradient(colors: [Color(hex: 0x0482d1), Color(hex: 0x0566ed)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Spacer()
                    
                    Image("Icon")
                        .resizable()
                        .cornerRadius(22)
                        .frame(width: 80, height: 80)
                        .shadow(radius: 10)
                    
                    Text("TrollInstallerX")
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("请输入卡密以继续使用")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                    
                    VStack(spacing: 12) {
                        TextField("请输入卡密", text: $kamiInput)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal, 30)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .font(.system(size: 16, design: .rounded))
                        
                        Button(action: {
                            verifyKami()
                        }) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Text("验证")
                                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.blue.opacity(0.6))
                            )
                        }
                        .padding(.horizontal, 30)
                        .disabled(isLoading || kamiInput.trimmingCharacters(in: .whitespaces).isEmpty)
                        
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(.system(size: 13, weight: .regular, design: .rounded))
                                .foregroundColor(.red)
                                .padding(.horizontal, 30)
                                .transition(.opacity)
                        }
                    }
                    
                    Spacer()
                    
                    Text("设备标识: \(deviceCode)")
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .foregroundColor(.white.opacity(0.3))
                        .padding(.bottom, 20)
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
        
        var components = URLComponents(string: "http://124.221.171.80/api.php")!
        components.queryItems = [
            URLQueryItem(name: "api", value: "kmlogon"),
            URLQueryItem(name: "app", value: "10003"),
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

