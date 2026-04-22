//
//  TrollInstallerXApp.swift
//  TrollInstallerX
//
//  Created by Alfie on 22/03/2024.
//

import SwiftUI

@main
struct TrollInstallerXApp: App {
    @AppStorage("kami_verified") private var isVerified: Bool = false
    
    var body: some Scene {
        WindowGroup {
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
