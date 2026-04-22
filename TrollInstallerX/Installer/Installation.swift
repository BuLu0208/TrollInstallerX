//
//  Installation.swift
//  TrollInstallerX
//
//  Created by Alfie on 22/03/2024.
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
    if !fileManager.fileExists(atPath: kernelPath) {
        if fileManager.fileExists(atPath: Bundle.main.path(forResource: "kernelcache", ofType: "") ?? "") {
            try? fileManager.copyItem(atPath: Bundle.main.path(forResource: "kernelcache", ofType: "")!, toPath: kernelPath)
            if fileManager.fileExists(atPath: kernelPath) { return true }
        }
        if MacDirtyCow.supports(device) && checkForMDCUnsandbox() {
            let fd = open(docsDir + "/full_disk_access_sandbox_token.txt", O_RDONLY)
            if fd > 0 {
                let tokenData = get_NSString_from_file(fd)
                sandbox_extension_consume(tokenData)
                Logger.log("姝ｅ湪澶嶅埗鍐呮牳缂撳瓨")
                let path = get_kernelcache_path()
                do {
                    try fileManager.copyItem(atPath: path!, toPath: kernelPath)
                    return true
                } catch {
                    Logger.log("澶嶅埗鍐呮牳缂撳瓨澶辫触", type: .error)
                    NSLog("Failed to copy kernelcache - \(error)")
                }
            }
        }
        Logger.log("姝ｅ湪涓嬭浇鍐呮牳")
        if !grab_kernelcache(kernelPath) {
            Logger.log("涓嬭浇鍐呮牳澶辫触", type: .error)
            return false
        }
    }
    
    return true
}


func cleanupPrivatePreboot() -> Bool {
    // Remove /private/preboot/tmp
    let fileManager = FileManager.default
    do {
        try fileManager.removeItem(atPath: "/private/preboot/tmp")
    } catch let e {
        print("Failed to remove /private/preboot/tmp! \(e.localizedDescription)")
        return false
    }
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

@discardableResult
func doDirectInstall(_ device: Device) async -> Bool {
    
    let exploit = selectExploit(device)
    
    let iOS14 = device.version < Version("15.0")
    let supportsFullPhysRW = !(device.cpuFamily == .A8 && device.version > Version("15.1.1")) && ((device.isArm64e && device.version >= Version(major: 15, minor: 2)) || (!device.isArm64e && device.version >= Version("15.0")))
    
    Logger.log("姝ｈ繍琛屽湪 \(device.modelIdentifier) 璁惧涓婄殑 iOS 鐗堟湰涓?\(device.version.readableString)")
    
    if !iOS14 {
        if !(getKernel(device)) {
            Logger.log("鑾峰彇鍐呮牳婕忔礊澶辫触", type: .error)
            return false
        }
    }
    
    Logger.log("姝ｅ湪鏌ユ壘鍐呮牳婕忔礊")
    if !initialise_kernel_info(kernelPath, iOS14) {
        Logger.log("鏌ユ壘鍐呮牳婕忔礊澶辫触", type: .error)
        return false
    }
    
    Logger.log("姝ｅ湪鍒╃敤鍐呮牳 (\(exploit.name)) 婕忔礊")
    if !exploit.initialise() {
        Logger.log("鍒╃敤鍐呮牳婕忔礊澶辫触", type: .error)
        return false
    }
    Logger.log("鎴愬姛鍒╃敤鍐呮牳婕忔礊", type: .success)
    post_kernel_exploit(iOS14)
    
    var trollstoreTarData: Data?
    if FileManager.default.fileExists(atPath: docsDir + "/TrollStore.tar") {
        trollstoreTarData = try? Data(contentsOf: docsURL.appendingPathComponent("TrollStore.tar"))
    }
    
    if supportsFullPhysRW {
        if device.isArm64e {
            Logger.log("姝ｅ湪缁曡繃 PPL (\(dmaFail.name))")
            if !dmaFail.initialise() {
                Logger.log("缁曡繃 PPL 澶辫触", type: .error)
                return false
            }
            Logger.log("鎴愬姛缁曡繃 PPL", type: .success)
        }
        
        if #available(iOS 16, *) {
            libjailbreak_kalloc_pt_init()
        }
        
        if !build_physrw_primitive() {
            Logger.log("鏋勫缓纭欢璇诲啓鏉′欢澶辫触", type: .error)
            return false
        }
        
        if device.isArm64e {
            if !dmaFail.deinitialise() {
                Logger.log("鍒濆鍖?\(dmaFail.name) 澶辫触", type: .error)
                return false
            }
        }
        
        if !exploit.deinitialise() {
            Logger.log("鍒濆鍖?\(exploit.name) 澶辫触", type: .error)
            return false
        }
        
        Logger.log("姝ｅ湪瑙ｉ櫎娌欑洅")
        if !unsandbox() {
            Logger.log("瑙ｉ櫎娌欑洅澶辫触", type: .error)
            return false
        }
        
        Logger.log("鎻愬崌鏉冮檺")
        if !get_root_pplrw() {
            Logger.log("鎻愬崌鏉冮檺澶辫触", type: .error)
            return false
        }
        if !platformise() {
            Logger.log("骞冲彴鍖栧け璐?, type: .error)
            return false
        }
    } else {
        
        Logger.log("瑙ｉ櫎娌欑洅骞舵彁鍗囨潈闄愪腑")
        if !get_root_krw(iOS14) {
            Logger.log("瑙ｉ櫎娌欑洅骞舵彁鍗囨潈闄愬け璐?, type: .error)
            return false
        }
    }
    
    remount_private_preboot()
    
    if let data = trollstoreTarData {
        do {
            try FileManager.default.createDirectory(atPath: "/private/preboot/tmp", withIntermediateDirectories: false)
            FileManager.default.createFile(atPath: "/private/preboot/tmp/TrollStore.tar", contents: nil)
            try data.write(to: URL(string: "file:///private/preboot/tmp/TrollStore.tar")!)
        } catch {
            print("鏃犳硶鎴愬姛鍐欏嚭 TrollStore.tar - \(error.localizedDescription)")
        }
    }
    
    // Prevents download finishing between extraction and installation
    let useLocalCopy = FileManager.default.fileExists(atPath: "/private/preboot/tmp/TrollStore.tar")

    if !fileManager.fileExists(atPath: "/private/preboot/tmp/trollstorehelper") {
        Logger.log("姝ｅ湪鑾峰彇 TrollStore.tar")
        if !extractTrollStore(useLocalCopy) {
            Logger.log("鑾峰彇 TrollStore.tar 澶辫触", type: .error)
            return false
        }
    }
    
    let newCandidates = getCandidates()
    persistenceHelperCandidates = newCandidates
    
    var persistenceID = ""
    let tipsCandidate = newCandidates.first(where: { $0.bundleIdentifier == "com.apple.tips" })
    if tipsCandidate != nil && tipsCandidate!.isInstalled {
        persistenceID = "com.apple.tips"
        TIXDefaults().setValue(persistenceID, forKey: "persistenceHelper")
        Logger.log("自动选择 Tips 作为持久性助手", type: .success)
    } else {
        DispatchQueue.main.sync {
            HelperAlert.shared.showAlert = true
            HelperAlert.shared.objectWillChange.send()
        }
        while HelperAlert.shared.showAlert { }
        persistenceID = TIXDefaults().string(forKey: "persistenceHelper") ?? ""
    }
    
    if persistenceID != "" {
        if install_persistence_helper(persistenceID) {
            Logger.log("鎴愬姛瀹夎鎸佷箙鎬у姪鎵嬶紒", type: .success)
        } else {
            Logger.log("瀹夎鎸佷箙鎬у姪鎵嬪け璐?, type: .error)
        }
    }
    
    Logger.log("姝ｅ湪瀹夎 TrollStore")
    if !install_trollstore(useLocalCopy ? "/private/preboot/tmp/TrollStore.tar" : Bundle.main.bundlePath + "/TrollStore.tar") {
        Logger.log("瀹夎 TrollStore 澶辫触", type: .error)
    } else {
        Logger.log("鎴愬姛瀹夎 TrollStore锛?, type: .success)
    }
    
    if !cleanupPrivatePreboot() {
        Logger.log("娓呴櫎 /private/preboot 澶辫触", type: .error)
    }
    
    if !supportsFullPhysRW {
        if !drop_root_krw(iOS14) {
            Logger.log("闄嶄綆root鏉冮檺澶辫触", type: .error)
            return false
        }
        if !exploit.deinitialise() {
            Logger.log("鍒濆鍖?\(exploit.name) 澶辫触", type: .error)
            return false
        }
    }
    
    return true
}

func doIndirectInstall(_ device: Device) async -> Bool {
    let exploit = selectExploit(device)
    
    Logger.log("姝ｈ繍琛屽湪 \(device.modelIdentifier) 璁惧涓婄殑 iOS 鐗堟湰涓?\(device.version.readableString)")
    
    if !extractTrollStoreIndirect() {
        return false
    }
    defer {
        cleanupIndirectInstall()
    }
    
    if !(getKernel(device)) {
        Logger.log("鑾峰彇鍐呮牳澶辫触", type: .error)
    }
    
    Logger.log("姝ｅ湪鏌ユ壘鍐呮牳婕忔礊")
    if !initialise_kernel_info(kernelPath, false) {
        Logger.log("鏌ユ壘鍐呮牳婕忔礊澶辫触", type: .error)
        return false
    }
    
    Logger.log("姝ｅ湪鍒╃敤鍐呮牳婕忔礊 (\(exploit.name))")
    if !exploit.initialise() {
        Logger.log("鍒╃敤鍐呮牳婕忔礊澶辫触", type: .error)
        return false
    }
    defer {
        if !exploit.deinitialise() {
            Logger.log("鍒濆鍖?\(exploit.name) 澶辫触", type: .error)
        }
    }
    Logger.log("鎴愬姛鍒╃敤鍐呮牳", type: .success)
    post_kernel_exploit(false)
    
    var path: UnsafePointer<CChar>? = nil
    let pathPointer = withUnsafeMutablePointer(to: &path) { ptr in
        UnsafeMutablePointer<UnsafePointer<CChar>?>.init(ptr)
    }
    if is_persistence_helper_installed(pathPointer) {
        Logger.log("鎸佷箙鎬у姪鎵嬪凡瀹夎! (\(path == nil ? "unknown" : String(cString: path!)))", type: .warning)
        return false
    }
    
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
    
    var persistenceID = ""
    let tipsCandidate = candidates.first(where: { $0.bundleIdentifier == "com.apple.tips" })
    if tipsCandidate != nil && tipsCandidate!.isInstalled {
        persistenceID = "com.apple.tips"
        TIXDefaults().setValue(persistenceID, forKey: "persistenceHelper")
        Logger.log("自动选择 Tips 作为持久性助手", type: .success)
    } else {
        DispatchQueue.main.sync {
            HelperAlert.shared.showAlert = true
            HelperAlert.shared.objectWillChange.send()
        }
        while HelperAlert.shared.showAlert { }
        persistenceID = TIXDefaults().string(forKey: "persistenceHelper") ?? ""
    }
    
    var pathToInstall = ""
    for candidate in persistenceHelperCandidates {
        if persistenceID == candidate.bundleIdentifier {
            pathToInstall = candidate.bundlePath!
        }
    }
    var success = false
    if !install_persistence_helper_via_vnode(pathToInstall) {
        Logger.log("瀹夎鎸佷箙鎬у姪鎵嬪け璐?, type: .error)
    } else {
        Logger.log("鎴愬姛瀹夎鎸佷箙鎬у姪鎵?, type: .success)
        success = true
    }
    
    if success {
        let verbose = TIXDefaults().bool(forKey: "verbose")
        Logger.log("\(verbose ? "15" : "5") 绉掑悗娉ㄩ攢")
        DispatchQueue.global().async {
            sleep(verbose ? 15 : 5)
            restartBackboard()
        }
    }
    
    return true
}

