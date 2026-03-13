import Foundation
import AppKit
import Carbon

// MARK: - Shortcut Models

struct KeyboardShortcut: Codable, Identifiable, Equatable {
    let id: UUID
    var action: ShortcutAction
    var keyCombo: KeyCombination
    var isEnabled: Bool
    var description: String
    
    init(
        id: UUID = UUID(),
        action: ShortcutAction,
        keyCombo: KeyCombination,
        isEnabled: Bool = true,
        description: String = ""
    ) {
        self.id = id
        self.action = action
        self.keyCombo = keyCombo
        self.isEnabled = isEnabled
        self.description = description
    }
}

struct KeyCombination: Codable, Equatable {
    var key: Key
    var modifiers: Set<ModifierKey>
    
    var displayString: String {
        let modifierString = modifiers.sorted { $0.rawValue < $1.rawValue }
            .map { $0.displayString }
            .joined(separator: "+")
        
        if modifierString.isEmpty {
            return key.displayString
        }
        return "\(modifierString)+\(key.displayString)"
    }
    
    var carbonKeyCode: UInt32 {
        return key.carbonKeyCode
    }
    
    var carbonModifiers: UInt32 {
        return modifiers.reduce(0) { $0 | $1.carbonFlags }
    }
}

enum Key: String, Codable, CaseIterable {
    // Letters
    case a, b, c, d, e, f, g, h, i, j, k, l, m
    case n, o, p, q, r, s, t, u, v, w, x, y, z
    
    // Numbers
    case zero = "0", one = "1", two = "2", three = "3", four = "4"
    case five = "5", six = "6", seven = "7", eight = "8", nine = "9"
    
    // Function keys
    case f1, f2, f3, f4, f5, f6, f7, f8, f9, f10, f11, f12
    
    // Special keys
    case space = "Space"
    case tab = "Tab"
    case enter = "Enter"
    case escape = "Escape"
    case backspace = "Backspace"
    case delete = "Delete"
    case home = "Home"
    case end = "End"
    case pageUp = "Page Up"
    case pageDown = "Page Down"
    case up = "↑"
    case down = "↓"
    case left = "←"
    case right = "→"
    
    var displayString: String {
        switch self {
        case .space: return "␣"
        case .up, .down, .left, .right: return rawValue
        default: return rawValue.uppercased()
        }
    }
    
    var carbonKeyCode: UInt32 {
        switch self {
        case .a: return 0
        case .b: return 11
        case .c: return 8
        case .d: return 2
        case .e: return 14
        case .f: return 3
        case .g: return 5
        case .h: return 4
        case .i: return 34
        case .j: return 38
        case .k: return 40
        case .l: return 37
        case .m: return 46
        case .n: return 45
        case .o: return 31
        case .p: return 35
        case .q: return 12
        case .r: return 15
        case .s: return 1
        case .t: return 17
        case .u: return 32
        case .v: return 9
        case .w: return 13
        case .x: return 7
        case .y: return 16
        case .z: return 6
        case .zero: return 29
        case .one: return 18
        case .two: return 19
        case .three: return 20
        case .four: return 21
        case .five: return 23
        case .six: return 22
        case .seven: return 26
        case .eight: return 28
        case .nine: return 25
        case .f1: return 122
        case .f2: return 120
        case .f3: return 99
        case .f4: return 118
        case .f5: return 96
        case .f6: return 97
        case .f7: return 98
        case .f8: return 100
        case .f9: return 101
        case .f10: return 109
        case .f11: return 103
        case .f12: return 111
        case .space: return 49
        case .tab: return 48
        case .enter: return 36
        case .escape: return 53
        case .backspace: return 51
        case .delete: return 117
        case .home: return 115
        case .end: return 119
        case .pageUp: return 116
        case .pageDown: return 121
        case .up: return 126
        case .down: return 125
        case .left: return 123
        case .right: return 124
        }
    }
}

enum ModifierKey: Int, Codable, CaseIterable {
    case command = 0
    case option = 1
    case control = 2
    case shift = 3
    case function = 4
    
    var displayString: String {
        switch self {
        case .command: return "⌘"
        case .option: return "⌥"
        case .control: return "⌃"
        case .shift: return "⇧"
        case .function: return "fn"
        }
    }
    
    var carbonFlags: UInt32 {
        switch self {
        case .command: return UInt32(cmdKey)
        case .option: return UInt32(optionKey)
        case .control: return UInt32(controlKey)
        case .shift: return UInt32(shiftKey)
        case .function: return 0x8000
        }
    }
    
    var eventModifierFlags: NSEvent.ModifierFlags {
        switch self {
        case .command: return .command
        case .option: return .option
        case .control: return .control
        case .shift: return .shift
        case .function: return .function
        }
    }
}

enum ShortcutAction: String, Codable, CaseIterable, Identifiable {
    // Word Learning
    case captureWord = "capture_word"
    case openVocabulary = "open_vocabulary"
    case startReview = "start_review"
    case quickAddWord = "quick_add_word"
    
    // Literature
    case importPDF = "import_pdf"
    case openLiterature = "open_literature"
    case searchInPDF = "search_in_pdf"
    
    // Writing Assistant
    case recognizeExpression = "recognize_expression"
    case openWritingAssistant = "open_writing_assistant"
    
    // General
    case showMainWindow = "show_main_window"
    case hideMainWindow = "hide_main_window"
    case toggleSidebar = "toggle_sidebar"
    case search = "search"
    case settings = "settings"
    case sync = "sync"
    
    // LLM Features
    case quickAsk = "quick_ask"
    case summarizeText = "summarize_text"
    case translate = "translate"
    
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
    
    var defaultShortcut: KeyboardShortcut? {
        switch self {
        case .captureWord:
            return KeyboardShortcut(
                action: self,
                keyCombo: KeyCombination(key: .c, modifiers: [.command, .option]),
                description: "激活屏幕取词功能"
            )
        case .openVocabulary:
            return KeyboardShortcut(
                action: self,
                keyCombo: KeyCombination(key: .v, modifiers: [.command]),
                description: "快速打开生词本"
            )
        case .startReview:
            return KeyboardShortcut(
                action: self,
                keyCombo: KeyCombination(key: .r, modifiers: [.command]),
                description: "开始单词复习"
            )
        case .showMainWindow:
            return KeyboardShortcut(
                action: self,
                keyCombo: KeyCombination(key: .one, modifiers: [.command]),
                description: "显示/隐藏主窗口"
            )
        case .quickAsk:
            return KeyboardShortcut(
                action: self,
                keyCombo: KeyCombination(key: .space, modifiers: [.command, .shift]),
                description: "快速向 AI 提问"
            )
        case .search:
            return KeyboardShortcut(
                action: self,
                keyCombo: KeyCombination(key: .f, modifiers: [.command]),
                description: "打开搜索"
            )
        case .settings:
            return KeyboardShortcut(
                action: self,
                keyCombo: KeyCombination(key: .comma, modifiers: [.command]),
                description: "打开设置"
            )
        default:
            return nil
        }
    }
}

enum ShortcutCategory: String, CaseIterable {
    case wordLearning = "单词学习"
    case literature = "文献管理"
    case writing = "写作辅助"
    case general = "通用"
    case ai = "AI 功能"
}

// MARK: - Shortcut Manager Protocol

@MainActor
protocol ShortcutManagerProtocol {
    func registerShortcut(_ shortcut: KeyboardShortcut) -> Bool
    func unregisterShortcut(_ shortcut: KeyboardShortcut)
    func updateShortcut(_ shortcut: KeyboardShortcut) -> Bool
    func getAllShortcuts() -> [KeyboardShortcut]
    func getShortcuts(for category: ShortcutCategory) -> [KeyboardShortcut]
    func getShortcut(for action: ShortcutAction) -> KeyboardShortcut?
    func resetToDefaults()
    func validateShortcut(_ keyCombo: KeyCombination) -> ShortcutValidationResult
    func importShortcuts(from url: URL) throws
    func exportShortcuts(to url: URL) throws
}

struct ShortcutValidationResult {
    let isValid: Bool
    let conflictsWith: KeyboardShortcut?
    let errorMessage: String?
}

// MARK: - Shortcut Manager Implementation

@MainActor
final class ShortcutManager: ShortcutManagerProtocol {
    
    static let shared = ShortcutManager()
    
    private var shortcuts: [KeyboardShortcut] = []
    private var eventHandler: EventHandlerRef?
    private var hotKeyCallbacks: [UInt32: () -> Void] = [:]
    
    private init() {
        loadDefaultShortcuts()
        registerGlobalShortcuts()
    }
    
    deinit {
        unregisterAllShortcuts()
    }
    
    // MARK: - Public Methods
    
    func registerShortcut(_ shortcut: KeyboardShortcut) -> Bool {
        // 检查冲突
        let validation = validateShortcut(shortcut.keyCombo)
        guard validation.isValid else {
            print("[ShortcutManager] Failed to register shortcut: \(validation.errorMessage ?? "Unknown error")")
            return false
        }
        
        // 注册 Carbon 热键
        let hotKeyID = UInt32(shortcuts.count + 1)
        var eventHotKey: EventHotKeyRef?
        
        let status = RegisterEventHotKey(
            shortcut.keyCombo.carbonKeyCode,
            shortcut.keyCombo.carbonModifiers,
            EventHotKeyID(signature: 0x41434850, id: hotKeyID),
            GetEventDispatcherTarget(),
            0,
            &eventHotKey
        )
        
        guard status == noErr else {
            print("[ShortcutManager] Failed to register Carbon hotkey: \(status)")
            return false
        }
        
        // 存储回调
        hotKeyCallbacks[hotKeyID] = { [weak self] in
            self?.handleShortcutAction(shortcut.action)
        }
        
        // 更新列表
        if let index = shortcuts.firstIndex(where: { $0.action == shortcut.action }) {
            shortcuts[index] = shortcut
        } else {
            shortcuts.append(shortcut)
        }
        
        saveShortcuts()
        return true
    }
    
    func unregisterShortcut(_ shortcut: KeyboardShortcut) {
        // 从列表中移除
        shortcuts.removeAll { $0.id == shortcut.id }
        
        // 重新注册所有快捷键
        reregisterAllShortcuts()
        saveShortcuts()
    }
    
    func updateShortcut(_ shortcut: KeyboardShortcut) -> Bool {
        unregisterShortcut(shortcut)
        return registerShortcut(shortcut)
    }
    
    func getAllShortcuts() -> [KeyboardShortcut] {
        return shortcuts
    }
    
    func getShortcuts(for category: ShortcutCategory) -> [KeyboardShortcut] {
        return shortcuts.filter { $0.action.category == category }
    }
    
    func getShortcut(for action: ShortcutAction) -> KeyboardShortcut? {
        return shortcuts.first { $0.action == action }
    }
    
    func resetToDefaults() {
        shortcuts.removeAll()
        loadDefaultShortcuts()
        reregisterAllShortcuts()
        saveShortcuts()
    }
    
    func validateShortcut(_ keyCombo: KeyCombination) -> ShortcutValidationResult {
        // 检查是否已存在
        if let existing = shortcuts.first(where: { 
            $0.keyCombo.key == keyCombo.key && 
            $0.keyCombo.modifiers == keyCombo.modifiers &&
            $0.isEnabled 
        }) {
            return ShortcutValidationResult(
                isValid: false,
                conflictsWith: existing,
                errorMessage: "快捷键与 '\(existing.action.displayName)' 冲突"
            )
        }
        
        // 检查系统保留快捷键
        if isSystemReserved(keyCombo) {
            return ShortcutValidationResult(
                isValid: false,
                conflictsWith: nil,
                errorMessage: "该快捷键被系统保留"
            )
        }
        
        return ShortcutValidationResult(isValid: true, conflictsWith: nil, errorMessage: nil)
    }
    
    func importShortcuts(from url: URL) throws {
        let data = try Data(contentsOf: url)
        let importedShortcuts = try JSONDecoder().decode([KeyboardShortcut].self, from: data)
        
        // 清除现有快捷键
        unregisterAllShortcuts()
        
        // 导入新快捷键
        for shortcut in importedShortcuts {
            _ = registerShortcut(shortcut)
        }
    }
    
    func exportShortcuts(to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(shortcuts)
        try data.write(to: url)
    }
    
    // MARK: - Private Methods
    
    private func loadDefaultShortcuts() {
        for action in ShortcutAction.allCases {
            if let defaultShortcut = action.defaultShortcut {
                shortcuts.append(defaultShortcut)
            }
        }
        
        // 从 UserDefaults 加载自定义设置
        if let savedData = UserDefaults.standard.data(forKey: "keyboard_shortcuts"),
           let savedShortcuts = try? JSONDecoder().decode([KeyboardShortcut].self, from: savedData) {
            
            // 合并保存的设置
            for saved in savedShortcuts {
                if let index = shortcuts.firstIndex(where: { $0.action == saved.action }) {
                    shortcuts[index] = saved
                }
            }
        }
    }
    
    private func saveShortcuts() {
        if let data = try? JSONEncoder().encode(shortcuts) {
            UserDefaults.standard.set(data, forKey: "keyboard_shortcuts")
        }
    }
    
    private func registerGlobalShortcuts() {
        // 安装事件处理器
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed)
        )
        
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        
        let callback: EventHandlerUPP = { _, eventRef, userData -> OSStatus in
            guard let eventRef = eventRef,
                  let userData = userData else { return OSStatus(eventNotHandledErr) }
            
            var hotKeyID = EventHotKeyID()
            GetEventParameter(
                eventRef,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )
            
            let manager = Unmanaged<ShortcutManager>.fromOpaque(userData).takeUnretainedValue()
            manager.hotKeyCallbacks[hotKeyID.id]?()
            
            return noErr
        }
        
        InstallEventHandler(
            GetEventDispatcherTarget(),
            callback,
            1,
            &eventType,
            selfPtr,
            &eventHandler
        )
        
        // 注册所有启用的快捷键
        for shortcut in shortcuts where shortcut.isEnabled {
            _ = registerShortcut(shortcut)
        }
    }
    
    private func unregisterAllShortcuts() {
        // 注销所有 Carbon 热键
        // 实际实现需要跟踪每个热键的引用
        hotKeyCallbacks.removeAll()
    }
    
    private func reregisterAllShortcuts() {
        unregisterAllShortcuts()
        for shortcut in shortcuts where shortcut.isEnabled {
            _ = registerShortcut(shortcut)
        }
    }
    
    private func handleShortcutAction(_ action: ShortcutAction) {
        print("[ShortcutManager] Shortcut triggered: \(action.displayName)")
        
        // 发送通知或执行操作
        NotificationCenter.default.post(
            name: .shortcutTriggered,
            object: nil,
            userInfo: ["action": action]
        )
        
        // 直接执行操作
        executeAction(action)
    }
    
    private func executeAction(_ action: ShortcutAction) {
        switch action {
        case .captureWord:
            // 触发屏幕取词
            NotificationCenter.default.post(name: .startWordCapture, object: nil)
        case .openVocabulary:
            // 打开生词本
            NotificationCenter.default.post(name: .showVocabularyView, object: nil)
        case .startReview:
            // 开始复习
            NotificationCenter.default.post(name: .startReviewSession, object: nil)
        case .showMainWindow:
            // 显示主窗口
            NSApp.activate(ignoringOtherApps: true)
        case .quickAsk:
            // 显示快速问答弹窗
            NotificationCenter.default.post(name: .showQuickAskPanel, object: nil)
        case .search:
            // 打开搜索
            NotificationCenter.default.post(name: .showSearchPanel, object: nil)
        case .settings:
            // 打开设置
            NotificationCenter.default.post(name: .showSettingsView, object: nil)
        default:
            break
        }
    }
    
    private func isSystemReserved(_ keyCombo: KeyCombination) -> Bool {
        // 检查是否是系统保留的快捷键
        let reservedCombos: [(Key, Set<ModifierKey>)] = [
            (.c, [.command]),           // Copy
            (.v, [.command]),           // Paste
            (.x, [.command]),           // Cut
            (.z, [.command]),           // Undo
            (.a, [.command]),           // Select All
            (.s, [.command]),           // Save
            (.q, [.command]),           // Quit
            (.w, [.command]),           // Close Window
            (.n, [.command]),           // New
            (.o, [.command]),           // Open
            (.p, [.command]),           // Print
            (.f, [.command]),           // Find
            (.h, [.command]),           // Hide
            (.m, [.command]),           // Minimize
            (.tab, [.command]),         // Switch App
            (.space, [.command, .shift]), // Spotlight
            (.space, [.control]),        // Input Method
            (.escape, []),              // Cancel
        ]
        
        return reservedCombos.contains { $0.0 == keyCombo.key && $0.1 == keyCombo.modifiers }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let shortcutTriggered = Notification.Name("shortcutTriggered")
    static let startWordCapture = Notification.Name("startWordCapture")
    static let showVocabularyView = Notification.Name("showVocabularyView")
    static let startReviewSession = Notification.Name("startReviewSession")
    static let showQuickAskPanel = Notification.Name("showQuickAskPanel")
    static let showSearchPanel = Notification.Name("showSearchPanel")
    static let showSettingsView = Notification.Name("showSettingsView")
}

// MARK: - Shortcut Settings View Model

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
}
