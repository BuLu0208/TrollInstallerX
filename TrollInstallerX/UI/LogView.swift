import SwiftUI

struct StdoutLog: Identifiable, Equatable {
    let message: String
    let id = UUID()
}

struct LogView: View {
    @StateObject var logger = Logger.shared
    @Binding var installationFinished: Bool
    
    @AppStorage("verbose", store: TIXDefaults()) var verbose: Bool = false
    
    // 添加下载进度状态
    @State private var downloadProgress: Float = 0.0
    @State private var downloadedBytes: Int64 = 0
    @State private var totalBytes: Int64 = 0
    @State private var isDownloading: Bool = false
    
    let pipe = Pipe()
    let sema = DispatchSemaphore(value: 0)
    @State private var stdoutString = ""
    @State private var stdoutItems = [StdoutLog]()
    
    @State var verboseID = UUID()
    
    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView {
                    if verbose {
                        ForEach(stdoutItems) { item in
                            HStack {
                                Text(item.message)
                                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                                    .multilineTextAlignment(.leading)
                                    .foregroundColor(.white)
                                    .id(item.id)
                                Spacer()
                            }
                            .frame(width: geometry.size.width)
                        }
                        
                        .onChange(of: stdoutItems) { _ in
                            DispatchQueue.main.async {
                                proxy.scrollTo(stdoutItems.last!.id, anchor: .bottom)
                            }
                        }
                    } else {
                        VStack(alignment: .leading) {
                            Spacer()
                            
                            // 添加下载进度显示
                            if isDownloading {
                                VStack(alignment: .leading) {
                                    Text("正在下载文件...")
                                        .font(.system(size: 13, weight: .regular, design: .rounded))
                                        .foregroundColor(.white)
                                    
                                    ProgressView(value: downloadProgress)
                                        .progressViewStyle(LinearProgressViewStyle())
                                        .frame(height: 8)
                                        .accentColor(.blue)
                                    
                                    Text(String(format: "%.1f%% (%.2f MB / %.2f MB)", 
                                              downloadProgress * 100,
                                              Float(downloadedBytes) / 1024 / 1024,
                                              Float(totalBytes) / 1024 / 1024))
                                        .font(.system(size: 12, weight: .regular, design: .rounded))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                .padding(.vertical, 5)
                            }
                            
                            ForEach(logger.logItems) { log in
                                HStack {
                                    Label(
                                        title: {
                                            Text(log.message)
                                                .font(.system(size: 13, weight: .regular, design: .rounded))
                                                .shadow(radius: 2)
                                        },
                                        icon: {
                                            Image(systemName: log.image)
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 12, height: 12)
                                                .padding(.trailing, 5)
                                        }
                                    )
                                    .foregroundColor(log.colour)
                                    .padding(.vertical, 5)
                                    .transition(AnyTransition.asymmetric(
                                        insertion: .move(edge: .bottom),
                                        removal: .move(edge: .top)
                                    ))
                                    Spacer()
                                }
                            }
                        }
                        .onChange(of: geometry.size.height) { newHeight in
                            DispatchQueue.main.async {
                                withAnimation {
                                    proxy.scrollTo(logger.logItems.last!.id, anchor: .bottom)
                                }
                            }
                        }
                        
                        .onChange(of: logger.logItems) { _ in
                            DispatchQueue.main.async {
                                proxy.scrollTo(logger.logItems.last!.id, anchor: .bottom)
                            }
                        }
                        
                        // 添加下载进度通知监听
                        .onAppear {
                            NotificationCenter.default.addObserver(
                                forName: NSNotification.Name("DownloadProgressUpdated"),
                                object: nil,
                                queue: .main) { notification in
                                    if let progress = notification.userInfo?["progress"] as? Float,
                                       let received = notification.userInfo?["receivedBytes"] as? Int64,
                                       let total = notification.userInfo?["totalBytes"] as? Int64 {
                                        isDownloading = true
                                        downloadProgress = progress
                                        downloadedBytes = received
                                        totalBytes = total
                                    }
                                }
                        }
                    }
                }
            }
        }
    }
}
