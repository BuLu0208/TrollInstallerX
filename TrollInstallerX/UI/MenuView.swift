//
//  MenuView.swift
//  TrollInstallerX
//

import SwiftUI

struct MenuView: View {
    @Binding var isShowingSettings: Bool
    @Binding var isShowingMDCAlert: Bool
    @Binding var isShowingOTAAlert: Bool
    @Binding var isShowingCredits: Bool
    let device: Device

    @State private var isTestingNetwork = false
    @State private var networkResult: String? = nil
    @State private var networkSpeed: String? = nil
    @State private var networkPing: String? = nil
    @State private var networkSuccess: Bool? = nil

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .foregroundColor(Color.white.opacity(0.08))

                VStack {
                    Button(action: {
                        if !isShowingSettings && !isShowingMDCAlert && !isShowingOTAAlert {
                            UIImpactFeedbackGenerator().impactOccurred()
                            withAnimation {
                                isShowingSettings = true
                            }
                        }
                    }, label: {
                        HStack {
                            Label(
                                title: {
                                    Text("设置")
                                        .font(.system(size: 17, weight: .regular, design: .rounded))
                                },
                                icon: { Image(systemName: "gear")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 22, height: 22)
                                        .padding(.trailing, 5)
                                }
                            )
                            .foregroundColor(device.isSupported ? .white.opacity(0.85) : .secondary)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.3))
                        }
                    })
                    .padding()
                    .frame(maxWidth: .infinity)

                    Button(action: {
                        if !isShowingSettings && !isShowingMDCAlert && !isShowingOTAAlert {
                            UIImpactFeedbackGenerator().impactOccurred()
                            withAnimation {
                                isShowingCredits = true
                            }
                        }
                    }, label: {
                        HStack {
                            Label(
                                title: {
                                    Text("使用教程")
                                        .font(.system(size: 17, weight: .regular, design: .rounded))
                                },
                                icon: { Image(systemName: "book")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 22, height: 22)
                                        .padding(.trailing, 5)
                                }
                            )
                            .foregroundColor(device.isSupported ? .white.opacity(0.85) : .secondary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.3))
                        }
                    })
                    .padding()
                    .frame(maxWidth: .infinity)

                    Button(action: {
                        testNetwork()
                    }, label: {
                        HStack {
                            if isTestingNetwork {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(width: 22, height: 22)
                                    .padding(.trailing, 5)
                                Text("检测中...")
                                    .font(.system(size: 17, weight: .regular, design: .rounded))
                                    .foregroundColor(.white.opacity(0.6))
                            } else {
                                Label(
                                    title: {
                                        Text("网络检测")
                                            .font(.system(size: 17, weight: .regular, design: .rounded))
                                    },
                                    icon: { Image(systemName: "network")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 22, height: 22)
                                            .padding(.trailing, 5)
                                    }
                                )
                                .foregroundColor(device.isSupported ? .white.opacity(0.85) : .secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.3))
                        }
                    })
                    .padding()
                    .frame(maxWidth: .infinity)

                    // 网络检测结果
                    if networkResult != nil {
                        HStack {
                            Image(systemName: networkSuccess == true ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(networkSuccess == true ? .green : .red)
                            Text(networkResult ?? "")
                                .font(.system(size: 13, weight: .regular, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)
                            if let speed = networkSpeed {
                                Text(speed)
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            if let ping = networkPing {
                                Text(ping)
                                    .font(.system(size: 13, weight: .regular, design: .rounded))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }
                }
                .padding()
            }
        }
    }

    private func testNetwork() {
        isTestingNetwork = true
        networkResult = nil
        networkSpeed = nil
        networkPing = nil
        networkSuccess = nil

        let testURL = URL(string: "https://github.lengye.top/download/iphone-kernelcache/network_test_5mb.json")!
        let startTime = Date()
        var connectedTime: Date? = nil

        var request = URLRequest(url: testURL)
        request.httpMethod = "HEAD"

        URLSession.shared.dataTask(with: request) { _, response, headError in
            connectedTime = Date()
            let ping = connectedTime.timeIntervalSince(startTime)

            DispatchQueue.main.async {
                networkPing = String(format: "延迟 %.1fs", ping)
            }

            let downloadRequest = URLRequest(url: testURL)
            URLSession.shared.dataTask(with: downloadRequest) { data, _, downloadError in
                let endTime = Date()
                let downloadTime = endTime.timeIntervalSince(connectedTime ?? startTime)
                let bytes = Double(data?.count ?? 0)
                let speed = bytes / downloadTime / 1024.0 / 1024.0

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isTestingNetwork = false

                    if downloadError != nil || data == nil || bytes < 1024 * 100 {
                        networkSuccess = false
                        if ping > 5 {
                            networkResult = "连接服务器超时，请检查网络或使用 VPN"
                        } else {
                            networkResult = "无法访问下载服务器"
                        }
                    } else {
                        networkSuccess = true
                        networkResult = "网络正常，可以安装巨魔"
                        if speed > 10 {
                            networkSpeed = String(format: "⚡ %.1f MB/s", speed)
                        } else if speed > 5 {
                            networkSpeed = String(format: "🚀 %.1f MB/s", speed)
                        } else if speed > 1 {
                            networkSpeed = String(format: "📱 %.1f MB/s", speed)
                        } else {
                            networkSpeed = String(format: "🐢 %.1f MB/s", speed)
                        }
                    }
                }
            }.resume()
        }.resume()
    }
}
