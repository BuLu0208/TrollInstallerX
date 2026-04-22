//
//  MainView.swift
//  TrollInstallerX
//
//  Created by Alfie on 22/03/2024.
//

import SwiftUI

struct MainView: View {
    
    @State private var isInstalling = false
    
    @State private var device: Device = Device()
    
    @State private var isShowingMDCAlert = false
    @State private var isShowingOTAAlert = false
    @State private var isShowingHelperAlert = false
    
    @State private var isShowingSettings = false
    @State private var isShowingCredits = false
    
    @State private var installedSuccessfully = false
    @State private var installationFinished = false
    
    @ObservedObject var helperView = HelperAlert.shared
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ZStack {
                    LinearGradient(colors: [Color(hex: 0x1a1a2e), Color(hex: 0x16213e), Color(hex: 0x0f3460)], startPoint: .top, endPoint: .bottom)
                        .ignoresSafeArea()
                    VStack {
                        VStack {
                            Image("Icon")
                                .resizable()
                                .cornerRadius(22)
                                .frame(maxWidth: 100, maxHeight: 100)
                                .shadow(color: Color(hex: 0x533483).opacity(0.4), radius: 15)
                            Text("免挂梯子巨魔安装器")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text("开发者 TB：老司机巨魔 | 微信：BuLu-0208")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.4))
                                Text("TB：IOS巨魔王 | 微信：jiesuo66688")
                                Text("iOS 14.0 - 16.6.1 通用安装")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.35))
                        }
                        .padding(.vertical)
                        
                        if !isInstalling {
                            MenuView(isShowingSettings: $isShowingSettings, isShowingMDCAlert: $isShowingMDCAlert, isShowingOTAAlert: $isShowingOTAAlert, isShowingCredits: $isShowingCredits, device: device)
                                .frame(maxWidth: geometry.size.width / 1.2, maxHeight: geometry.size.height / 4)
                                .transition(.scale)
                                .padding()
                                .shadow(radius: 10)
                                .disabled(!device.isSupported)
                        }
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .foregroundColor(.white.opacity(0.06))
                                .frame(maxWidth: geometry.size.width / 1.2)
                                .frame(maxHeight: isInstalling ? geometry.size.height / 1.75 : 60)
                                .transition(.scale)
                                .shadow(radius: 10)
                            if isInstalling {
                                LogView(installationFinished: $installationFinished)
                                    .padding()
                                    .frame(maxWidth: geometry.size.width / 1.2)
                                    .frame(maxHeight: geometry.size.height / 1.75)
                            } else {
                                Button(action: {
                                    if !isShowingSettings && !isShowingMDCAlert && !isShowingOTAAlert && !isShowingCredits {
                                        UIImpactFeedbackGenerator().impactOccurred()
                                        withAnimation {
                                            isInstalling.toggle()
                                        }
                                    }
                                }, label: {
                                    Text(device.isSupported ? "安装 TrollStore" : "不支持")
                                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white)
                                        .padding()
                                        .frame(maxWidth: geometry.size.width / 1.2)
                                        .frame(maxHeight: 60)
                                })
                                .frame(maxWidth: geometry.size.width / 1.2)
                                .frame(maxHeight: 60)
                                .background(
                                    LinearGradient(colors: [Color(hex: 0x0f3460), Color(hex: 0x533483)], startPoint: .leading, endPoint: .trailing)
                                )
                                .cornerRadius(16)
                                .shadow(color: Color(hex: 0x533483).opacity(0.3), radius: 15)
                            }
                        }
                        .padding()
                        .disabled(!device.isSupported)
                    }
                    .blur(radius: (isShowingMDCAlert || isShowingOTAAlert || isShowingSettings || helperView.showAlert || isShowingCredits) ? 10 : 0)
                }
                
                if isShowingOTAAlert && !isShowingCredits {
                    PopupView(isShowingAlert: $isShowingOTAAlert $isShowingOTAAlert, content: {
                        TrollHelperOTAView(arm64eVersion: .constant(false))
                    })
                }
                
                if isShowingMDCAlert {
                    PopupView(isShowingAlert: $isShowingMDCAlert, shouldAllowDismiss: false, content: {
                        UnsandboxView(isShowingMDCAlert: $isShowingMDCAlert)
                    })
                }
                
                if isShowingSettings {
                    PopupView(isShowingAlert: $isShowingSettings, content: {
                        SettingsView(device: device)
                    })
                }

                if isShowingCredits {
                    PopupView(isShowingAlert: $isShowingCredits, content: {
                        CreditsView()
                    })
                }
                    })
                }
                
                if helperView.showAlert {
                    PopupView(isShowingAlert: $isShowingHelperAlert, shouldAllowDismiss: false, content: {
                        PersistenceHelperView(isShowingHelperAlert: $isShowingHelperAlert, allowNoPersistenceHelper: device.supportsDirectInstall)
                    })
                }
            }
            .onChange(of: helperView.showAlert) { new in
                if new {
                    withAnimation {
                        isShowingHelperAlert = true
                    }
                }
            }
            .onChange(of: isShowingHelperAlert) { new in
                if !new {
                    helperView.showAlert = false
                }
            }
            .onChange(of: isInstalling) { _ in
                Task {
                    if device.isSupported {
                        if device.supportsDirectInstall {
                            installedSuccessfully = await doDirectInstall(device)
                        } else {
                            installedSuccessfully = await doIndirectInstall(device)
                        }
                        installationFinished = true
                    }
                    UINotificationFeedbackGenerator().notificationOccurred(installedSuccessfully ? .success : .error)
                }
            }
            .onChange(of: isShowingOTAAlert) { new in
                if !new {
                    withAnimation {
                        isShowingMDCAlert = !checkForMDCUnsandbox() && MacDirtyCow.supports(device)
                    }
                }
            }
            .onAppear {
                if device.isSupported {
                    withAnimation {
                        isShowingOTAAlert = device.supportsOTA
                        if !isShowingOTAAlert && !isShowingCredits { isShowingMDCAlert = !checkForMDCUnsandbox() && MacDirtyCow.supports(device) }
                    }
                }
                Task {
                    await getUpdatedTrollStore()
                }
            }
            .onChange(of: isShowingOTAAlert) { _ in
                if !checkForMDCUnsandbox() && MacDirtyCow.supports(device) && !isShowingOTAAlert && device.supportsOTA {
                    withAnimation {
                        isShowingMDCAlert = true
                    }
                }
            }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}


