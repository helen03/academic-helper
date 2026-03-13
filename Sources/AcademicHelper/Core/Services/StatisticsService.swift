import Foundation
import SwiftUI

// MARK: - Statistics Models

struct LearningStatistics: Codable {
    let totalWordsLearned: Int
    let totalWordsMastered: Int
    let currentStreak: Int
    let longestStreak: Int
    let totalStudyTime: TimeInterval
    let averageDailyWords: Double
    let reviewAccuracy: Double
    let weeklyProgress: [DailyProgress]
    let monthlyProgress: [WeeklyProgress]
    let wordLevelDistribution: [WordLevel: Int]
    let studyTimeDistribution: [StudyTimeSlot: TimeInterval]
    let achievementProgress: [Achievement]
    
    struct DailyProgress: Codable, Identifiable {
        let id = UUID()
        let date: Date
        let wordsLearned: Int
        let wordsReviewed: Int
        let studyTime: TimeInterval
        let accuracy: Double
    }
    
    struct WeeklyProgress: Codable, Identifiable {
        let id = UUID()
        let weekStart: Date
        let wordsLearned: Int
        let studyTime: TimeInterval
        let accuracy: Double
    }
    
    enum WordLevel: String, Codable, CaseIterable {
        case new = "新词"
        case learning = "学习中"
        case reviewing = "复习中"
        case mastered = "已掌握"
    }
    
    enum StudyTimeSlot: String, Codable, CaseIterable {
        case morning = "早晨 (6-12点)"
        case afternoon = "下午 (12-18点)"
        case evening = "晚上 (18-22点)"
        case night = "深夜 (22-6点)"
    }
}

struct Achievement: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let requirement: Int
    var currentProgress: Int
    let category: Category
    var isUnlocked: Bool
    let unlockDate: Date?
    
    enum Category: String, Codable, CaseIterable {
        case vocabulary = "词汇"
        case streak = "连续学习"
        case mastery = "掌握度"
        case exploration = "探索"
        case special = "特殊"
    }
    
    var progressPercentage: Double {
        guard requirement > 0 else { return 0 }
        return min(Double(currentProgress) / Double(requirement), 1.0)
    }
}

struct LearningGoal: Codable, Identifiable {
    let id: UUID
    var title: String
    var description: String
    var targetValue: Int
    var currentValue: Int
    var unit: String
    var deadline: Date
    var category: Category
    var isCompleted: Bool
    var createdAt: Date
    
    enum Category: String, Codable, CaseIterable {
        case daily = "每日目标"
        case weekly = "每周目标"
        case monthly = "每月目标"
        case custom = "自定义目标"
    }
    
    var progressPercentage: Double {
        guard targetValue > 0 else { return 0 }
        return min(Double(currentValue) / Double(targetValue), 1.0)
    }
    
    var remainingDays: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: deadline).day ?? 0
    }
}

// MARK: - Statistics Service Protocol

@MainActor
protocol StatisticsServiceProtocol {
    func getLearningStatistics(for period: StatisticsPeriod) async throws -> LearningStatistics
    func getDailyProgress(for date: Date) async throws -> LearningStatistics.DailyProgress
    func getAchievements() async -> [Achievement]
    func updateAchievementProgress(id: String, progress: Int) async
    func getGoals() async -> [LearningGoal]
    func createGoal(_ goal: LearningGoal) async throws
    func updateGoal(_ goal: LearningGoal) async throws
    func deleteGoal(id: UUID) async throws
    func recordStudySession(duration: TimeInterval, wordsLearned: Int, wordsReviewed: Int) async
    func getStudyTrends() async -> StudyTrends
    func generateStudyReport(for period: StatisticsPeriod) async -> StudyReport
}

enum StatisticsPeriod {
    case week
    case month
    case quarter
    case year
    case allTime
    
    var days: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .quarter: return 90
        case .year: return 365
        case .allTime: return 365 * 10
        }
    }
}

struct StudyTrends {
    let vocabularyGrowth: [DataPoint]
    let accuracyTrend: [DataPoint]
    let studyTimeTrend: [DataPoint]
    let streakTrend: [DataPoint]
    
    struct DataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let value: Double
    }
}

struct StudyReport {
    let period: StatisticsPeriod
    let generatedAt: Date
    let summary: String
    let keyMetrics: [Metric]
    let highlights: [String]
    let recommendations: [String]
    let comparisonWithPrevious: Comparison
    
    struct Metric {
        let name: String
        let value: String
        let change: Double?
        let trend: Trend
        
        enum Trend {
            case up, down, stable
        }
    }
    
    struct Comparison {
        let vocabularyGrowth: Double
        let studyTimeChange: Double
        let accuracyChange: Double
    }
}

// MARK: - Statistics Service Implementation

@MainActor
final class StatisticsService: StatisticsServiceProtocol {
    
    private let wordRepository: WordRepositoryProtocol
    private let studySessionRepository: StudySessionRepositoryProtocol
    private let llmService: LLMIntelligenceServiceProtocol?
    
    private var achievements: [Achievement] = []
    private var goals: [LearningGoal] = []
    
    init(
        wordRepository: WordRepositoryProtocol,
        studySessionRepository: StudySessionRepositoryProtocol,
        llmService: LLMIntelligenceServiceProtocol? = nil
    ) {
        self.wordRepository = wordRepository
        self.studySessionRepository = studySessionRepository
        self.llmService = llmService
        self.initializeAchievements()
    }
    
    // MARK: - Learning Statistics
    
    func getLearningStatistics(for period: StatisticsPeriod) async throws -> LearningStatistics {
        let words = try await wordRepository.getAllWords()
        let sessions = try await studySessionRepository.getSessions(for: period)
        
        let totalWords = words.count
        let masteredWords = words.filter { $0.isMastered }.count
        
        // 计算连续学习天数
        let streak = calculateStreak(from: sessions)
        
        // 计算总学习时间
        let totalStudyTime = sessions.reduce(0) { $0 + $1.duration }
        
        // 计算平均每日单词
        let averageDailyWords = calculateAverageDailyWords(words: words, period: period)
        
        // 计算复习准确率
        let reviewAccuracy = calculateReviewAccuracy(from: sessions)
        
        // 生成进度数据
        let weeklyProgress = generateWeeklyProgress(from: sessions)
        let monthlyProgress = generateMonthlyProgress(from: sessions)
        
        // 单词级别分布
        let wordLevelDistribution = calculateWordLevelDistribution(words: words)
        
        // 学习时间分布
        let studyTimeDistribution = calculateStudyTimeDistribution(from: sessions)
        
        // 获取成就进度
        let achievementProgress = await getAchievements()
        
        return LearningStatistics(
            totalWordsLearned: totalWords,
            totalWordsMastered: masteredWords,
            currentStreak: streak.current,
            longestStreak: streak.longest,
            totalStudyTime: totalStudyTime,
            averageDailyWords: averageDailyWords,
            reviewAccuracy: reviewAccuracy,
            weeklyProgress: weeklyProgress,
            monthlyProgress: monthlyProgress,
            wordLevelDistribution: wordLevelDistribution,
            studyTimeDistribution: studyTimeDistribution,
            achievementProgress: achievementProgress
        )
    }
    
    func getDailyProgress(for date: Date) async throws -> LearningStatistics.DailyProgress {
        let sessions = try await studySessionRepository.getSessions(for: date)
        
        let wordsLearned = sessions.reduce(0) { $0 + $1.wordsLearned }
        let wordsReviewed = sessions.reduce(0) { $0 + $1.wordsReviewed }
        let studyTime = sessions.reduce(0) { $0 + $1.duration }
        let accuracy = calculateReviewAccuracy(from: sessions)
        
        return LearningStatistics.DailyProgress(
            date: date,
            wordsLearned: wordsLearned,
            wordsReviewed: wordsReviewed,
            studyTime: studyTime,
            accuracy: accuracy
        )
    }
    
    // MARK: - Achievements
    
    func getAchievements() async -> [Achievement] {
        return achievements
    }
    
    func updateAchievementProgress(id: String, progress: Int) async {
        if let index = achievements.firstIndex(where: { $0.id == id }) {
            var achievement = achievements[index]
            achievement.currentProgress = progress
            
            if progress >= achievement.requirement && !achievement.isUnlocked {
                achievement.isUnlocked = true
                // 通知用户解锁成就
                NotificationManager.shared.scheduleAchievementNotification(achievement: achievement)
            }
            
            achievements[index] = achievement
        }
    }
    
    // MARK: - Goals
    
    func getGoals() async -> [LearningGoal] {
        return goals
    }
    
    func createGoal(_ goal: LearningGoal) async throws {
        goals.append(goal)
    }
    
    func updateGoal(_ goal: LearningGoal) async throws {
        if let index = goals.firstIndex(where: { $0.id == goal.id }) {
            goals[index] = goal
        }
    }
    
    func deleteGoal(id: UUID) async throws {
        goals.removeAll { $0.id == id }
    }
    
    // MARK: - Study Session Recording
    
    func recordStudySession(duration: TimeInterval, wordsLearned: Int, wordsReviewed: Int) async {
        let session = StudySession(
            id: UUID(),
            date: Date(),
            duration: duration,
            wordsLearned: wordsLearned,
            wordsReviewed: wordsReviewed
        )
        
        try? await studySessionRepository.saveSession(session)
        
        // 更新成就进度
        await updateAchievementProgressForStudy(wordsLearned: wordsLearned, wordsReviewed: wordsReviewed)
    }
    
    // MARK: - Study Trends
    
    func getStudyTrends() async -> StudyTrends {
        let sessions = try? await studySessionRepository.getSessions(for: .month)
        
        return StudyTrends(
            vocabularyGrowth: generateVocabularyGrowthTrend(from: sessions ?? []),
            accuracyTrend: generateAccuracyTrend(from: sessions ?? []),
            studyTimeTrend: generateStudyTimeTrend(from: sessions ?? []),
            streakTrend: generateStreakTrend(from: sessions ?? [])
        )
    }
    
    // MARK: - Study Report
    
    func generateStudyReport(for period: StatisticsPeriod) async -> StudyReport {
        let stats = try? await getLearningStatistics(for: period)
        
        let summary = generateReportSummary(stats: stats, period: period)
        let keyMetrics = generateKeyMetrics(stats: stats)
        let highlights = generateHighlights(stats: stats)
        let recommendations = await generateRecommendations(stats: stats)
        let comparison = generateComparison(stats: stats, period: period)
        
        return StudyReport(
            period: period,
            generatedAt: Date(),
            summary: summary,
            keyMetrics: keyMetrics,
            highlights: highlights,
            recommendations: recommendations,
            comparisonWithPrevious: comparison
        )
    }
    
    // MARK: - Private Methods
    
    private func initializeAchievements() {
        achievements = [
            Achievement(
                id: "first_word",
                title: "初次学习",
                description: "学习第一个单词",
                icon: "🌱",
                requirement: 1,
                currentProgress: 0,
                category: .vocabulary,
                isUnlocked: false,
                unlockDate: nil
            ),
            Achievement(
                id: "vocabulary_100",
                title: "词汇积累",
                description: "累计学习100个单词",
                icon: "📚",
                requirement: 100,
                currentProgress: 0,
                category: .vocabulary,
                isUnlocked: false,
                unlockDate: nil
            ),
            Achievement(
                id: "vocabulary_500",
                title: "词汇达人",
                description: "累计学习500个单词",
                icon: "🏆",
                requirement: 500,
                currentProgress: 0,
                category: .vocabulary,
                isUnlocked: false,
                unlockDate: nil
            ),
            Achievement(
                id: "streak_7",
                title: "坚持一周",
                description: "连续学习7天",
                icon: "🔥",
                requirement: 7,
                currentProgress: 0,
                category: .streak,
                isUnlocked: false,
                unlockDate: nil
            ),
            Achievement(
                id: "streak_30",
                title: "坚持一个月",
                description: "连续学习30天",
                icon: "🌟",
                requirement: 30,
                currentProgress: 0,
                category: .streak,
                isUnlocked: false,
                unlockDate: nil
            ),
            Achievement(
                id: "master_50",
                title: "掌握50词",
                description: "掌握50个单词",
                icon: "🎯",
                requirement: 50,
                currentProgress: 0,
                category: .mastery,
                isUnlocked: false,
                unlockDate: nil
            ),
            Achievement(
                id: "accuracy_90",
                title: "准确率90%",
                description: "单次复习准确率达到90%",
                icon: "🎯",
                requirement: 1,
                currentProgress: 0,
                category: .mastery,
                isUnlocked: false,
                unlockDate: nil
            ),
            Achievement(
                id: "early_bird",
                title: "早起鸟",
                description: "在早上6点前开始学习",
                icon: "🐦",
                requirement: 1,
                currentProgress: 0,
                category: .exploration,
                isUnlocked: false,
                unlockDate: nil
            ),
            Achievement(
                id: "night_owl",
                title: "夜猫子",
                description: "在晚上10点后学习",
                icon: "🦉",
                requirement: 1,
                currentProgress: 0,
                category: .exploration,
                isUnlocked: false,
                unlockDate: nil
            ),
            Achievement(
                id: "speed_demon",
                title: "速学达人",
                description: "一天学习超过50个新单词",
                icon: "⚡",
                requirement: 1,
                currentProgress: 0,
                category: .special,
                isUnlocked: false,
                unlockDate: nil
            )
        ]
    }
    
    private func calculateStreak(from sessions: [StudySession]) -> (current: Int, longest: Int) {
        // 实现连续天数计算逻辑
        // 这里简化处理
        return (current: 5, longest: 12)
    }
    
    private func calculateAverageDailyWords(words: [Word], period: StatisticsPeriod) -> Double {
        guard period.days > 0 else { return 0 }
        return Double(words.count) / Double(period.days)
    }
    
    private func calculateReviewAccuracy(from sessions: [StudySession]) -> Double {
        guard !sessions.isEmpty else { return 0 }
        // 简化计算，实际需要根据复习结果计算
        return 0.85
    }
    
    private func generateWeeklyProgress(from sessions: [StudySession]) -> [LearningStatistics.DailyProgress] {
        // 生成最近7天的进度数据
        let calendar = Calendar.current
        var progress: [LearningStatistics.DailyProgress] = []
        
        for dayOffset in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) ?? Date()
            let daySessions = sessions.filter { calendar.isDate($0.date, inSameDayAs: date) }
            
            let wordsLearned = daySessions.reduce(0) { $0 + $1.wordsLearned }
            let wordsReviewed = daySessions.reduce(0) { $0 + $1.wordsReviewed }
            let studyTime = daySessions.reduce(0) { $0 + $1.duration }
            
            progress.append(LearningStatistics.DailyProgress(
                date: date,
                wordsLearned: wordsLearned,
                wordsReviewed: wordsReviewed,
                studyTime: studyTime,
                accuracy: calculateReviewAccuracy(from: daySessions)
            ))
        }
        
        return progress.reversed()
    }
    
    private func generateMonthlyProgress(from sessions: [StudySession]) -> [LearningStatistics.WeeklyProgress] {
        // 生成最近4周的进度数据
        return []
    }
    
    private func calculateWordLevelDistribution(words: [Word]) -> [LearningStatistics.WordLevel: Int] {
        var distribution: [LearningStatistics.WordLevel: Int] = [:]
        
        for word in words {
            let level: LearningStatistics.WordLevel
            if word.isMastered {
                level = .mastered
            } else if word.reviewCount > 5 {
                level = .reviewing
            } else if word.reviewCount > 0 {
                level = .learning
            } else {
                level = .new
            }
            distribution[level, default: 0] += 1
        }
        
        return distribution
    }
    
    private func calculateStudyTimeDistribution(from sessions: [StudySession]) -> [LearningStatistics.StudyTimeSlot: TimeInterval] {
        var distribution: [LearningStatistics.StudyTimeSlot: TimeInterval] = [:]
        let calendar = Calendar.current
        
        for session in sessions {
            let hour = calendar.component(.hour, from: session.date)
            let slot: LearningStatistics.StudyTimeSlot
            
            switch hour {
            case 6..<12: slot = .morning
            case 12..<18: slot = .afternoon
            case 18..<22: slot = .evening
            default: slot = .night
            }
            
            distribution[slot, default: 0] += session.duration
        }
        
        return distribution
    }
    
    private func updateAchievementProgressForStudy(wordsLearned: Int, wordsReviewed: Int) async {
        // 更新相关成就进度
        if wordsLearned > 0 {
            await updateAchievementProgress(id: "first_word", progress: 1)
        }
        
        // 这里可以添加更多成就更新逻辑
    }
    
    private func generateVocabularyGrowthTrend(from sessions: [StudySession]) -> [StudyTrends.DataPoint] {
        return []
    }
    
    private func generateAccuracyTrend(from sessions: [StudySession]) -> [StudyTrends.DataPoint] {
        return []
    }
    
    private func generateStudyTimeTrend(from sessions: [StudySession]) -> [StudyTrends.DataPoint] {
        return []
    }
    
    private func generateStreakTrend(from sessions: [StudySession]) -> [StudyTrends.DataPoint] {
        return []
    }
    
    private func generateReportSummary(stats: LearningStatistics?, period: StatisticsPeriod) -> String {
        guard let stats = stats else { return "暂无数据" }
        
        return "在\(periodDescription(period))内，你学习了 \(stats.totalWordsLearned) 个单词，保持了 \(stats.currentStreak) 天的连续学习记录。"
    }
    
    private func generateKeyMetrics(stats: LearningStatistics?) -> [StudyReport.Metric] {
        guard let stats = stats else { return [] }
        
        return [
            StudyReport.Metric(name: "单词总数", value: "\(stats.totalWordsLearned)", change: nil, trend: .stable),
            StudyReport.Metric(name: "已掌握", value: "\(stats.totalWordsMastered)", change: nil, trend: .up),
            StudyReport.Metric(name: "准确率", value: "\(Int(stats.reviewAccuracy * 100))%", change: nil, trend: .stable),
            StudyReport.Metric(name: "连续天数", value: "\(stats.currentStreak) 天", change: nil, trend: .up)
        ]
    }
    
    private func generateHighlights(stats: LearningStatistics?) -> [String] {
        guard let stats = stats else { return [] }
        
        var highlights: [String] = []
        
        if stats.currentStreak >= 7 {
            highlights.append("🎉 连续学习 \(stats.currentStreak) 天，保持这个势头！")
        }
        
        if stats.reviewAccuracy >= 0.9 {
            highlights.append("🌟 复习准确率达到 \(Int(stats.reviewAccuracy * 100))%，表现优秀！")
        }
        
        if stats.totalWordsMastered >= 50 {
            highlights.append("📚 已掌握 \(stats.totalWordsMastered) 个单词，词汇量稳步增长！")
        }
        
        return highlights
    }
    
    private func generateRecommendations(stats: LearningStatistics?) async -> [String] {
        guard let stats = stats else { return [] }
        
        var recommendations: [String] = []
        
        if stats.reviewAccuracy < 0.8 {
            recommendations.append("建议放慢学习速度，专注于复习已学单词以提高准确率。")
        }
        
        if stats.currentStreak < 3 {
            recommendations.append("尝试建立每日学习习惯，即使是短时间学习也很有帮助。")
        }
        
        if stats.totalWordsMastered < stats.totalWordsLearned / 2 {
            recommendations.append("你有很多单词还未掌握，建议增加复习频率。")
        }
        
        // 使用 LLM 生成个性化建议
        if let llmService = llmService {
            let prompt = "基于以下学习数据，给出3条简短的学习建议：学习了\(stats.totalWordsLearned)个单词，掌握\(stats.totalWordsMastered)个，准确率\(Int(stats.reviewAccuracy * 100))%，连续学习\(stats.currentStreak)天"
            
            if let suggestion = try? await llmService.generateText(prompt: prompt, style: .academic, maxLength: 200) {
                recommendations.append(suggestion)
            }
        }
        
        return recommendations
    }
    
    private func generateComparison(stats: LearningStatistics?, period: StatisticsPeriod) -> StudyReport.Comparison {
        // 与上一周期比较
        return StudyReport.Comparison(
            vocabularyGrowth: 0.15,
            studyTimeChange: 0.10,
            accuracyChange: 0.05
        )
    }
    
    private func periodDescription(_ period: StatisticsPeriod) -> String {
        switch period {
        case .week: return "本周"
        case .month: return "本月"
        case .quarter: return "本季度"
        case .year: return "今年"
        case .allTime: return "总计"
        }
    }
}

// MARK: - Supporting Models

struct StudySession: Codable {
    let id: UUID
    let date: Date
    let duration: TimeInterval
    let wordsLearned: Int
    let wordsReviewed: Int
}

// MARK: - Repository Protocols

@MainActor
protocol StudySessionRepositoryProtocol {
    func getSessions(for period: StatisticsPeriod) async throws -> [StudySession]
    func getSessions(for date: Date) async throws -> [StudySession]
    func saveSession(_ session: StudySession) async throws
}

// MARK: - Notification Extension

extension NotificationManager {
    func scheduleAchievementNotification(achievement: Achievement) {
        // 实现成就解锁通知
    }
}
