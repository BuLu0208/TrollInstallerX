//
//  CreditsView.swift
//  TrollInstallerX
//

import SwiftUI

struct CreditsView: View {
    @State private var copiedMsg: String = ""
    @State private var copiedTimer: Timer?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Text("使用教程")
                    .font(.system(size: 23, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 30)
                    .padding(.bottom, 20)

                VStack(spacing: 16) {
                    // 1. 开发者联系方式
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "message.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Color.green.opacity(0.7))
                            Text("开发者联系方式（有问题添加没事别加！）")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.9))
                        }

                        Button(action: {
                            UIPasteboard.general.string = "BuLu-0208"
                            showCopied("BuLu-0208")
                        }) {
                            HStack(spacing: 8) {
                                Text("微信：BuLu-0208")
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.7))
                                Spacer()
                                Text("点击复制")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundColor(Color(hex: 0x533483))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(10)
                        }

                        if !copiedMsg.isEmpty {
                            Text(copiedMsg)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(Color.green.opacity(0.9))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(14)

                    // 2. 巨魔使用教程
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

                    // 3. 卡密购买
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "cart.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Color.orange.opacity(0.7))
                            Text("购买卡密")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.9))
                        }

                        Link(destination: URL(string: "https://www.820faka.cn//details/180476F2")!) {
                            HStack {
                                Text("点击购买卡密")
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.7))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Color.orange.opacity(0.6))
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
        .background(
            LinearGradient(
                colors: [Color(hex: 0x1a1a2e), Color(hex: 0x16213e), Color(hex: 0x0f3460)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private func showCopied(_ wechat: String) {
        copiedMsg = "已复制 " + wechat + "，前往微信搜索添加"
        copiedTimer?.invalidate()
        copiedTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { _ in
            DispatchQueue.main.async {
                copiedMsg = ""
            }
        }
    }
}
