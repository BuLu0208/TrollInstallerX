//
//  CreditsView.swift
//  TrollInstallerX
//

import SwiftUI

struct CreditsView: View {
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
