import SwiftUI

// MARK: - Main Content View

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    
    var body: some View {
        NavigationSplitView {
            SidebarView(viewModel: viewModel)
        } detail: {
            DetailView(viewModel: viewModel)
        }
        .frame(minWidth: 1000, minHeight: 600)
    }
}

// MARK: - Sidebar View

struct SidebarView: View {
    @ObservedObject var viewModel: ContentViewModel
    
    var body: some View {
        List(selection: $viewModel.selectedTab) {
            // 学习模块
            Section("学习") {
                ForEach(Tab.learningTabs) { tab in
                    NavigationLink(value: tab) {
                        Label(tab.rawValue, systemImage: tab.icon)
                    }
                }
            }
            
            // 文献模块
            Section("文献") {
                ForEach(Tab.literatureTabs) { tab in
                    NavigationLink(value: tab) {
                        Label(tab.rawValue, systemImage: tab.icon)
                    }
                }
            }
            
            // 工具模块
            Section("工具") {
                ForEach(Tab.toolTabs) { tab in
                    NavigationLink(value: tab) {
                        Label(tab.rawValue, systemImage: tab.icon)
                    }
                }
            }
            
            // 设置模块
            Section("设置") {
                ForEach(Tab.settingsTabs) { tab in
                    NavigationLink(value: tab) {
                        Label(tab.rawValue, systemImage: tab.icon)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("AcademicHelper")
        .toolbar {
            ToolbarItem {
                Button {
                    viewModel.showingNotifications = true
                } label: {
                    NotificationBadge(count: viewModel.unreadNotificationCount)
                }
                .buttonStyle(.borderless)
                .popover(isPresented: $viewModel.showingNotifications) {
                    NotificationPopoverView()
                        .frame(width: 350, height: 400)
                }
            }
        }
    }
}

// MARK: - Detail View

struct DetailView: View {
    @ObservedObject var viewModel: ContentViewModel
    
    var body: some View {
        Group {
            switch viewModel.selectedTab {
            // 学习模块
            case .wordLearning:
                WordLearningView()
            case .review:
                ReviewView()
            case .vocabulary:
                VocabularyView()
            case .statistics:
                StatisticsView()
                
            // 文献模块
            case .literature:
                LiteratureManagementView()
            case .pdfReader:
                PDFReaderView()
            case .terminology:
                TerminologyView()
                
            // 工具模块
            case .writing:
                WritingAssistantView()
            case .aiAssistant:
                AIAssistantView()
                
            // 设置模块
            case .generalSettings:
                GeneralSettingsView()
            case .aiConfiguration:
                LLMConfigurationView()
            case .dataManagement:
                DataImportExportView()
            case .shortcuts:
                ShortcutSettingsView()
            case .notifications:
                NotificationSettingsView()
            }
        }
    }
}

// MARK: - Tab Enum

enum Tab: String, CaseIterable, Identifiable {
    // 学习模块
    case wordLearning = "单词学习"
    case review = "复习模式"
    case vocabulary = "词汇管理"
    case statistics = "学习统计"
    
    // 文献模块
    case literature = "文献管理"
    case pdfReader = "PDF 阅读器"
    case terminology = "术语库"
    
    // 工具模块
    case writing = "写作辅助"
    case aiAssistant = "AI 助手"
    
    // 设置模块
    case generalSettings = "通用设置"
    case aiConfiguration = "AI 配置"
    case dataManagement = "数据管理"
    case shortcuts = "快捷键"
    case notifications = "通知设置"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .wordLearning: return "character.book.closed"
        case .review: return "arrow.clockwise"
        case .vocabulary: return "textformat.abc"
        case .statistics: return "chart.bar.fill"
        case .literature: return "doc.text"
        case .pdfReader: return "doc.fill"
        case .terminology: return "books.vertical.fill"
        case .writing: return "pencil.line"
        case .aiAssistant: return "sparkles"
        case .generalSettings: return "gear"
        case .aiConfiguration: return "cpu.fill"
        case .dataManagement: return "externaldrive.fill"
        case .shortcuts: return "keyboard.fill"
        case .notifications: return "bell.fill"
        }
    }
    
    static var learningTabs: [Tab] { [.wordLearning, .review, .vocabulary, .statistics] }
    static var literatureTabs: [Tab] { [.literature, .pdfReader, .terminology] }
    static var toolTabs: [Tab] { [.writing, .aiAssistant] }
    static var settingsTabs: [Tab] { [.generalSettings, .aiConfiguration, .dataManagement, .shortcuts, .notifications] }
}

// MARK: - Notification Badge

struct NotificationBadge: View {
    let count: Int
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: "bell")
                .font(.system(size: 16))
            
            if count > 0 {
                Text("\(min(count, 99))")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.red)
                    .clipShape(Capsule())
                    .offset(x: 6, y: -6)
            }
        }
    }
}

// MARK: - Notification Popover View

struct NotificationPopoverView: View {
    @StateObject private var viewModel = NotificationPopoverViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("通知")
                    .font(.headline)
                
                Spacer()
                
                if viewModel.unreadCount > 0 {
                    Button("全部已读") {
                        viewModel.markAllAsRead()
                    }
                    .buttonStyle(.link)
                }
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            
            Divider()
            
            // 通知列表
            if viewModel.notifications.isEmpty {
                EmptyNotificationView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.notifications) { notification in
                            NotificationRow(notification: notification) {
                                viewModel.markAsRead(id: notification.id)
                            }
                            Divider()
                        }
                    }
                }
            }
            
            Divider()
            
            // 底部按钮
            HStack {
                Button("清除全部") {
                    viewModel.clearAll()
                }
                .buttonStyle(.link)
                .foregroundColor(.red)
                
                Spacer()
                
                Button("查看全部") {
                    // 打开通知中心
                }
                .buttonStyle(.link)
            }
            .padding()
            .background(Color(.controlBackgroundColor))
        }
    }
}

struct EmptyNotificationView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "bell.slash")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("暂无通知")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.textBackgroundColor))
    }
}

struct NotificationRow: View {
    let notification: AppNotification
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // 图标
            Image(systemName: notification.type.icon)
                .font(.system(size: 20))
                .foregroundColor(iconColor)
                .frame(width: 36, height: 36)
                .background(iconColor.opacity(0.1))
                .cornerRadius(8)
            
            // 内容
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(notification.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Text(notification.formattedTime)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 未读指示器
            if !notification.isRead {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
            }
        }
        .padding()
        .background(notification.isRead ? Color.clear : Color.blue.opacity(0.05))
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
    
    private var iconColor: Color {
        switch notification.type {
        case .dailyReminder: return .blue
        case .studyGoal: return .green
        case .reviewReminder: return .orange
        case .literatureUpdate: return .purple
        case .achievement: return .yellow
        case .system: return .gray
        }
    }
}

// MARK: - Placeholder Views

struct AIAssistantView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(.purple)
            
            Text("AI 助手")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("智能问答、文本分析和学术辅助功能即将推出")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct GeneralSettingsView: View {
    var body: some View {
        VStack {
            Text("通用设置")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct NotificationSettingsView: View {
    var body: some View {
        VStack {
            Text("通知设置")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - View Models

@MainActor
class ContentViewModel: ObservableObject {
    @Published var selectedTab: Tab = .wordLearning
    @Published var showingNotifications = false
    @Published var unreadNotificationCount = 0
    
    init() {
        updateUnreadCount()
    }
    
    private func updateUnreadCount() {
        Task {
            // 从 NotificationService 获取未读数量
            unreadNotificationCount = 0
        }
    }
}

@MainActor
class NotificationPopoverViewModel: ObservableObject {
    @Published var notifications: [AppNotification] = []
    @Published var unreadCount = 0
    
    init() {
        loadNotifications()
    }
    
    func loadNotifications() {
        // 模拟数据
        notifications = [
            AppNotification(
                type: .achievement,
                title: "🎉 学习达人",
                message: "恭喜！您已连续学习 7 天",
                isRead: false
            ),
            AppNotification(
                type: .dailyReminder,
                title: "学习提醒",
                message: "今天也要坚持学习哦！",
                isRead: true
            )
        ]
        unreadCount = notifications.filter { !$0.isRead }.count
    }
    
    func markAsRead(id: UUID) {
        if let index = notifications.firstIndex(where: { $0.id == id }) {
            var updated = notifications[index]
            updated = AppNotification(
                id: updated.id,
                type: updated.type,
                title: updated.title,
                message: updated.message,
                timestamp: updated.timestamp,
                isRead: true,
                actionURL: updated.actionURL,
                metadata: updated.metadata
            )
            notifications[index] = updated
            unreadCount = notifications.filter { !$0.isRead }.count
        }
    }
    
    func markAllAsRead() {
        notifications = notifications.map { notification in
            AppNotification(
                id: notification.id,
                type: notification.type,
                title: notification.title,
                message: notification.message,
                timestamp: notification.timestamp,
                isRead: true,
                actionURL: notification.actionURL,
                metadata: notification.metadata
            )
        }
        unreadCount = 0
    }
    
    func clearAll() {
        notifications.removeAll()
        unreadCount = 0
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
