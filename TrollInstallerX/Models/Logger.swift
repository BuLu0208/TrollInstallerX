//
//  Logger.swift
//  TrollInstallerX
//
//  Created by Alfie on 22/03/2024.
//  Modified: 添加持久化文件日志 + 崩溃日志备份
//

import SwiftUI

enum LogType {
    case success
    case warning
    case error
    case info
}

struct LogItem: Identifiable, Equatable {
    let message: String
    let type: LogType
    let date: Date = Date()
    var id = UUID()
    
    var image: String {
        switch self.type {
        case .success: return "checkmark"
        case .warning: return "exclamationmark.triangle"
        case .error: return "xmark"
        case .info: return "info"
        }
    }
    
    var colour: Color {
        switch self.type {
        case .success: return .init(hex: 0x08d604)
        case .warning: return .yellow
        case .error: return .red
        case .info: return .white
        }
    }
}

class Logger: ObservableObject {
    @Published var logString: String = ""
    @Published var logItems: [LogItem] = [LogItem]()
    
    static var shared = Logger()
    
    // MARK: - 文件日志路径
    
    private static var logDir: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    /// 当前运行日志
    static var currentLogURL: URL {
        logDir.appendingPathComponent("tix_current.log")
    }
    
    /// 上次运行日志（可能是崩溃前的）
    static var lastRunLogURL: URL {
        logDir.appendingPathComponent("tix_lastrun.log")
    }
    
    /// stdout 详细日志
    static var stdoutLogURL: URL {
        logDir.appendingPathComponent("tix_stdout.log")
    }
    
    /// 上次 stdout 详细日志
    static var lastStdoutLogURL: URL {
        logDir.appendingPathComponent("tix_stdout_lastrun.log")
    }
    
    // MARK: - 日志管理
    
    /// App 启动时调用：备份上次日志
    static func preservePreviousLogs() {
        let fm = FileManager.default
        
        // 备份当前日志 → 上次运行日志
        if fm.fileExists(atPath: currentLogURL.path) {
            try? fm.removeItem(at: lastRunLogURL)
            try? fm.moveItem(at: currentLogURL, to: lastRunLogURL)
        }
        if fm.fileExists(atPath: stdoutLogURL.path) {
            try? fm.removeItem(at: lastStdoutLogURL)
            try? fm.moveItem(at: stdoutLogURL, to: lastStdoutLogURL)
        }
        
        // 新建当前日志
        let header = "===== TrollInstallerX 日志 \(formatDate(Date())) =====\n"
        try? header.write(to: currentLogURL, atomically: true, encoding: .utf8)
        
        // stdout 日志留空，由 LogView 重定向时创建
        try? "".write(to: stdoutLogURL, atomically: true, encoding: .utf8)
    }
    
    /// 追加一行到文件日志
    private static func appendToFile(_ text: String) {
        let line = "[\(formatDate(Date()))] \(text)\n"
        guard let data = line.data(using: .utf8) else { return }
        // 用 FileHandle 追加，确保实时写入磁盘
        if let handle = try? FileHandle(forWritingTo: currentLogURL) {
            handle.seekToEndOfFile()
            handle.write(data)
            try? handle.synchronizeFile() // 强制刷盘，死机前也能保留
            try? handle.close()
        }
    }
    
    /// 追加 stdout 输出到文件
    static func appendStdoutToFile(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }
        if let handle = try? FileHandle(forWritingTo: stdoutLogURL) {
            handle.seekToEndOfFile()
            handle.write(data)
            try? handle.synchronizeFile()
            try? handle.close()
        }
    }
    
    private static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: date)
    }
    
    /// 读取日志文件内容
    static func readLogFile(_ url: URL) -> String {
        (try? String(contentsOf: url, encoding: .utf8)) ?? ""
    }
    
    // MARK: - 日志输出
    
    static func log(_ logMessage: String, type: LogType? = .info) {
        let newItem = LogItem(message: logMessage, type: type ?? .info)
        print(logMessage)
        UIImpactFeedbackGenerator().impactOccurred()
        
        // 写入文件
        appendToFile(logMessage)
        
        DispatchQueue.main.async {
            shared.logItems.append(newItem)
            shared.logString.append(logMessage + "\n")
            shared.logItems.sort(by: { $0.date < $1.date })
        }
    }
}
