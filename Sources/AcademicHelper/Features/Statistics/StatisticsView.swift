import SwiftUI
import Charts

struct StatisticsView: View {
    @StateObject private var viewModel = StatisticsViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 概览卡片
                OverviewCardsSection(viewModel: viewModel)
                
                // 学习趋势图表
                LearningTrendChart(viewModel: viewModel)
                
                // 单词级别分布
                WordLevelDistributionChart(viewModel: viewModel)
                
                // 学习时间分布
                StudyTimeDistributionChart(viewModel: viewModel)
                
                // 成就展示
                AchievementsSection(viewModel: viewModel)
                
                // 学习目标
                LearningGoalsSection(viewModel: viewModel)
            }
            .padding()
        }
        .navigationTitle("学习统计")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { viewModel.generateReport() }) {
                    Label("生成报告", systemImage: "doc.text")
                }
            }
        }
    }
}

// MARK: - Overview Cards

struct OverviewCardsSection: View {
    @ObservedObject var viewModel: StatisticsViewModel
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            StatCard(
                title: "总单词数",
                value: "\(viewModel.totalWords)",
                icon: "book.fill",
                color: .blue
            )
            
            StatCard(
                title: "已掌握",
                value: "\(viewModel.masteredWords)",
                icon: "checkmark.circle.fill",
                color: .green
            )
            
            StatCard(
                title: "连续学习",
                value: "\(viewModel.currentStreak) 天",
                icon: "flame.fill",
                color: .orange
            )
            
            StatCard(
                title: "准确率",
                value: "\(Int(viewModel.accuracy * 100))%",
                icon: "target",
                color: .purple
            )
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(value)
                        .font(.system(size: 32, weight: .bold))
                    Text(title)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Learning Trend Chart

struct LearningTrendChart: View {
    @ObservedObject var viewModel: StatisticsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("学习趋势")
                .font(.headline)
            
            if #available(macOS 13.0, *) {
                Chart(viewModel.weeklyProgress) { day in
                    LineMark(
                        x: .value("日期", day.date, unit: .day),
                        y: .value("单词数", day.wordsLearned)
                    )
                    .foregroundStyle(.blue)
                    
                    AreaMark(
                        x: .value("日期", day.date, unit: .day),
                        y: .value("单词数", day.wordsLearned)
                    )
                    .foregroundStyle(.blue.opacity(0.1))
                }
                .frame(height: 200)
            } else {
                // Fallback for older macOS
                Text("图表需要 macOS 13.0+")
                    .foregroundColor(.secondary)
                    .frame(height: 200)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Word Level Distribution

struct WordLevelDistributionChart: View {
    @ObservedObject var viewModel: StatisticsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("单词掌握度分布")
                .font(.headline)
            
            HStack(spacing: 20) {
                ForEach(viewModel.wordLevelData, id: \.level) { item in
                    VStack {
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 40, height: 100)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(item.color)
                                .frame(width: 40, height: CGFloat(item.percentage) * 100)
                        }
                        
                        Text("\(item.count)")
                            .font(.caption)
                            .fontWeight(.bold)
                        
                        Text(item.level)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Study Time Distribution

struct StudyTimeDistributionChart: View {
    @ObservedObject var viewModel: StatisticsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("学习时间分布")
                .font(.headline)
            
            if #available(macOS 13.0, *) {
                Chart(viewModel.studyTimeData) { item in
                    SectorMark(
                        angle: .value("时间", item.minutes),
                        innerRadius: .ratio(0.5)
                    )
                    .foregroundStyle(by: .value("时段", item.timeSlot))
                }
                .frame(height: 200)
            } else {
                Text("图表需要 macOS 13.0+")
                    .foregroundColor(.secondary)
                    .frame(height: 200)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Achievements Section

struct AchievementsSection: View {
    @ObservedObject var viewModel: StatisticsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("成就")
                    .font(.headline)
                Spacer()
                Text("\(viewModel.unlockedAchievements)/\(viewModel.totalAchievements)")
                    .foregroundColor(.secondary)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(viewModel.achievements) { achievement in
                    AchievementBadge(achievement: achievement)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct AchievementBadge: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 8) {
            Text(achievement.icon)
                .font(.system(size: 32))
                .opacity(achievement.isUnlocked ? 1.0 : 0.3)
            
            Text(achievement.title)
                .font(.caption)
                .lineLimit(1)
                .opacity(achievement.isUnlocked ? 1.0 : 0.5)
            
            if !achievement.isUnlocked {
                ProgressView(value: achievement.progressPercentage)
                    .progressViewStyle(.linear)
                    .scaleEffect(x: 1, y: 0.5)
            }
        }
        .padding(.vertical, 8)
        .background(achievement.isUnlocked ? Color.yellow.opacity(0.1) : Color.clear)
        .cornerRadius(8)
    }
}

// MARK: - Learning Goals Section

struct LearningGoalsSection: View {
    @ObservedObject var viewModel: StatisticsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("学习目标")
                    .font(.headline)
                Spacer()
                Button("添加目标") {
                    viewModel.showAddGoalSheet = true
                }
            }
            
            ForEach(viewModel.goals) { goal in
                GoalRow(goal: goal)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct GoalRow: View {
    let goal: LearningGoal
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(goal.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text(goal.category.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
            }
            
            HStack {
                Text("\(goal.currentValue)/\(goal.targetValue) \(goal.unit)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("还剩 \(goal.remainingDays) 天")
                    .font(.caption)
                    .foregroundColor(goal.remainingDays < 3 ? .red : .secondary)
            }
            
            ProgressView(value: goal.progressPercentage)
                .progressViewStyle(.linear)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - View Model

@MainActor
class StatisticsViewModel: ObservableObject {
    @Published var totalWords = 100
    @Published var masteredWords = 50
    @Published var currentStreak = 5
    @Published var accuracy = 0.85
    
    @Published var weeklyProgress: [DailyProgress] = []
    @Published var wordLevelData: [WordLevelItem] = []
    @Published var studyTimeData: [StudyTimeItem] = []
    @Published var achievements: [Achievement] = []
    @Published var goals: [LearningGoal] = []
    
    @Published var showAddGoalSheet = false
    
    var unlockedAchievements: Int {
        achievements.filter { $0.isUnlocked }.count
    }
    
    var totalAchievements: Int {
        achievements.count
    }
    
    init() {
        loadMockData()
    }
    
    private func loadMockData() {
        // 加载模拟数据
        weeklyProgress = (0..<7).map { day in
            DailyProgress(
                date: Calendar.current.date(byAdding: .day, value: -day, to: Date()) ?? Date(),
                wordsLearned: Int.random(in: 5...20)
            )
        }.reversed()
        
        wordLevelData = [
            WordLevelItem(level: "新词", count: 20, color: .gray),
            WordLevelItem(level: "学习中", count: 30, color: .blue),
            WordLevelItem(level: "复习中", count: 25, color: .orange),
            WordLevelItem(level: "已掌握", count: 50, color: .green)
        ]
        
        studyTimeData = [
            StudyTimeItem(timeSlot: "早晨", minutes: 120),
            StudyTimeItem(timeSlot: "下午", minutes: 90),
            StudyTimeItem(timeSlot: "晚上", minutes: 180),
            StudyTimeItem(timeSlot: "深夜", minutes: 30)
        ]
        
        achievements = [
            Achievement(id: "1", title: "初次学习", description: "", icon: "🌱", requirement: 1, currentProgress: 1, category: .vocabulary, isUnlocked: true, unlockDate: Date()),
            Achievement(id: "2", title: "词汇积累", description: "", icon: "📚", requirement: 100, currentProgress: 50, category: .vocabulary, isUnlocked: false, unlockDate: nil),
            Achievement(id: "3", title: "坚持一周", description: "", icon: "🔥", requirement: 7, currentProgress: 5, category: .streak, isUnlocked: false, unlockDate: nil)
        ]
        
        goals = [
            LearningGoal(id: UUID(), title: "每日学习 20 词", description: "", targetValue: 20, currentValue: 15, unit: "词", deadline: Date().addingTimeInterval(86400), category: .daily, isCompleted: false, createdAt: Date()),
            LearningGoal(id: UUID(), title: "本周掌握 50 词", description: "", targetValue: 50, currentValue: 30, unit: "词", deadline: Date().addingTimeInterval(7 * 86400), category: .weekly, isCompleted: false, createdAt: Date())
        ]
    }
    
    func generateReport() {
        // 生成学习报告
    }
}

// MARK: - Supporting Models

struct DailyProgress: Identifiable {
    let id = UUID()
    let date: Date
    let wordsLearned: Int
}

struct WordLevelItem {
    let level: String
    let count: Int
    let color: Color
    
    var percentage: Double {
        Double(count) / 125.0 // 假设总数125
    }
}

struct StudyTimeItem: Identifiable {
    let id = UUID()
    let timeSlot: String
    let minutes: Int
}
