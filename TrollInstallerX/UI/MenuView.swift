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
                }
                .padding()
            }
        }
    }
}
