import SwiftUI
import Combine

// MARK: - General Settings Model

struct GeneralSettings: Codable, Equatable {
    // 外观设置
    var appearance: AppearanceMode = .system
    var accentColor: AccentColorOption = .blue
    
    // 字体设置
    var fontSize: FontSize = .medium
    var fontFamily: FontFamily = .system
    
    // 启动设置
    var launchAtLogin: Bool = false
    var defaultTab: DefaultTab = .wordLearning
    var showDockIcon: Bool = true
    
    // 语言设置
    var language: AppLanguage = .system
    
    // 窗口设置
    var rememberWindowPosition: Bool = true
    var windowWidth: CGFloat = 1200
    var windowHeight: CGFloat = 800
    
    enum AppearanceMode: String, Codable, CaseIterable, Identifiable {
        case light = "light"
        case dark = "dark"
        case system = "system"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .light: return "浅色"
            case .dark: return "深色"
            case .system: return "跟随系统"
            }
        }
        
        var icon: String {
            switch self {
            case .light: return "sun.max.fill"
            case .dark: return "moon.fill"
            case .system: return "circle.lefthalf.filled"
            }
        }
    }
    
    enum AccentColorOption: String, Codable, CaseIterable, Identifiable {
        case blue = "blue"
        case purple = "purple"
        case pink = "pink"
        case red = "red"
        case orange = "orange"
        case yellow = "yellow"
        case green = "green"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .blue: return "蓝色"
            case .purple: return "紫色"
            case .pink: return "粉色"
            case .red: return "红色"
            case .orange: return "橙色"
            case .yellow: return "黄色"
            case .green: return "绿色"
            }
        }
        
        var color: Color {
            switch self {
            case .blue: return .blue
            case .purple: return .purple
            case .pink: return .pink
            case .red: return .red
            case .orange: return .orange
            case .yellow: return .yellow
            case .green: return .green
            }
        }
    }
    
    enum FontSize: String, Codable, CaseIterable, Identifiable {
        case small = "small"
        case medium = "medium"
        case large = "large"
        case extraLarge = "extraLarge"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .small: return "小"
            case .medium: return "中"
            case .large: return "大"
            case .extraLarge: return "超大"
            }
        }
        
        var scale: CGFloat {
            switch self {
            case .small: return 0.9
            case .medium: return 1.0
            case .large: return 1.1
            case .extraLarge: return 1.2
            }
        }
    }
    
    enum FontFamily: String, Codable, CaseIterable, Identifiable {
        case system = "system"
        case sfPro = "SF Pro"
        case pingFang = "PingFang SC"
        case helvetica = "Helvetica"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .system: return "系统默认"
            case .sfPro: return "SF Pro"
            case .pingFang: return "苹方"
            case .helvetica: return "Helvetica"
            }
        }
    }
    
    enum DefaultTab: String, Codable, CaseIterable, Identifiable {
        case wordLearning = "wordLearning"
        case literature = "literature"
        case writing = "writing"
        case lastUsed = "lastUsed"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .wordLearning: return "单词学习"
            case .literature: return "文献管理"
            case .writing: return "写作辅助"
            case .lastUsed: return "上次使用"
            }
        }
    }
    
    enum AppLanguage: String, Codable, CaseIterable, Identifiable {
        case system = "system"
        case simplifiedChinese = "zh-Hans"
        case english = "en"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .system: return "跟随系统"
            case .simplifiedChinese: return "简体中文"
            case .english: return "English"
            }
        }
    }
}

// MARK: - Settings Store

@MainActor
final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()
    
    @Published var generalSettings: GeneralSettings {
        didSet {
            saveSettings()
            applySettings()
        }
    }
    
    private let settingsKey = "general_settings"
    
    private init() {
        self.generalSettings = Self.loadSettings()
        applySettings()
    }
    
    private static func loadSettings() -> GeneralSettings {
        if let data = UserDefaults.standard.data(forKey: "general_settings"),
           let settings = try? JSONDecoder().decode(GeneralSettings.self, from: data) {
            return settings
        }
        return GeneralSettings()
    }
    
    private func saveSettings() {
        if let data = try? JSONEncoder().encode(generalSettings) {
            UserDefaults.standard.set(data, forKey: settingsKey)
        }
    }
    
    private func applySettings() {
        // 应用外观设置
        applyAppearance()
        
        // 应用字体设置
        applyFontSettings()
        
        // 应用启动设置
        applyLaunchSettings()
    }
    
    private func applyAppearance() {
        // 外观模式在 SwiftUI 中通过 .preferredColorScheme 应用
        // 实际应用需要在 App 级别处理
    }
    
    private func applyFontSettings() {
        // 字体设置通过动态类型或自定义修饰符应用
    }
    
    private func applyLaunchSettings() {
        // 开机启动设置
        let shouldLaunchAtLogin = generalSettings.launchAtLogin
        // 使用 SMLoginItemSetEnabled 或类似 API 设置
        // 注意：需要配置 Helper Bundle
    }
    
    func resetToDefaults() {
        generalSettings = GeneralSettings()
    }
}

// MARK: - General Settings View

struct GeneralSettingsView: View {
    @StateObject private var viewModel = GeneralSettingsViewModel()
    @State private var showingResetConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 外观设置
                AppearanceSection(viewModel: viewModel)
                
                Divider()
                
                // 字体设置
                FontSection(viewModel: viewModel)
                
                Divider()
                
                // 启动设置
                LaunchSection(viewModel: viewModel)
                
                Divider()
                
                // 语言设置
                LanguageSection(viewModel: viewModel)
                
                Divider()
                
                // 窗口设置
                WindowSection(viewModel: viewModel)
                
                Divider()
                
                // 重置按钮
                ResetSection(showingConfirmation: $showingResetConfirmation, viewModel: viewModel)
            }
            .padding()
        }
        .navigationTitle("通用设置")
        .alert("重置设置", isPresented: $showingResetConfirmation) {
            Button("取消", role: .cancel) { }
            Button("重置", role: .destructive) {
                viewModel.resetToDefaults()
            }
        } message: {
            Text("确定要将所有设置恢复为默认值吗？此操作不可撤销。")
        }
    }
}

// MARK: - Appearance Section

struct AppearanceSection: View {
    @ObservedObject var viewModel: GeneralSettingsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "paintbrush.fill")
                    .font(.title2)
                    .foregroundColor(.purple)
                
                Text("外观")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            // 外观模式选择
            VStack(alignment: .leading, spacing: 8) {
                Text("外观模式")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Picker("外观模式", selection: $viewModel.appearance) {
                    ForEach(GeneralSettings.AppearanceMode.allCases) { mode in
                        HStack {
                            Image(systemName: mode.icon)
                            Text(mode.displayName)
                        }
                        .tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
            
            // 强调色选择
            VStack(alignment: .leading, spacing: 8) {
                Text("强调色")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 60))
                ], spacing: 12) {
                    ForEach(GeneralSettings.AccentColorOption.allCases) { color in
                        AccentColorButton(
                            color: color,
                            isSelected: viewModel.accentColor == color,
                            action: { viewModel.accentColor = color }
                        )
                    }
                }
            }
            
            // 预览
            VStack(alignment: .leading, spacing: 8) {
                Text("预览")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack(spacing: 12) {
                    Button("主要按钮") { }
                        .buttonStyle(.borderedProminent)
                    
                    Button("次要按钮") { }
                        .buttonStyle(.bordered)
                    
                    Toggle("开关", isOn: .constant(true))
                        .toggleStyle(.switch)
                        .labelsHidden()
                }
                .padding()
                .background(Color(.textBackgroundColor))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct AccentColorButton: View {
    let color: GeneralSettings.AccentColorOption
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Circle()
                    .fill(color.color)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color.primary : Color.clear, lineWidth: 2)
                    )
                
                Text(color.displayName)
                    .font(.caption)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Font Section

struct FontSection: View {
    @ObservedObject var viewModel: GeneralSettingsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "textformat")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("字体")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            // 字体大小
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("字体大小")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text(viewModel.fontSize.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Picker("字体大小", selection: $viewModel.fontSize) {
                    ForEach(GeneralSettings.FontSize.allCases) { size in
                        Text(size.displayName).tag(size)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
            
            // 字体族
            VStack(alignment: .leading, spacing: 8) {
                Text("字体")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Picker("字体", selection: $viewModel.fontFamily) {
                    ForEach(GeneralSettings.FontFamily.allCases) { family in
                        Text(family.displayName).tag(family)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }
            
            // 预览
            VStack(alignment: .leading, spacing: 8) {
                Text("预览")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("这是标题文本")
                        .font(.title2)
                    Text("这是正文文本，用于展示当前字体设置的效果。The quick brown fox jumps over the lazy dog.")
                        .font(.body)
                    Text("这是小号文本")
                        .font(.caption)
                }
                .padding()
                .background(Color(.textBackgroundColor))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Launch Section

struct LaunchSection: View {
    @ObservedObject var viewModel: GeneralSettingsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "power")
                    .font(.title2)
                    .foregroundColor(.green)
                
                Text("启动")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            // 开机启动
            Toggle(isOn: $viewModel.launchAtLogin) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("开机时启动")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("系统登录时自动启动 AcademicHelper")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .toggleStyle(.switch)
            
            // 默认页面
            VStack(alignment: .leading, spacing: 8) {
                Text("启动时显示")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Picker("默认页面", selection: $viewModel.defaultTab) {
                    ForEach(GeneralSettings.DefaultTab.allCases) { tab in
                        Text(tab.displayName).tag(tab)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }
            
            // Dock 图标
            Toggle(isOn: $viewModel.showDockIcon) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("在 Dock 中显示图标")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("关闭后应用将只在菜单栏显示")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .toggleStyle(.switch)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Language Section

struct LanguageSection: View {
    @ObservedObject var viewModel: GeneralSettingsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "globe")
                    .font(.title2)
                    .foregroundColor(.orange)
                
                Text("语言")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("界面语言")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Picker("界面语言", selection: $viewModel.language) {
                    ForEach(GeneralSettings.AppLanguage.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }
            
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("更改语言需要重启应用才能生效")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Window Section

struct WindowSection: View {
    @ObservedObject var viewModel: GeneralSettingsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "macwindow")
                    .font(.title2)
                    .foregroundColor(.cyan)
                
                Text("窗口")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            Toggle(isOn: $viewModel.rememberWindowPosition) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("记住窗口位置")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("下次启动时恢复上次关闭时的窗口位置和大小")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .toggleStyle(.switch)
            
            // 默认窗口大小
            VStack(alignment: .leading, spacing: 8) {
                Text("默认窗口大小")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("宽度")
                            .font(.caption)
                        TextField("宽度", value: $viewModel.windowWidth, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("高度")
                            .font(.caption)
                        TextField("高度", value: $viewModel.windowHeight, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                    }
                    
                    Text("像素")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Reset Section

struct ResetSection: View {
    @Binding var showingConfirmation: Bool
    @ObservedObject var viewModel: GeneralSettingsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "arrow.counterclockwise")
                    .font(.title2)
                    .foregroundColor(.red)
                
                Text("重置")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("恢复默认设置")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("将所有设置恢复为默认值")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("重置...") {
                    showingConfirmation = true
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - View Model

@MainActor
class GeneralSettingsViewModel: ObservableObject {
    private let store = SettingsStore.shared
    
    @Published var appearance: GeneralSettings.AppearanceMode {
        didSet { store.generalSettings.appearance = appearance }
    }
    
    @Published var accentColor: GeneralSettings.AccentColorOption {
        didSet { store.generalSettings.accentColor = accentColor }
    }
    
    @Published var fontSize: GeneralSettings.FontSize {
        didSet { store.generalSettings.fontSize = fontSize }
    }
    
    @Published var fontFamily: GeneralSettings.FontFamily {
        didSet { store.generalSettings.fontFamily = fontFamily }
    }
    
    @Published var launchAtLogin: Bool {
        didSet { store.generalSettings.launchAtLogin = launchAtLogin }
    }
    
    @Published var defaultTab: GeneralSettings.DefaultTab {
        didSet { store.generalSettings.defaultTab = defaultTab }
    }
    
    @Published var showDockIcon: Bool {
        didSet { store.generalSettings.showDockIcon = showDockIcon }
    }
    
    @Published var language: GeneralSettings.AppLanguage {
        didSet { store.generalSettings.language = language }
    }
    
    @Published var rememberWindowPosition: Bool {
        didSet { store.generalSettings.rememberWindowPosition = rememberWindowPosition }
    }
    
    @Published var windowWidth: CGFloat {
        didSet { store.generalSettings.windowWidth = windowWidth }
    }
    
    @Published var windowHeight: CGFloat {
        didSet { store.generalSettings.windowHeight = windowHeight }
    }
    
    init() {
        let settings = store.generalSettings
        self.appearance = settings.appearance
        self.accentColor = settings.accentColor
        self.fontSize = settings.fontSize
        self.fontFamily = settings.fontFamily
        self.launchAtLogin = settings.launchAtLogin
        self.defaultTab = settings.defaultTab
        self.showDockIcon = settings.showDockIcon
        self.language = settings.language
        self.rememberWindowPosition = settings.rememberWindowPosition
        self.windowWidth = settings.windowWidth
        self.windowHeight = settings.windowHeight
    }
    
    func resetToDefaults() {
        store.resetToDefaults()
        
        let settings = store.generalSettings
        appearance = settings.appearance
        accentColor = settings.accentColor
        fontSize = settings.fontSize
        fontFamily = settings.fontFamily
        launchAtLogin = settings.launchAtLogin
        defaultTab = settings.defaultTab
        showDockIcon = settings.showDockIcon
        language = settings.language
        rememberWindowPosition = settings.rememberWindowPosition
        windowWidth = settings.windowWidth
        windowHeight = settings.windowHeight
    }
}

// MARK: - Preview

struct GeneralSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        GeneralSettingsView()
    }
}
