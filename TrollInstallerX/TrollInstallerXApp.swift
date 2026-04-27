//
//  TrollInstallerXApp.swift
//  TrollInstallerX
//
//  Created by Alfie on 22/03/2024.
//  Modified: 启动时备份上次日志
//

import SwiftUI

@main
struct TrollInstallerXApp: App {
    @AppStorage("kami_verified") private var isVerified: Bool = false
    
    init() {
        // App 启动时立即备份旧日志
        Logger.preservePreviousLogs()
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if isVerified {
                    MainView()
                        .preferredColorScheme(.dark)
                } else {
                    KamiVerifyView(onVerified: {
                        isVerified = true
                    })
                    .preferredColorScheme(.dark)
                }
            }
        }
    }
}
