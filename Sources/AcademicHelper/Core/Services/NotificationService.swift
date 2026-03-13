import Foundation
import UserNotifications
import Combine

// MARK: - Notification Types

enum NotificationType: String, CaseIterable {
    case dailyReminder = "daily_reminder"
    case studyGoal = "study_goal"
    case reviewReminder = "review_reminder"
    case literatureUpdate = "literature_update"
    case achievement = "achievement"
    case system = "system"
    
    var title: String {
        switch self {
        case .dailyReminder: return "每日提醒"
        case .studyGoal: return "学习目标"
        case .reviewReminder: return "复习提醒"
        case .literatureUpdate: return "文献更新"
        case .achievement: return "成就解锁"
        case .system: return "系统通知"
        }
    }
    
    var icon: String {
        switch self {
        case .dailyReminder: return "bell.fill"
        case .studyGoal: return "target"
        case .reviewReminder: return "arrow.clockwise"
        case .literatureUpdate: return "doc.text"
        case .achievement: return "trophy.fill"
        case .system: return "gear"
        }
    }
    
    var defaultSound: String {
        switch self {
        case .achievement: return "achievement.caf"
        default: return "default.caf"
        }
    }
}

// MARK: - Notification Model

struct AppNotification: Identifiable, Codable, Equatable {
    let id: UUID
    let type: NotificationType
    let title: String
    let message: String
    let timestamp: Date
    let isRead: Bool
    let actionURL: String?
    let metadata: [String: String]?
    
    init(
        id: UUID = UUID(),
        type: NotificationType,
        title: String,
        message: String,
        timestamp: Date = Date(),
        isRead: Bool = false,
        actionURL: String? = nil,
        metadata: [String: String]? = nil
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.message = message
        self.timestamp = timestamp
        self.isRead = isRead
        self.actionURL = actionURL
        self.metadata = metadata
    }
    
    var formattedTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

// MARK: - Notification Settings

struct NotificationSettings: Codable {
    var isEnabled: Bool = true
    var dailyReminderEnabled: Bool = true
    var dailyReminderTime: Date = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    var studyGoalEnabled: Bool = true
    var reviewReminderEnabled: Bool = true
    var literatureUpdateEnabled: Bool = false
    var achievementEnabled: Bool = true
    var soundEnabled: Bool = true
    var badgeEnabled: Bool = true
    var previewEnabled: Bool = true
    
    var dailyGoal: Int = 20
    var reviewInterval: TimeInterval = 3600 // 1 hour
}

// MARK: - Notification Service Protocol

@MainActor
protocol NotificationServiceProtocol {
    func requestAuthorization() async throws -> Bool
    func scheduleNotification(_ notification: AppNotification, delay: TimeInterval) async
    func scheduleDailyReminder(at time: Date) async
    func cancelNotification(id: String) async
    func cancelAllNotifications() async
    func getPendingNotifications() async -> [UNNotificationRequest]
    func getNotificationHistory() async -> [AppNotification]
    func markAsRead(id: UUID) async
    func markAllAsRead() async
    func clearHistory() async
    func updateSettings(_ settings: NotificationSettings) async
    func getUnreadCount() async -> Int
}

// MARK: - Notification Service Implementation

@MainActor
final class NotificationService: NSObject, NotificationServiceProtocol {
    
    // MARK: - Properties
    
    private let notificationCenter = UNUserNotificationCenter.current
    private var settings: NotificationSettings
    private var notificationHistory: [AppNotification] = []
    private let maxHistoryCount = 100
    
    private let settingsKey = "notification_settings"
    private let historyKey = "notification_history"
    
    @Published private(set) var unreadCount: Int = 0
    @Published private(set) var isAuthorized: Bool = false
    
    // MARK: - Singleton
    
    static let shared = NotificationService()
    
    private override init() {
        self.settings = NotificationSettings()
        super.init()
        notificationCenter.delegate = self
        loadSettings()
        loadHistory()
        updateUnreadCount()
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() async throws -> Bool {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        let granted = try await notificationCenter.requestAuthorization(options: options)
        
        await MainActor.run {
            self.isAuthorized = granted
            self.settings.isEnabled = granted
            self.saveSettings()
        }
        
        if granted {
            await registerNotificationCategories()
        }
        
        return granted
    }
    
    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus
    }
    
    // MARK: - Scheduling
    
    func scheduleNotification(_ notification: AppNotification, delay: TimeInterval = 0) async {
        guard settings.isEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.message
        content.sound = settings.soundEnabled ? .default : nil
        content.badge = settings.badgeEnabled ? NSNumber(value: unreadCount + 1) : nil
        content.userInfo = [
            "id": notification.id.uuidString,
            "type": notification.type.rawValue,
            "actionURL": notification.actionURL ?? ""
        ]
        content.categoryIdentifier = notification.type.rawValue
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(delay, 1), repeats: false)
        let request = UNNotificationRequest(
            identifier: notification.id.uuidString,
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
            addToHistory(notification)
        } catch {
            print("[NotificationService] Failed to schedule notification: \(error)")
        }
    }
    
    func scheduleDailyReminder(at time: Date) async {
        guard settings.dailyReminderEnabled else { return }
        
        // 取消现有的每日提醒
        await cancelNotification(id: "daily_reminder")
        
        let content = UNMutableNotificationContent()
        content.title = "学习提醒"
        content.body = "今天也要坚持学习哦！完成每日目标，积累知识。"
        content.sound = .default
        content.categoryIdentifier = NotificationType.dailyReminder.rawValue
        
        var dateComponents = Calendar.current.dateComponents([.hour, .minute], from: time)
        dateComponents.second = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "daily_reminder",
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
        } catch {
            print("[NotificationService] Failed to schedule daily reminder: \(error)")
        }
    }
    
    func scheduleReviewReminder(for wordId: UUID, word: String, delay: TimeInterval) async {
        guard settings.reviewReminderEnabled else { return }
        
        let notification = AppNotification(
            type: .reviewReminder,
            title: "复习提醒",
            message: "该复习单词 \"\(word)\" 了",
            metadata: ["wordId": wordId.uuidString]
        )
        
        await scheduleNotification(notification, delay: delay)
    }
    
    func scheduleStudyGoalReminder(progress: Double) async {
        guard settings.studyGoalEnabled, progress < 1.0 else { return }
        
        let remaining = Int((1.0 - progress) * Double(settings.dailyGoal))
        
        let notification = AppNotification(
            type: .studyGoal,
            title: "学习目标进度",
            message: "今日目标还差 \(remaining) 个单词，加油！"
        )
        
        await scheduleNotification(notification, delay: 3600) // 1小时后提醒
    }
    
    func sendAchievementNotification(title: String, description: String) async {
        guard settings.achievementEnabled else { return }
        
        let notification = AppNotification(
            type: .achievement,
            title: "🎉 \(title)",
            message: description
        )
        
        await scheduleNotification(notification)
    }
    
    // MARK: - Cancellation
    
    func cancelNotification(id: String) async {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [id])
    }
    
    func cancelAllNotifications() async {
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    func cancelNotificationsByType(_ type: NotificationType) async {
        let pending = await getPendingNotifications()
        let idsToCancel = pending
            .filter { $0.content.categoryIdentifier == type.rawValue }
            .map { $0.identifier }
        
        notificationCenter.removePendingNotificationRequests(withIdentifiers: idsToCancel)
    }
    
    // MARK: - Query
    
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await notificationCenter.pendingNotificationRequests()
    }
    
    func getDeliveredNotifications() async -> [UNNotification] {
        return await notificationCenter.deliveredNotifications()
    }
    
    func getNotificationHistory() async -> [AppNotification] {
        return notificationHistory.sorted { $0.timestamp > $1.timestamp }
    }
    
    func getUnreadNotifications() async -> [AppNotification] {
        return notificationHistory.filter { !$0.isRead }
    }
    
    func getNotificationsByType(_ type: NotificationType) async -> [AppNotification] {
        return notificationHistory.filter { $0.type == type }
    }
    
    // MARK: - History Management
    
    private func addToHistory(_ notification: AppNotification) {
        notificationHistory.insert(notification, at: 0)
        
        // 限制历史记录数量
        if notificationHistory.count > maxHistoryCount {
            notificationHistory.removeLast(notificationHistory.count - maxHistoryCount)
        }
        
        saveHistory()
        updateUnreadCount()
    }
    
    func markAsRead(id: UUID) async {
        if let index = notificationHistory.firstIndex(where: { $0.id == id }) {
            var updated = notificationHistory[index]
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
            notificationHistory[index] = updated
            saveHistory()
            updateUnreadCount()
        }
    }
    
    func markAllAsRead() async {
        notificationHistory = notificationHistory.map { notification in
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
        saveHistory()
        updateUnreadCount()
    }
    
    func clearHistory() async {
        notificationHistory.removeAll()
        saveHistory()
        updateUnreadCount()
    }
    
    func deleteNotification(id: UUID) async {
        notificationHistory.removeAll { $0.id == id }
        saveHistory()
        updateUnreadCount()
    }
    
    // MARK: - Settings
    
    func updateSettings(_ newSettings: NotificationSettings) async {
        settings = newSettings
        saveSettings()
        
        // 根据新设置重新调度通知
        if settings.dailyReminderEnabled {
            await scheduleDailyReminder(at: settings.dailyReminderTime)
        } else {
            await cancelNotification(id: "daily_reminder")
        }
    }
    
    func getSettings() -> NotificationSettings {
        return settings
    }
    
    private func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let loaded = try? JSONDecoder().decode(NotificationSettings.self, from: data) {
            settings = loaded
        }
    }
    
    private func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: settingsKey)
        }
    }
    
    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: historyKey),
           let loaded = try? JSONDecoder().decode([AppNotification].self, from: data) {
            notificationHistory = loaded
        }
    }
    
    private func saveHistory() {
        if let data = try? JSONEncoder().encode(notificationHistory) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
    }
    
    private func updateUnreadCount() {
        unreadCount = notificationHistory.filter { !$0.isRead }.count
    }
    
    // MARK: - Categories
    
    private func registerNotificationCategories() async {
        let actions: [UNNotificationAction] = [
            UNNotificationAction(
                identifier: "MARK_AS_READ",
                title: "标记为已读",
                options: .foreground
            ),
            UNNotificationAction(
                identifier: "DISMISS",
                title: "忽略",
                options: .destructive
            )
        ]
        
        let categories: [UNNotificationCategory] = NotificationType.allCases.map { type in
            UNNotificationCategory(
                identifier: type.rawValue,
                actions: actions,
                intentIdentifiers: [],
                options: .customDismissAction
            )
        }
        
        notificationCenter.setNotificationCategories(Set(categories))
    }
    
    // MARK: - Badge
    
    func updateBadgeCount() async {
        let count = settings.badgeEnabled ? unreadCount : 0
        await MainActor.run {
            NSApplication.shared.dockTile.badgeLabel = count > 0 ? "\(count)" : nil
        }
    }
    
    func clearBadge() async {
        await MainActor.run {
            NSApplication.shared.dockTile.badgeLabel = nil
        }
        notificationCenter.setBadgeCount(0)
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
    
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        Task { @MainActor in
            if let idString = userInfo["id"] as? String,
               let id = UUID(uuidString: idString) {
                await self.markAsRead(id: id)
            }
            
            switch response.actionIdentifier {
            case "MARK_AS_READ":
                // 已处理
                break
            case "DISMISS":
                if let idString = userInfo["id"] as? String,
                   let id = UUID(uuidString: idString) {
                    await self.deleteNotification(id: id)
                }
            default:
                // 处理点击通知
                if let actionURL = userInfo["actionURL"] as? String,
                   !actionURL.isEmpty,
                   let url = URL(string: actionURL) {
                    NSWorkspace.shared.open(url)
                }
            }
        }
        
        completionHandler()
    }
}

// MARK: - Convenience Methods

extension NotificationService {
    
    func sendImmediateNotification(
        type: NotificationType,
        title: String,
        message: String,
        actionURL: String? = nil
    ) async {
        let notification = AppNotification(
            type: type,
            title: title,
            message: message,
            actionURL: actionURL
        )
        await scheduleNotification(notification)
    }
    
    func scheduleWordReminder(word: String, delay: TimeInterval) async {
        let notification = AppNotification(
            type: .reviewReminder,
            title: "单词复习",
            message: "记得复习单词 \"\(word)\""
        )
        await scheduleNotification(notification, delay: delay)
    }
    
    func scheduleLiteratureReminder(title: String, delay: TimeInterval) async {
        let notification = AppNotification(
            type: .literatureUpdate,
            title: "文献提醒",
            message: "继续阅读 \"\(title)\""
        )
        await scheduleNotification(notification, delay: delay)
    }
}
