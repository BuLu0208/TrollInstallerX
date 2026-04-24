//
//  CreditsView.swift
//  TrollInstallerX
//

import SwiftUI

struct CreditsView: View {
    @State private var testResult: String = ""
    @State private var isSending: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Text("使用教程")
                    .font(.system(size: 23, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 30)
                    .padding(.bottom, 20)

                VStack(spacing: 16) {
                    // 1. 巨魔使用教程
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "book.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: 0x533483))
                            Text("巨魔使用教程")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.9))
                        }

                        Link(destination: URL(string: "https://www.yuque.com/yuqueyonghuroiej0/mucqna/wdnqeac20vyq2vq5?singleDoc#")!) {
                            HStack {
                                Text("点击查看巨魔使用教程")
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.7))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Color(hex: 0x533483))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(14)
                }
                .padding(.bottom, 30)
            }
        }

        // 测试数据上报
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: 0x533483))
                Text("数据上报测试")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
            }

            Button(action: {
                sendTestReport()
            }, label: {
                HStack {
                    if isSending {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                        Text("发送中...")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                    } else {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 14))
                        Text("发送测试数据")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.08))
                .cornerRadius(10)
            })

            if !testResult.isEmpty {
                Text(testResult)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(testResult.hasPrefix("✅") ? .green : .red)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 30)
    }

    private func sendTestReport() {
        isSending = true
        testResult = ""

        var systemInfo = utsname()
        uname(&systemInfo)
        let machine: String = withUnsafePointer(to: &systemInfo.machine) {
            String(cString: UnsafeRawPointer($0).assumingMemoryBound(to: CChar.self))
        }

        let payload: [String: Any] = [
            "type": "open",
            "device": machine,
            "model": UIDevice.current.model,
            "ios": UIDevice.current.systemVersion,
            "time": Int(Date().timeIntervalSince1970)
        ]

        guard let url = URL(string: "http://124.221.171.80/jumoapi/report.php") else {
            DispatchQueue.main.async { testResult = "❌ URL 构建失败"; isSending = false }
            return
        }

        var request = URLRequest(url: url, timeoutInterval: 10)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let data = try JSONSerialization.data(withJSONObject: payload)
            request.httpBody = data
            URLSession.shared.dataTask(with: request) { _, response, error in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isSending = false
                    if let error = error {
                        testResult = "❌ 网络错误: \(error.localizedDescription)"
                    } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                        testResult = "✅ 发送成功！请查看统计面板确认"
                    } else {
                        testResult = "❌ 服务器返回异常"
                    }
                }
            }.resume()
        } catch {
            DispatchQueue.main.async { testResult = "❌ JSON 序列化失败: \(error.localizedDescription)"; isSending = false }
        }
    }
}
}
