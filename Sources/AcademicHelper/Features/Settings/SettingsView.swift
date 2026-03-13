import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    
    var body: some View {
        TabView {
            GeneralSettingsView(viewModel: viewModel)
                .tabItem {
                    Label("通用", systemImage: "gear")
                }
            
            WordLearningSettingsView(viewModel: viewModel)
                .tabItem {
                    Label("单词学习", systemImage: "character.book.closed")
                }
            
            SyncSettingsView(viewModel: viewModel)
                .tabItem {
                    Label("同步", systemImage: "arrow.clockwise.cloud")
                }
            
            DataManagementView(viewModel: viewModel)
                .tabItem {
                    Label("数据管理", systemImage: "externaldrive")
                }
            
            AboutView()
                .tabItem {
                    Label("关于", systemImage: "info.circle")
                }
        }
        .frame(minWidth: 500, minHeight: 400)
        .padding()
    }
}

struct GeneralSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    
    var body: some View {
        Form {
            Section("外观") {
                Picker("主题", selection: $viewModel.appearanceTheme) {
                    Text("系统默认").tag(AppearanceTheme.system)
                    Text("浅色").tag(AppearanceTheme.light)
                    Text("深色").tag(AppearanceTheme.dark)
                }
                .pickerStyle(.segmented)
            }
            
            Section("启动") {
                Toggle("开机自动启动", isOn: $viewModel.launchAtLogin)
                Toggle("启动时显示主窗口", isOn: $viewModel.showMainWindowOnLaunch)
            }
            
            Section("通知") {
                Toggle("启用通知", isOn: $viewModel.notificationsEnabled)
                
                if viewModel.notificationsEnabled {
                    Toggle("复习提醒", isOn: $viewModel.reviewRemindersEnabled)
                    
                    if viewModel.reviewRemindersEnabled {
                        DatePicker("提醒时间", selection: $viewModel.reviewReminderTime, displayedComponents: .hourAndMinute)
                    }
                }
            }
            
            Section("快捷键") {
                HStack {
                    Text("屏幕取词")
                    Spacer()
                    KeyboardShortcutRecorder(shortcut: $viewModel.wordCaptureShortcut)
                }
                
                HStack {
                    Text("快速添加单词")
                    Spacer()
                    KeyboardShortcutRecorder(shortcut: $viewModel.quickAddWordShortcut)
                }
            }
        }
        .formStyle(.grouped)
    }
}

struct WordLearningSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    
    var body: some View {
        Form {
            Section("词典设置") {
                Picker("默认词典", selection: $viewModel.defaultDictionary) {
                    Text("Free Dictionary").tag("free_dictionary")
                    Text("有道词典").tag("youdao")
                    Text("剑桥词典").tag("cambridge")
                }
                
                Toggle("自动发音", isOn: $viewModel.autoPronunciation)
                
                if viewModel.autoPronunciation {
                    Picker("发音引擎", selection: $viewModel.pronunciationEngine) {
                        Text("系统语音").tag("system")
                        Text("在线发音").tag("online")
                    }
                }
            }
            
            Section("复习设置") {
                Stepper("每日新单词上限: \(viewModel.dailyNewWordLimit)", value: $viewModel.dailyNewWordLimit, in: 5...50)
                
                Stepper("每日复习上限: \(viewModel.dailyReviewLimit)", value: $viewModel.dailyReviewLimit, in: 10...100)
                
                Picker("默认难度", selection: $viewModel.defaultWordDifficulty) {
                    ForEach(WordDifficulty.allCases, id: \.self) { difficulty in
                        Text(difficulty.description).tag(difficulty)
                    }
                }
            }
            
            Section("屏幕取词") {
                Toggle("启用屏幕取词", isOn: $viewModel.wordCaptureEnabled)
                
                if viewModel.wordCaptureEnabled {
                    Toggle("取词时自动播放发音", isOn: $viewModel.autoPlayPronunciationOnCapture)
                    Toggle("取词时显示例句", isOn: $viewModel.showExamplesOnCapture)
                }
            }
        }
        .formStyle(.grouped)
    }
}

struct SyncSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    
    var body: some View {
        Form {
            Section("iCloud 同步") {
                Toggle("启用 iCloud 同步", isOn: $viewModel.iCloudSyncEnabled)
                
                if viewModel.iCloudSyncEnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("已连接到 iCloud")
                        }
                        
                        Text("上次同步: \(viewModel.lastSyncTime)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Button("立即同步") {
                            viewModel.syncNow()
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    Text("启用 iCloud 同步后，您的数据将在所有设备间自动同步")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Section("同步选项") {
                Toggle("单词数据", isOn: $viewModel.syncWords)
                Toggle("文献数据", isOn: $viewModel.syncLiterature)
                Toggle("学术表达", isOn: $viewModel.syncExpressions)
                Toggle("学习进度", isOn: $viewModel.syncProgress)
            }
            
            Section("冲突解决") {
                Picker("数据冲突时", selection: $viewModel.conflictResolution) {
                    Text("使用最新版本").tag(ConflictResolution.latest)
                    Text("手动选择").tag(ConflictResolution.manual)
                    Text("保留本地版本").tag(ConflictResolution.local)
                }
            }
        }
        .formStyle(.grouped)
        .disabled(!viewModel.iCloudSyncEnabled)
    }
}

struct DataManagementView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @State private var showingExportDialog = false
    @State private var showingImportDialog = false
    @State private var showingClearDataConfirmation = false
    
    var body: some View {
        Form {
            Section("数据导出") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("将所有数据导出为 JSON 文件")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Button("导出数据...") {
                        showingExportDialog = true
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            Section("数据导入") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("从 JSON 文件导入数据")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Button("导入数据...") {
                        showingImportDialog = true
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            Section("数据清理") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("单词: \(viewModel.wordCount)")
                            Text("文献: \(viewModel.literatureCount)")
                            Text("表达: \(viewModel.expressionCount)")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Button("清理缓存") {
                            viewModel.clearCache()
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Divider()
                    
                    Button("清除所有数据...") {
                        showingClearDataConfirmation = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
            }
        }
        .formStyle(.grouped)
        .fileExporter(
            isPresented: $showingExportDialog,
            document: viewModel.exportDocument,
            contentType: .json,
            defaultFilename: "AcademicHelper_Export_\(Date().formatted(.iso8601))"
        ) { result in
            viewModel.handleExportResult(result)
        }
        .fileImporter(
            isPresented: $showingImportDialog,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            viewModel.handleImportResult(result)
        }
        .alert("确认清除所有数据？", isPresented: $showingClearDataConfirmation) {
            Button("取消", role: .cancel) {}
            Button("清除", role: .destructive) {
                viewModel.clearAllData()
            }
        } message: {
            Text("此操作不可撤销，所有单词、文献和学术表达数据将被永久删除。")
        }
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "graduationcap.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue)
            
            Text("AcademicHelper")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("版本 1.0.0 (Build 100)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Text("专为学术工作者设计的一站式辅助工具")
                .font(.body)
                .foregroundStyle(.secondary)
            
            Divider()
                .frame(width: 200)
            
            VStack(spacing: 8) {
                Link("访问官网", destination: URL(string: "https://academichelper.app")!)
                Link("隐私政策", destination: URL(string: "https://academichelper.app/privacy")!)
                Link("用户协议", destination: URL(string: "https://academichelper.app/terms")!)
            }
            
            Divider()
                .frame(width: 200)
            
            Text("© 2024 AcademicHelper. All rights reserved.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct KeyboardShortcutRecorder: View {
    @Binding var shortcut: String
    @State private var isRecording = false
    
    var body: some View {
        Button(action: {
            isRecording.toggle()
        }) {
            Text(shortcut.isEmpty ? "点击记录" : shortcut)
                .frame(width: 100)
        }
        .buttonStyle(.bordered)
        .background(isRecording ? Color.blue.opacity(0.2) : Color.clear)
        .onAppear {
            if isRecording {
                NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                    shortcut = event.modifiers.description + "+" + event.charactersIgnoringModifiers!
                    isRecording = false
                    return nil
                }
            }
        }
    }
}

enum AppearanceTheme: String, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"
}

enum ConflictResolution: String, CaseIterable {
    case latest = "latest"
    case manual = "manual"
    case local = "local"
}

@MainActor
class SettingsViewModel: ObservableObject {
    // General Settings
    @Published var appearanceTheme: AppearanceTheme = .system
    @Published var launchAtLogin = false
    @Published var showMainWindowOnLaunch = true
    @Published var notificationsEnabled = true
    @Published var reviewRemindersEnabled = true
    @Published var reviewReminderTime = Date()
    @Published var wordCaptureShortcut = "Cmd+Shift+D"
    @Published var quickAddWordShortcut = "Cmd+Shift+A"
    
    // Word Learning Settings
    @Published var defaultDictionary = "free_dictionary"
    @Published var autoPronunciation = true
    @Published var pronunciationEngine = "system"
    @Published var dailyNewWordLimit = 20
    @Published var dailyReviewLimit = 50
    @Published var defaultWordDifficulty: WordDifficulty = .medium
    @Published var wordCaptureEnabled = true
    @Published var autoPlayPronunciationOnCapture = false
    @Published var showExamplesOnCapture = true
    
    // Sync Settings
    @Published var iCloudSyncEnabled = false
    @Published var lastSyncTime = "从未"
    @Published var syncWords = true
    @Published var syncLiterature = true
    @Published var syncExpressions = true
    @Published var syncProgress = true
    @Published var conflictResolution: ConflictResolution = .latest
    
    // Data Management
    @Published var wordCount = 0
    @Published var literatureCount = 0
    @Published var expressionCount = 0
    @Published var exportDocument: ExportDocument?
    
    @Inject private var wordRepository: WordRepositoryProtocol
    @Inject private var literatureRepository: LiteratureRepositoryProtocol
    @Inject private var expressionRepository: ExpressionRepositoryProtocol
    
    init() {
        loadSettings()
        loadDataCounts()
    }
    
    func loadSettings() {
        // Load from UserDefaults or Core Data
    }
    
    func loadDataCounts() {
        Task {
            do {
                let words = try await wordRepository.fetchAllWords()
                let documents = try await literatureRepository.fetchAllDocuments()
                let expressions = try await expressionRepository.fetchAllExpressions()
                
                await MainActor.run {
                    wordCount = words.count
                    literatureCount = documents.count
                    expressionCount = expressions.count
                }
            } catch {
                print("Failed to load data counts: \(error)")
            }
        }
    }
    
    func syncNow() {
        // Trigger iCloud sync
        lastSyncTime = Date().formatted()
    }
    
    func clearCache() {
        // Clear temporary files and cache
    }
    
    func clearAllData() {
        Task {
            do {
                let words = try await wordRepository.fetchAllWords()
                for word in words {
                    try await wordRepository.deleteWord(id: word.id)
                }
                
                let documents = try await literatureRepository.fetchAllDocuments()
                for document in documents {
                    try await literatureRepository.deleteDocument(id: document.id)
                }
                
                let expressions = try await expressionRepository.fetchAllExpressions()
                for expression in expressions {
                    try await expressionRepository.deleteExpression(id: expression.id)
                }
                
                await loadDataCounts()
            } catch {
                print("Failed to clear data: \(error)")
            }
        }
    }
    
    func handleExportResult(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            print("Exported to: \(url)")
        case .failure(let error):
            print("Export failed: \(error)")
        }
    }
    
    func handleImportResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                importData(from: url)
            }
        case .failure(let error):
            print("Import failed: \(error)")
        }
    }
    
    private func importData(from url: URL) {
        // Parse JSON and import data
    }
}

struct ExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    static var writableContentTypes: [UTType] { [.json] }
    
    var data: Data
    
    init(data: Data) {
        self.data = data
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
