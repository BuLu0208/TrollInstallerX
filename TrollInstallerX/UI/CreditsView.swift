//
//  CreditsView.swift
//  TrollInstallerX
//

import SwiftUI

struct CreditsView: View {
    private func showCopyAlert(_ title: String, message: String) {
        guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else { return }
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好的", style: .cancel))
        window.rootViewController?.present(alert, animated: true)
    }

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

                // ========== 广告区域 ==========
                VStack(spacing: 14) {
                    // 开发者广告
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "person.badge.key.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: 0x533483))
                            Text("开发者冷夜~招收代理 · 定制巨魔开发")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.9))
                        }

                        Button(action: {
                            UIPasteboard.general.string = "BuLu-0208"
                            showCopyAlert("已复制", message: "微信号 BuLu-0208 已复制，去微信添加好友（备注问题）")
                        }) {
                            HStack {
                                Text("📋 点击复制微信号添加好友")
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

                    // 代理商广告
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "tag.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Color.orange.opacity(0.8))
                            Text("巨魔工作室 定制")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.9))
                        }

                        Button(action: {
                            UIPasteboard.general.string = "巨魔工作室"
                            showCopyAlert("已复制", message: "巨魔工作室 已复制，去闲鱼搜索吧！")
                        }) {
                            HStack {
                                Text("📋 点击复制去闲鱼搜索")
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
}
