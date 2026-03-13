import SwiftUI

struct ShortcutSettingsView: View {
    @StateObject private var viewModel = ShortcutSettingsViewModel()
    
    var body: some View {
        Form {
            Section(header: Text("快捷键说明")) {
                Text("点击快捷键组合进行编辑。注意避免与系统快捷键冲突。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ForEach(ShortcutCategory.allCases) { category in
                Section(header: Text(category.rawValue)) {
                    ForEach(viewModel.getShortcuts(for: category)) { shortcut in
                        ShortcutRow(
                            shortcut: shortcut,
                            isRecording: viewModel.recordingAction == shortcut.action,
                            onTap: { viewModel.startRecording(for: shortcut.action) },
                            onToggle: { viewModel.toggleShortcut(shortcut) }
                        )
                    }
                }
            }
            
            Section {
                Button("重置为默认") {
                    viewModel.resetToDefaults()
                }
                .foregroundColor(.red)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("快捷键设置")
        .alert("快捷键冲突", isPresented: .constant(viewModel.validationError != nil)) {
            Button("确定") { viewModel.validationError = nil }
        } message: {
            Text(viewModel.validationError ?? "")
        }
        .sheet(isPresented: $viewModel.isRecording) {
            ShortcutRecordingSheet(viewModel: viewModel)
        }
    }
}

struct ShortcutRow: View {
    let shortcut: KeyboardShortcut
    let isRecording: Bool
    let onTap: () -> Void
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(shortcut.action.displayName)
                    .font(.body)
                
                if !shortcut.description.isEmpty {
                    Text(shortcut.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // 快捷键显示
            Button(action: onTap) {
                HStack(spacing: 4) {
                    if isRecording {
                        Text("按下快捷键...")
                            .foregroundColor(.accentColor)
                    } else {
                        ForEach(Array(shortcut.keyCombo.modifiers), id: \.self) { modifier in
                            Text(modifier.displayString)
                                .font(.system(size: 14, weight: .medium))
                        }
                        Text(shortcut.keyCombo.key.displayString)
                            .font(.system(size: 14, weight: .medium))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isRecording ? Color.accentColor.opacity(0.1) : Color.gray.opacity(0.1))
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
            .disabled(!shortcut.isEnabled)
            
            // 启用开关
            Toggle("", isOn: Binding(
                get: { shortcut.isEnabled },
                set: { _ in onToggle() }
            ))
            .toggleStyle(.switch)
            .labelsHidden()
        }
        .padding(.vertical, 4)
    }
}

struct ShortcutRecordingSheet: View {
    @ObservedObject var viewModel: ShortcutSettingsViewModel
n    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("录制快捷键")
                .font(.title2)
                .fontWeight(.bold)
            
            if let action = viewModel.recordingAction {
                Text("为 \"\(action.displayName)\" 设置快捷键")
                    .foregroundColor(.secondary)
            }
            
            Image(systemName: "keyboard")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)
            
            Text("按下您想要的快捷键组合")
                .font(.headline)
            
            Text("支持 ⌘ Command、⌥ Option、⌃ Control、⇧ Shift 与其他键的组合")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 12) {
                Button("取消") {
                    viewModel.stopRecording()
                    dismiss()
                }
                
                Button("清除快捷键") {
                    viewModel.clearCurrentShortcut()
                    dismiss()
                }
            }
            .padding(.top)
        }
        .padding(40)
        .frame(width: 400)
    }
}

// MARK: - View Model

@MainActor
class ShortcutSettingsViewModel: ObservableObject {
    @Published var shortcuts: [KeyboardShortcut] = []
    @Published var selectedCategory: ShortcutCategory = .general
    @Published var isRecording = false
    @Published var recordingAction: ShortcutAction?
    @Published var validationError: String?
    
    private let shortcutManager = ShortcutManager.shared
    
    init() {
        loadShortcuts()
    }
    
    func loadShortcuts() {
        shortcuts = shortcutManager.getAllShortcuts()
    }
    
    func getShortcuts(for category: ShortcutCategory) -> [KeyboardShortcut] {
        return shortcuts.filter { $0.action.category == category }
    }
    
    func updateShortcut(_ shortcut: KeyboardShortcut, newKeyCombo: KeyCombination) {
        let validation = shortcutManager.validateShortcut(newKeyCombo)
        
        guard validation.isValid else {
            validationError = validation.errorMessage
            return
        }
        
        var updatedShortcut = shortcut
        updatedShortcut.keyCombo = newKeyCombo
        
        if shortcutManager.updateShortcut(updatedShortcut) {
            loadShortcuts()
            validationError = nil
        }
    }
    
    func toggleShortcut(_ shortcut: KeyboardShortcut) {
        var updatedShortcut = shortcut
        updatedShortcut.isEnabled.toggle()
        
        if updatedShortcut.isEnabled {
            _ = shortcutManager.registerShortcut(updatedShortcut)
        } else {
            shortcutManager.unregisterShortcut(updatedShortcut)
        }
        
        loadShortcuts()
    }
    
    func resetToDefaults() {
        shortcutManager.resetToDefaults()
        loadShortcuts()
    }
    
    func startRecording(for action: ShortcutAction) {
        isRecording = true
        recordingAction = action
    }
    
    func stopRecording() {
        isRecording = false
        recordingAction = nil
    }
    
    func clearCurrentShortcut() {
        // 清除当前快捷键
        if let action = recordingAction,
           let shortcut = shortcuts.first(where: { $0.action == action }) {
            var updated = shortcut
            updated.isEnabled = false
            _ = shortcutManager.updateShortcut(updated)
            loadShortcuts()
        }
        stopRecording()
    }
}

// MARK: - Supporting Types

enum ShortcutCategory: String, CaseIterable, Identifiable {
    case wordLearning = "单词学习"
    case literature = "文献管理"
    case writing = "写作辅助"
    case general = "通用"
    case ai = "AI 功能"
    
    var id: String { rawValue }
}

enum ShortcutAction: String, CaseIterable, Identifiable {
    case captureWord = "capture_word"
    case openVocabulary = "open_vocabulary"
    case startReview = "start_review"
    case quickAddWord = "quick_add_word"
    case importPDF = "import_pdf"
    case openLiterature = "open_literature"
    case searchInPDF = "search_in_pdf"
    case recognizeExpression = "recognize_expression"
    case openWritingAssistant = "open_writing_assistant"
    case showMainWindow = "show_main_window"
    case hideMainWindow = "hide_main_window"
    case toggleSidebar = "toggle_sidebar"
    case search = "search"
    case settings = "settings"
    case sync = "sync"
    case quickAsk = "quick_ask"
    case summarizeText = "summarize_text"
    case translate = "translate"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .captureWord: return "屏幕取词"
        case .openVocabulary: return "打开生词本"
        case .startReview: return "开始复习"
        case .quickAddWord: return "快速添加单词"
        case .importPDF: return "导入 PDF"
        case .openLiterature: return "打开文献"
        case .searchInPDF: return "在 PDF 中搜索"
        case .recognizeExpression: return "识别学术表达"
        case .openWritingAssistant: return "打开写作助手"
        case .showMainWindow: return "显示主窗口"
        case .hideMainWindow: return "隐藏主窗口"
        case .toggleSidebar: return "切换侧边栏"
        case .search: return "搜索"
        case .settings: return "设置"
        case .sync: return "同步"
        case .quickAsk: return "快速问答"
        case .summarizeText: return "总结文本"
        case .translate: return "翻译"
        }
    }
    
    var category: ShortcutCategory {
        switch self {
        case .captureWord, .openVocabulary, .startReview, .quickAddWord:
            return .wordLearning
        case .importPDF, .openLiterature, .searchInPDF:
            return .literature
        case .recognizeExpression, .openWritingAssistant:
            return .writing
        case .showMainWindow, .hideMainWindow, .toggleSidebar, .search, .settings, .sync:
            return .general
        case .quickAsk, .summarizeText, .translate:
            return .ai
        }
    }
}

struct KeyboardShortcut: Identifiable {
    let id = UUID()
    let action: ShortcutAction
    var keyCombo: KeyCombination
    var isEnabled: Bool
    var description: String
}

struct KeyCombination {
    var key: Key
    var modifiers: Set<ModifierKey>
}

enum Key: String, CaseIterable {
    case a, b, c, d, e, f, g, h, i, j, k, l, m
    case n, o, p, q, r, s, t, u, v, w, x, y, z
    case zero = "0", one = "1", two = "2", three = "3", four = "4"
    case five = "5", six = "6", seven = "7", eight = "8", nine = "9"
    case f1, f2, f3, f4, f5, f6, f7, f8, f9, f10, f11, f12
    case space = "Space"
    case tab = "Tab"
    case enter = "Enter"
    case escape = "Escape"
    case delete = "Delete"
    
    var displayString: String {
        switch self {
        case .space: return "␣"
        default: return rawValue.uppercased()
        }
    }
}

enum ModifierKey: String, CaseIterable {
    case command = "command"
    case option = "option"
    case control = "control"
    case shift = "shift"
    
    var displayString: String {
        switch self {
        case .command: return "⌘"
        case .option: return "⌥"
        case .control: return "⌃"
        case .shift: return "⇧"
        }
    }
}

// MARK: - Placeholder for ShortcutManager

class ShortcutManager {
    static let shared = ShortcutManager()
    
    func getAllShortcuts() -> [KeyboardShortcut] {
        // 返回默认快捷键
        return [
            KeyboardShortcut(action: .captureWord, keyCombo: KeyCombination(key: .c, modifiers: [.command, .option]), isEnabled: true, description: "激活屏幕取词功能"),
            KeyboardShortcut(action: .openVocabulary, keyCombo: KeyCombination(key: .v, modifiers: [.command]), isEnabled: true, description: "快速打开生词本"),
            KeyboardShortcut(action: .startReview, keyCombo: KeyCombination(key: .r, modifiers: [.command]), isEnabled: true, description: "开始单词复习"),
            KeyboardShortcut(action: .showMainWindow, keyCombo: KeyCombination(key: .one, modifiers: [.command]), isEnabled: true, description: "显示/隐藏主窗口"),
            KeyboardShortcut(action: .quickAsk, keyCombo: KeyCombination(key: .space, modifiers: [.command, .shift]), isEnabled: true, description: "快速向 AI 提问"),
            KeyboardShortcut(action: .search, keyCombo: KeyCombination(key: .f, modifiers: [.command]), isEnabled: true, description: "打开搜索"),
            KeyboardShortcut(action: .settings, keyCombo: KeyCombination(key: .comma, modifiers: [.command]), isEnabled: true, description: "打开设置")
        ]
    }
    
    func validateShortcut(_ keyCombo: KeyCombination) -> ShortcutValidationResult {
        // 验证快捷键是否有效
        return ShortcutValidationResult(isValid: true, errorMessage: nil)
    }
    
    func registerShortcut(_ shortcut: KeyboardShortcut) -> Bool {
        return true
    }
    
    func unregisterShortcut(_ shortcut: KeyboardShortcut) {
        // 注销快捷键
    }
    
    func updateShortcut(_ shortcut: KeyboardShortcut) -> Bool {
        return true
    }
    
    func resetToDefaults() {
        // 重置为默认设置
    }
}

struct ShortcutValidationResult {
    let isValid: Bool
    let errorMessage: String?
}
