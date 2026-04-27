//
//  SettingsView.swift
//  TrollInstallerX
//
//  Created by Alfie on 26/03/2024.
//  Modified: 添加日志管理按钮
//

import SwiftUI

struct SettingsView: View {
    
    let device: Device
    
    @AppStorage("exploitFlavour", store: TIXDefaults()) var exploitFlavour: String = ""
    @AppStorage("verbose", store: TIXDefaults()) var verbose: Bool = false
    @AppStorage("autoInstallHelper", store: TIXDefaults()) var autoInstallHelper: Bool = true
    
    @State private var hasLastRunLog = false
    @State private var hasLastStdoutLog = false
    
    var body: some View {
        VStack(spacing: 10) {
            Button(action: {
                UIImpactFeedbackGenerator().impactOccurred()
                let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                try? FileManager.default.removeItem(atPath: docsDir.path + "/kernelcache")
            }, label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .frame(maxWidth: 225)
                        .frame(maxHeight: 40)
                        .foregroundColor(.white.opacity(0.2))
                        .shadow(radius: 10)
                    Text("清除内核缓存")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding()
                }
            })
            .padding()
            if smith.supports(device) || physpuppet.supports(device) {
                Picker("Kernel exploit", selection: $exploitFlavour) {
                    Text("landa").foregroundColor(.white).tag("landa")
                    if smith.supports(device) {
                        Text("smith").foregroundColor(.white).tag("smith")
                    }
                    if physpuppet.supports(device) {
                        Text("physpuppet").foregroundColor(.white).tag("physpuppet")
                    }
                }
                .pickerStyle(.segmented)
                .colorMultiply(.white)
                .padding()
            }
            VStack {
                Toggle(isOn: $verbose, label: {
                    Text("详细日志记录")
                        .font(.system(size: 17, weight: .regular, design: .rounded))
                        .foregroundColor(.white)
                })
            }
            .padding()
            VStack {
                Toggle(isOn: $autoInstallHelper, label: {
                    Text("自动安装持久性助手")
                        .font(.system(size: 17, weight: .regular, design: .rounded))
                        .foregroundColor(.white)
                })
            }
            .padding()
            
            // ===== 日志管理 =====
            VStack(spacing: 8) {
                Text("日志记录")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.gray)
                    .padding(.top, 8)
                
                Button(action: { shareFile(Logger.currentLogURL) }, label: {
                    logButton("导出当前日志", icon: "doc.text", color: .white)
                })
                
                if verbose {
                    Button(action: { shareFile(Logger.stdoutLogURL) }, label: {
                        logButton("导出详细日志", icon: "doc.text.viewfinder", color: .white)
                    })
                }
                
                if hasLastRunLog {
                    Button(action: { shareFile(Logger.lastRunLogURL) }, label: {
                        logButton("查看上次运行日志", icon: "exclamationmark.triangle", color: .orange)
                    })
                }
                
                if hasLastStdoutLog {
                    Button(action: { shareFile(Logger.lastStdoutLogURL) }, label: {
                        logButton("查看上次详细日志", icon: "exclamationmark.triangle", color: .orange)
                    })
                }
                
                Button(action: { deleteAllLogs() }, label: {
                    logButton("清除所有日志", icon: "trash", color: .red)
                })
            }
            .padding(.horizontal)
        }
        .onAppear {
            if exploitFlavour == "" {
                exploitFlavour = physpuppet.supports(device) ? "physpuppet" : "landa"
            }
            hasLastRunLog = FileManager.default.fileExists(atPath: Logger.lastRunLogURL.path)
            hasLastStdoutLog = FileManager.default.fileExists(atPath: Logger.lastStdoutLogURL.path)
        }
    }
    
    private func logButton(_ title: String, icon: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .frame(maxWidth: 225)
                .frame(maxHeight: 40)
                .foregroundColor(color.opacity(0.2))
                .shadow(radius: 10)
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
            }
            .foregroundColor(color)
            .padding()
        }
    }
    
    private func shareFile(_ url: URL) {
        UIImpactFeedbackGenerator().impactOccurred()
        if !FileManager.default.fileExists(atPath: url.path) {
            try? "".write(to: url, atomically: true, encoding: .utf8)
        }
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        rootVC.present(vc, animated: true)
    }
    
    private func deleteAllLogs() {
        UIImpactFeedbackGenerator().impactOccurred()
        let fm = FileManager.default
        for url in [Logger.currentLogURL, Logger.lastRunLogURL, Logger.stdoutLogURL, Logger.lastStdoutLogURL] {
            try? fm.removeItem(at: url)
        }
        hasLastRunLog = false
        hasLastStdoutLog = false
    }
}
