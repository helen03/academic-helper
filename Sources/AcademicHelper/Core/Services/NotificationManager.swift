import Foundation
import UserNotifications

@MainActor
protocol NotificationManagerProtocol {
    func requestAuthorization() async -> Bool
    func scheduleReviewReminder(for words: [Word]) async
    func scheduleDailyReminder(at hour: Int, minute: Int) async
    func scheduleWordReminder(word: Word, delay: TimeInterval) async
    func cancelAllNotifications() async
    func cancelNotification(identifier: String) async
    func getPendingNotifications() async -> [UNNotificationRequest]
    func checkAuthorizationStatus() async -> UNAuthorizationStatus
}

@MainActor
final class NotificationManager: NotificationManagerProtocol {
    static let shared = NotificationManager()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private var isAuthorized = false
    
    private init() {}
    
    // MARK: - Authorization
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted
            return granted
        } catch {
            print("[Notification] Authorization error: \(error)")
            return false
        }
    }
    
    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus
    }
    
    // MARK: - Review Reminders
    
    /// 为待复习的单词安排提醒
    func scheduleReviewReminder(for words: [Word]) async {
        guard await checkAuthorizationStatus() == .authorized else {
            print("[Notification] Not authorized to schedule notifications")
            return
        }
        
        // 取消之前的复习提醒
        await cancelNotification(identifier: "reviewReminder")
        
        guard !words.isEmpty else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "📚 单词复习时间"
        content.body = "您有 \(words.count) 个单词需要复习，保持学习节奏！"
        content.sound = .default
        content.badge = NSNumber(value: words.count)
        content.categoryIdentifier = "REVIEW_CATEGORY"
        
        // 根据 SM-2 算法计算最佳提醒时间
        let nextReviewTime = calculateOptimalReminderTime(for: words)
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: nextReviewTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: "reviewReminder", content: content, trigger: trigger)
        
        do {
            try await notificationCenter.add(request)
            print("[Notification] Scheduled review reminder for \(words.count) words at \(nextReviewTime)")
        } catch {
            print("[Notification] Failed to schedule reminder: \(error)")
        }
    }
    
    /// 安排每日固定时间提醒
    func scheduleDailyReminder(at hour: Int, minute: Int) async {
        guard await checkAuthorizationStatus() == .authorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "🎯 今日学习目标"
        content.body = "是时候学习新单词了！坚持就是胜利。"
        content.sound = .default
        content.categoryIdentifier = "DAILY_CATEGORY"
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyReminder", content: content, trigger: trigger)
        
        do {
            try await notificationCenter.add(request)
            print("[Notification] Scheduled daily reminder at \(hour):\(String(format: "%02d", minute))")
        } catch {
            print("[Notification] Failed to schedule daily reminder: \(error)")
        }
    }
    
    /// 为特定单词安排延迟提醒
    func scheduleWordReminder(word: Word, delay: TimeInterval) async {
        guard await checkAuthorizationStatus() == .authorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "📝 复习: \(word.text)"
        content.body = word.definition ?? "点击查看详情"
        content.sound = .default
        content.userInfo = ["wordID": word.id.uuidString]
        content.categoryIdentifier = "WORD_REMINDER_CATEGORY"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(
            identifier: "wordReminder_\(word.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
            print("[Notification] Scheduled reminder for '\(word.text)' in \(delay) seconds")
        } catch {
            print("[Notification] Failed to schedule word reminder: \(error)")
        }
    }
    
    // MARK: - Cancel Notifications
    
    func cancelAllNotifications() async {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
        print("[Notification] Cancelled all notifications")
    }
    
    func cancelNotification(identifier: String) async {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        print("[Notification] Cancelled notification: \(identifier)")
    }
    
    // MARK: - Query
    
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await notificationCenter.pendingNotificationRequests()
    }
    
    // MARK: - Private Helpers
    
    private func calculateOptimalReminderTime(for words: [Word]) -> Date {
        let now = Date()
        let calendar = Calendar.current
        
        // 找到最早需要复习的单词时间
        let earliestReview = words.compactMap { $0.nextReviewAt }.min() ?? now
        
        // 如果复习时间已过，提醒时间为现在 + 5 分钟
        if earliestReview <= now {
            return calendar.date(byAdding: .minute, value: 5, to: now) ?? now
        }
        
        // 否则在复习时间提醒
        return earliestReview
    }
}

// MARK: - Notification Categories

extension NotificationManager {
    /// 注册通知类别和动作
    func registerNotificationCategories() {
        // 复习提醒类别
        let reviewNowAction = UNNotificationAction(
            identifier: "REVIEW_NOW",
            title: "立即复习",
            options: .foreground
        )
        
        let reviewLaterAction = UNNotificationAction(
            identifier: "REVIEW_LATER",
            title: "稍后提醒",
            options: []
        )
        
        let reviewCategory = UNNotificationCategory(
            identifier: "REVIEW_CATEGORY",
            actions: [reviewNowAction, reviewLaterAction],
            intentIdentifiers: [],
            options: []
        )
        
        // 每日提醒类别
        let startLearningAction = UNNotificationAction(
            identifier: "START_LEARNING",
            title: "开始学习",
            options: .foreground
        )
        
        let dailyCategory = UNNotificationCategory(
            identifier: "DAILY_CATEGORY",
            actions: [startLearningAction],
            intentIdentifiers: [],
            options: []
        )
        
        // 单词提醒类别
        let rememberAction = UNNotificationAction(
            identifier: "REMEMBER",
            title: "记住了 ✅",
            options: []
        )
        
        let forgetAction = UNNotificationAction(
            identifier: "FORGET",
            title: "再复习 📝",
            options: []
        )
        
        let wordCategory = UNNotificationCategory(
            identifier: "WORD_REMINDER_CATEGORY",
            actions: [rememberAction, forgetAction],
            intentIdentifiers: [],
            options: []
        )
        
        notificationCenter.setNotificationCategories([reviewCategory, dailyCategory, wordCategory])
    }
}

// MARK: - Notification Scheduler

@MainActor
final class ReviewReminderScheduler {
    private let notificationManager: NotificationManagerProtocol
    private let wordRepository: WordRepositoryProtocol
    
    init(
        notificationManager: NotificationManagerProtocol = NotificationManager.shared,
        wordRepository: WordRepositoryProtocol
    ) {
        self.notificationManager = notificationManager
        self.wordRepository = wordRepository
    }
    
    /// 检查并安排复习提醒
    func checkAndScheduleReminders() async {
        do {
            let wordsDueForReview = try await wordRepository.getWordsDueForReview()
            
            if !wordsDueForReview.isEmpty {
                await notificationManager.scheduleReviewReminder(for: wordsDueForReview)
            }
        } catch {
            print("[Scheduler] Failed to check reminders: \(error)")
        }
    }
    
    /// 安排明天的复习提醒
    func scheduleTomorrowReminder() async {
        // 每天早上 9 点提醒
        await notificationManager.scheduleDailyReminder(at: 9, minute: 0)
    }
    
    /// 为特定单词安排复习提醒
    func scheduleReminderForWord(_ word: Word) async {
        guard let nextReview = word.nextReviewAt else { return }
        
        let delay = nextReview.timeIntervalSince(Date())
        guard delay > 0 else { return }
        
        await notificationManager.scheduleWordReminder(word: word, delay: delay)
    }
}
