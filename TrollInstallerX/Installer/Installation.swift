//
//  Installation.swift
//  TrollInstallerX
//
//  Created by Alfie on 22/03/2024.
//  Modified: 每个关键步骤添加详细日志，便于排查死机原因
//

import SwiftUI

let fileManager = FileManager.default
let docsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
let docsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].path
let kernelPath = docsDir + "/kernelcache"


func checkForMDCUnsandbox() -> Bool {
    return fileManager.fileExists(atPath: docsDir + "/full_disk_access_sandbox_token.txt")
}

func getKernel(_ device: Device) -> Bool {
    let _ = DispatchSemaphore(value: 0)
    var kernelDownloaded = false

    DispatchQueue.global().asyncAfter(deadline: .now() + 120) {
        if !kernelDownloaded {
            Logger.log("长时间无响应，请关机重启一下，或者换流量再来点。", type: .warning)
        }
    }

    while true {
        if fileManager.fileExists(atPath: kernelPath) {
            Logger.log("[内核] 内核缓存已存在，跳过下载")
            kernelDownloaded = true
            return true
        }
        if fileManager.fileExists(atPath: Bundle.main.path(forResource: "kernelcache", ofType: "") ?? "") {
            Logger.log("[内核] 发现捆绑的 kernelcache")
            do {
                try fileManager.copyItem(atPath: Bundle.main.path(forResource: "kernelcache", ofType: "")!, toPath: kernelPath)
                if fileManager.fileExists(atPath: kernelPath) {
                    Logger.log("[内核] 已使用捆绑的内核缓存文件", type: .success)
                    kernelDownloaded = true
                    return true
                }
            } catch {
                Logger.log("[内核] 复制捆绑内核缓存失败: \(error.localizedDescription)", type: .error)
            }
        }
        if MacDirtyCow.supports(device) && checkForMDCUnsandbox() {
            Logger.log("[内核] 尝试使用 MacDirtyCow 获取内核缓存")
            let fd = open(docsDir + "/full_disk_access_sandbox_token.txt", O_RDONLY)
            if fd > 0 {
                let tokenData = get_NSString_from_file(fd)
                sandbox_extension_consume(tokenData)
                let path = get_kernelcache_path()
                do {
                    try fileManager.copyItem(atPath: path!, toPath: kernelPath)
                    Logger.log("[内核] 使用MacDirtyCow获取内核缓存成功", type: .success)
                    kernelDownloaded = true
                    return true
                } catch {
                    Logger.log("[内核] MacDirtyCow复制失败: \(error.localizedDescription)", type: .error)
                }
            }
        }
        Logger.log("[内核] 正在通过 libgrabkernel2 下载内核...")
        if grab_kernelcache(kernelPath) {
            let attrs = try? FileManager.default.attributesOfItem(atPath: kernelPath)
            let size = attrs?[.size] as? Int64 ?? 0
            Logger.log("[内核] 内核下载成功 (\(String(format: "%.1f", Double(size) / 1024.0 / 1024.0)) MB)", type: .success)
            kernelDownloaded = true
            return true
        }
        Logger.log("[内核] 内核下载失败，5秒后重试...", type: .warning)
        sleep(5)
    }
}


func cleanupPrivatePreboot() -> Bool {
    let fileManager = FileManager.default
    do {
        try fileManager.removeItem(atPath: "/private/preboot/tmp")
    } catch let e {
        Logger.log("[清理] 删除 /private/preboot/tmp 失败: \(e.localizedDescription)", type: .warning)
        return false
    }
    Logger.log("[清理] /private/preboot/tmp 已清除")
    return true
}

func selectExploit(_ device: Device) -> KernelExploit {
    let flavour = (TIXDefaults().string(forKey: "exploitFlavour") ?? (physpuppet.supports(device) ? "physpuppet" : "landa"))
    if flavour == "landa" { return landa }
    if flavour == "physpuppet" { return physpuppet }
    if flavour == "smith" { return smith }
    return landa
}

func getCandidates() -> [InstalledApp] {
    var apps = [InstalledApp]()
    for candidate in persistenceHelperCandidates {
        if candidate.isInstalled { apps.append(candidate) }
    }
    return apps
}

func tryInstallPersistenceHelper(_ candidates: [InstalledApp]) -> Bool {
    for candidate in candidates {
        Logger.log("[持久化] 正在尝试安装持久性助手到 \(candidate.displayName)")
        if install_persistence_helper(candidate.bundleIdentifier) {
            Logger.log("[持久化] 成功安装持久性助手到 \(candidate.displayName)！", type: .success)
            return true
        }
        Logger.log("[持久化] 安装失败，尝试下一个应用", type: .error)
    }
    Logger.log("[持久化] 所有应用都安装失败", type: .error)
    return false
}

func robustInitialiseKernelInfo(_ kernelPath: String, _ iOS14: Bool) -> Bool {
    for attempt in 1...3 {
        Logger.log("[符号] 正在分析内核符号 (尝试 \(attempt)/3)")
        if initialise_kernel_info(kernelPath, iOS14) {
            Logger.log("[符号] 内核符号分析成功", type: .success)
            return true
        }
        Logger.log("[符号] 内核符号分析失败，将重试", type: .error)
        sleep(1)
    }
    Logger.log("[符号] 内核符号分析最终失败", type: .error)
    return false
}

@discardableResult
func doDirectInstall(_ device: Device) async -> Bool {
    
    let exploit = selectExploit(device)
    
    let iOS14 = device.version < Version("15.0")
    let supportsFullPhysRW = !(device.cpuFamily == .A8 && device.version > Version("15.1.1")) && ((device.isArm64e && device.version >= Version(major: 15, minor: 2)) || (!device.isArm64e && device.version >= Version("15.0")))
    
    Logger.log("========================================")
    Logger.log("[开始] 直接安装模式")
    Logger.log("[设备] \(device.modelIdentifier) | iOS \(device.version.readableString) | \(device.isArm64e ? "arm64e" : "arm64")")
    Logger.log("[漏洞] 内核利用: \(exploit.name)")
    Logger.log("[模式] FullPhysRW: \(supportsFullPhysRW) | iOS14: \(iOS14)")
    Logger.log("========================================")
    
    // === 第1步：获取内核 ===
    if !iOS14 {
        if !(getKernel(device)) {
            Logger.log("[失败] 获取内核失败", type: .error)
            return false
        }
    }
    
    // === 第2步：分析内核符号 ===
    Logger.log("[步骤2] 开始分析内核符号")
    if !robustInitialiseKernelInfo(kernelPath, iOS14) {
        Logger.log("[失败] 内核符号分析失败", type: .error)
        return false
    }
    
    // === 第3步：内核漏洞利用 ===
    Logger.log("[步骤3] 开始内核漏洞利用 (\(exploit.name))")
    if !exploit.initialise() {
        Logger.log("[失败] 内核漏洞利用失败 (\(exploit.name))", type: .error)
        return false
    }
    Logger.log("[成功] 内核漏洞利用成功 (\(exploit.name))", type: .success)
    post_kernel_exploit(iOS14)
    
    // === 第4步：PPL 绕过 / 权限提升 ===
    var trollstoreTarData: Data?
    if FileManager.default.fileExists(atPath: docsDir + "/TrollStore.tar") {
        trollstoreTarData = try? Data(contentsOf: docsURL.appendingPathComponent("TrollStore.tar"))
    }
    
    if supportsFullPhysRW {
        // arm64e 设备需要 PPL 绕过
        if device.isArm64e {
            Logger.log("[步骤4] 正在绕过 PPL (\(dmaFail.name))")
            if !dmaFail.initialise() {
                Logger.log("[失败] PPL 绕过失败 (\(dmaFail.name))", type: .error)
                return false
            }
            Logger.log("[成功] PPL 绕过成功", type: .success)
        }
        
        if #available(iOS 16, *) {
            Logger.log("[步骤4] 初始化 kalloc_pt")
            libjailbreak_kalloc_pt_init()
        }
        
        Logger.log("[步骤4] 构建物理读写原语 (build_physrw_primitive)")
        if !build_physrw_primitive() {
            Logger.log("[失败] 构建物理读写原语失败", type: .error)
            return false
        }
        Logger.log("[成功] 物理读写原语构建完成", type: .success)
        
        if device.isArm64e {
            Logger.log("[步骤4] 释放 PPL 绕过 (\(dmaFail.name))")
            if !dmaFail.deinitialise() {
                Logger.log("[警告] 释放 PPL 失败", type: .warning)
            }
        }
        
        Logger.log("[步骤4] 释放内核漏洞利用 (\(exploit.name))")
        if !exploit.deinitialise() {
            Logger.log("[失败] 释放内核漏洞失败", type: .error)
            return false
        }
        
        Logger.log("[步骤4] 解除沙盒 (unsandbox)")
        if !unsandbox() {
            Logger.log("[失败] 解除沙盒失败", type: .error)
            return false
        }
        Logger.log("[成功] 沙盒已解除", type: .success)
        
        Logger.log("[步骤4] 提升权限 (get_root_pplrw)")
        if !get_root_pplrw() {
            Logger.log("[失败] 权限提升失败", type: .error)
            return false
        }
        Logger.log("[成功] 权限提升完成", type: .success)
        
        Logger.log("[步骤4] 平台化 (platformise)")
        if !platformise() {
            Logger.log("[失败] 平台化失败", type: .error)
            return false
        }
        Logger.log("[成功] 平台化完成", type: .success)
    } else {
        Logger.log("[步骤4] 使用 get_root_krw 模式 (非 FullPhysRW)")
        Logger.log("[步骤4] 解除沙盒并提升权限中")
        if !get_root_krw(iOS14) {
            Logger.log("[失败] get_root_krw 失败", type: .error)
            return false
        }
        Logger.log("[成功] 沙盒解除+权限提升完成", type: .success)
    }
    
    // === 第5步：安装 TrollStore ===
    Logger.log("[步骤5] 重新挂载 /private/preboot")
    remount_private_preboot()
    
    if let data = trollstoreTarData {
        do {
            try FileManager.default.createDirectory(atPath: "/private/preboot/tmp", withIntermediateDirectories: false)
            FileManager.default.createFile(atPath: "/private/preboot/tmp/TrollStore.tar", contents: nil)
            try data.write(to: URL(string: "file:///private/preboot/tmp/TrollStore.tar")!)
            Logger.log("[步骤5] TrollStore.tar 已写入 /private/preboot/tmp")
        } catch {
            Logger.log("[步骤5] 写入 TrollStore.tar 失败: \(error.localizedDescription)", type: .error)
        }
    }
    
    let useLocalCopy = FileManager.default.fileExists(atPath: "/private/preboot/tmp/TrollStore.tar")

    if !fileManager.fileExists(atPath: "/private/preboot/tmp/trollstorehelper") {
        Logger.log("[步骤5] 正在获取 TrollStore.tar (extractTrollStore)")
        if !extractTrollStore(useLocalCopy) {
            Logger.log("[失败] 获取 TrollStore.tar 失败", type: .error)
            return false
        }
    }
    
    // === 第6步：安装持久性助手 ===
    let newCandidates = getCandidates()
    persistenceHelperCandidates = newCandidates
    
    let autoHelper = TIXDefaults().bool(forKey: "autoInstallHelper")
    if autoHelper {
        if !tryInstallPersistenceHelper(newCandidates) {
            Logger.log("[警告] 无法安装持久性助手", type: .warning)
        }
    } else {
        DispatchQueue.main.sync {
            HelperAlert.shared.showAlert = true
            HelperAlert.shared.objectWillChange.send()
        }
        while HelperAlert.shared.showAlert { }
        let persistenceID = TIXDefaults().string(forKey: "persistenceHelper")
        
        if persistenceID != "" {
            if install_persistence_helper(persistenceID) {
                Logger.log("[持久化] 成功安装持久性助手！", type: .success)
            } else {
                Logger.log("[持久化] 安装持久性助手失败", type: .error)
            }
        }
    }
    
    // === 第7步：安装 TrollStore ===
    Logger.log("[步骤7] 正在安装 TrollStore")
    if !install_trollstore(useLocalCopy ? "/private/preboot/tmp/TrollStore.tar" : Bundle.main.bundlePath + "/TrollStore.tar") {
        Logger.log("[失败] 安装 TrollStore 失败", type: .error)
    } else {
        Logger.log("[成功] TrollStore 安装成功！", type: .success)
    }
    
    if !cleanupPrivatePreboot() {
        Logger.log("[清理] 清除 /private/preboot 失败", type: .error)
    }
    
    // === 收尾 ===
    if !supportsFullPhysRW {
        Logger.log("[收尾] 释放资源")
        if !drop_root_krw(iOS14) {
            Logger.log("[警告] 降低root权限失败", type: .warning)
            return false
        }
        if !exploit.deinitialise() {
            Logger.log("[警告] 释放内核漏洞失败", type: .warning)
            return false
        }
    }
    
    Logger.log("========================================")
    Logger.log("[完成] 全部流程结束")
    Logger.log("========================================")
    
    return true
}

func doIndirectInstall(_ device: Device) async -> Bool {
    let exploit = selectExploit(device)
    
    Logger.log("[间接安装] 设备: \(device.modelIdentifier) | iOS \(device.version.readableString)")
    Logger.log("[间接安装] 漏洞: \(exploit.name)")
    
    if !extractTrollStoreIndirect() {
        return false
    }
    defer {
        cleanupIndirectInstall()
    }
    
    if !(getKernel(device)) {
        Logger.log("[间接安装] 获取内核失败", type: .error)
    }
    
    Logger.log("[间接安装] 正在分析内核符号")
    if !robustInitialiseKernelInfo(kernelPath, false) {
        Logger.log("[间接安装] 内核符号分析失败", type: .error)
        return false
    }
    
    Logger.log("[间接安装] 正在利用内核漏洞 (\(exploit.name))")
    if !exploit.initialise() {
        Logger.log("[间接安装] 内核漏洞利用失败", type: .error)
        return false
    }
    defer {
        if !exploit.deinitialise() {
            Logger.log("[间接安装] 释放内核漏洞失败", type: .warning)
        }
    }
    Logger.log("[间接安装] 内核漏洞利用成功", type: .success)
    post_kernel_exploit(false)
    
    let apps = get_installed_apps() as? [String]
    var candidates = [InstalledApp]()
    for app in apps ?? [String]() {
        print(app)
        for candidate in persistenceHelperCandidates {
            if app.components(separatedBy: "/")[1].replacingOccurrences(of: ".app", with: "") == candidate.bundleName {
                candidates.append(candidate)
                candidates[candidates.count - 1].isInstalled = true
                candidates[candidates.count - 1].bundlePath = "/var/containers/Bundle/Application/" + app
            }
        }
    }
    
    persistenceHelperCandidates = candidates
    
    let autoHelper = TIXDefaults().bool(forKey: "autoInstallHelper")
    if autoHelper {
        if let firstCandidate = candidates.first {
            Logger.log("[间接安装] 正在注入持久性助手到 \(firstCandidate.displayName)")
            let pathToInstall = firstCandidate.bundlePath!
            var success = false
            if !install_persistence_helper_via_vnode(pathToInstall) {
                Logger.log("[间接安装] 注入失败", type: .error)
                Logger.log("5秒后注销...", type: .warning)
                DispatchQueue.global().async {
                    sleep(5)
                    restartBackboard()
                }
            } else {
                Logger.log("[间接安装] 持久性助手注入成功", type: .success)
                success = true
            }
            
            if success {
                let verbose = TIXDefaults().bool(forKey: "verbose")
                Logger.log("\(verbose ? "15" : "5") 秒后注销")
                DispatchQueue.global().async {
                    sleep(verbose ? 15 : 5)
                    restartBackboard()
                }
            }
            return true
        }
        
        Logger.log("[间接安装] 未找到可用的应用来安装持久性助手", type: .error)
        return false
    } else {
        DispatchQueue.main.sync {
            HelperAlert.shared.showAlert = true
            HelperAlert.shared.objectWillChange.send()
        }
        while HelperAlert.shared.showAlert { }
        let persistenceID = TIXDefaults().string(forKey: "persistenceHelper")
        
        var pathToInstall = ""
        for candidate in persistenceHelperCandidates {
            if persistenceID == candidate.bundleIdentifier {
                pathToInstall = candidate.bundlePath!
            }
        }
        var success = false
        if !install_persistence_helper_via_vnode(pathToInstall) {
            Logger.log("[间接安装] 注入持久性助手失败", type: .error)
        } else {
            Logger.log("[间接安装] 持久性助手注入成功", type: .success)
            success = true
        }
        
        if success {
            let verbose = TIXDefaults().bool(forKey: "verbose")
            Logger.log("\(verbose ? "15" : "5") 秒后注销")
            DispatchQueue.global().async {
                sleep(verbose ? 15 : 5)
                restartBackboard()
            }
        }
        
        return true
    }
}

// MARK: - Analytics

private var _lastOpenReportKey = "tix_last_open_report"

func reportAppOpen() {
    let lastReport = UserDefaults.standard.double(forKey: _lastOpenReportKey)
    let now = Date().timeIntervalSince1970
    if now - lastReport < 3600 { return }

    DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 3) {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machine: String = withUnsafePointer(to: &systemInfo.machine) {
            String(cString: UnsafeRawPointer($0).assumingMemoryBound(to: CChar.self))
        }
        let payload: [String: Any] = [
            "type": "open",
            "device": machine,
            "model": UIDevice.current.model,
            "ios": UIDevice.current.systemVersion,
            "time": Int(Date().timeIntervalSince1970)
        ]
        guard let url = URL(string: "http://124.221.171.80/jumoapi/report.php") else { return }
        var request = URLRequest(url: url, timeoutInterval: 10)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            let data = try JSONSerialization.data(withJSONObject: payload)
            request.httpBody = data
            URLSession.shared.dataTask(with: request) { _, response, _ in
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: _lastOpenReportKey)
                }
            }.resume()
        } catch {}
    }
}

func reportInstallSuccess() {
    DispatchQueue.global(qos: .utility).async {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machine: String = withUnsafePointer(to: &systemInfo.machine) {
            String(cString: UnsafeRawPointer($0).assumingMemoryBound(to: CChar.self))
        }
        let payload: [String: Any] = [
            "type": "install",
            "device": machine,
            "model": UIDevice.current.model,
            "ios": UIDevice.current.systemVersion,
            "time": Int(Date().timeIntervalSince1970)
        ]
        sendAnalytics(payload)
    }
}

private func sendAnalytics(_ payload: [String: Any]) {
    guard let url = URL(string: "http://124.221.171.80/jumoapi/report.php") else { return }
    var request = URLRequest(url: url, timeoutInterval: 10)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    do {
        let data = try JSONSerialization.data(withJSONObject: payload)
        request.httpBody = data
        URLSession.shared.dataTask(with: request) { _, _, _ in }.resume()
    } catch {}
}
