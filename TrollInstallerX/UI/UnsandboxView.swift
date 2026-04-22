//
//  UnsandboxView.swift
//  TrollInstallerX
//
//  Created by Alfie on 26/03/2024.
//

import SwiftUI

struct UnsandboxView: View {
    @Binding var isShowingMDCAlert: Bool
    var body: some View {            
        VStack {
                Text("解除沙盒记得点好！")
                    .font(.system(size: 23, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding()
                Text(" 点击下面的解除沙盒然后记得点好！不要点错这样最方便快速度就可以安装上巨魔。")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                Button(action: {
                    UIImpactFeedbackGenerator().impactOccurred()
                    grant_full_disk_access({ error in
                        if let error = error {
                            Logger.log("利用 MacDirtyCow 漏洞失败")
                            NSLog("Failed to MacDirtyCow - \(error.localizedDescription)")
                        }
                        withAnimation {
                            isShowingMDCAlert = false
                        }
                    })
                }, label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .frame(width: 175, height: 45)
                            .foregroundColor(.white.opacity(0.2))
                            .shadow(radius: 10)
                        Text("解除沙盒")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .padding()
                    }
                })
                .padding(.vertical)
            }
    }
}
