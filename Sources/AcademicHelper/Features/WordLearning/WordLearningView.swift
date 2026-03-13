import SwiftUI

struct WordLearningView: View {
    @State private var selectedTab: WordLearningTab = .vocabulary
    @State private var showingReviewSheet = false
    
    enum WordLearningTab: String, CaseIterable {
        case vocabulary = "生词本"
        case review = "复习"
        case statistics = "统计"
        
        var icon: String {
            switch self {
            case .vocabulary:
                return "book.fill"
            case .review:
                return "arrow.clockwise"
            case .statistics:
                return "chart.bar.fill"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Picker("", selection: $selectedTab) {
                    ForEach(WordLearningTab.allCases, id: \.self) { tab in
                        Label(tab.rawValue, systemImage: tab.icon)
                            .tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 300)
                
                Spacer()
                
                Button(action: { showingReviewSheet = true }) {
                    Label("开始复习", systemImage: "play.circle.fill")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            Divider()
            
            // Content
            switch selectedTab {
            case .vocabulary:
                VocabularyView()
            case .review:
                ReviewQueueView()
            case .statistics:
                WordStatisticsView()
            }
        }
        .sheet(isPresented: $showingReviewSheet) {
            ReviewView()
        }
    }
}

struct ReviewQueueView: View {
    @StateObject private var viewModel = ReviewQueueViewModel()
    
    var body: some View {
        VStack {
            if viewModel.dueWords.isEmpty {
                EmptyReviewQueueView()
            } else {
                List(viewModel.dueWords) { word in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(word.text)
                                .font(.headline)
                            
                            if let definition = word.definition {
                                Text(definition)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        
                        Spacer()
                        
                        if let nextReview = word.nextReviewAt {
                            Text(timeSince(nextReview))
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .task {
            await viewModel.loadDueWords()
        }
    }
    
    private func timeSince(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct EmptyReviewQueueView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)
            
            Text("没有待复习的单词")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("太棒了！你已经完成了所有的复习任务。")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct WordStatisticsView: View {
    @StateObject private var viewModel = WordStatisticsViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Overview cards
                HStack(spacing: 16) {
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
                        title: "学习中",
                        value: "\(viewModel.learningWords)",
                        icon: "clock.fill",
                        color: .orange
                    )
                }
                .padding(.horizontal)
                
                // Difficulty distribution
                DifficultyChart(distribution: viewModel.difficultyDistribution)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                
                // Weekly progress
                WeeklyProgressChart(data: viewModel.weeklyProgress)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .task {
            await viewModel.loadStatistics()
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct DifficultyChart: View {
    let distribution: [WordDifficulty: Int]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("难度分布")
                .font(.headline)
            
            ForEach(WordDifficulty.allCases, id: \.self) { difficulty in
                let count = distribution[difficulty] ?? 0
                let total = distribution.values.reduce(0, +)
                let percentage = total > 0 ? Double(count) / Double(total) : 0
                
                HStack {
                    Text(difficulty.description)
                        .font(.caption)
                        .frame(width: 60, alignment: .leading)
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .cornerRadius(4)
                            
                            Rectangle()
                                .fill(difficultyColor(difficulty))
                                .frame(width: geometry.size.width * percentage)
                                .cornerRadius(4)
                        }
                    }
                    .frame(height: 8)
                    
                    Text("\(count)")
                        .font(.caption)
                        .frame(width: 30, alignment: .trailing)
                }
            }
        }
    }
    
    private func difficultyColor(_ difficulty: WordDifficulty) -> Color {
        switch difficulty {
        case .easy:
            return .green
        case .medium:
            return .yellow
        case .hard:
            return .orange
        case .veryHard:
            return .red
        }
    }
}

struct WeeklyProgressChart: View {
    let data: [DailyProgress]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("本周学习进度")
                .font(.headline)
            
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(data) { day in
                    VStack(spacing: 4) {
                        Rectangle()
                            .fill(day.count > 0 ? Color.blue : Color.gray.opacity(0.3))
                            .frame(height: CGFloat(day.count) * 5 + 5)
                            .cornerRadius(2)
                        
                        Text(day.dayOfWeek)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 100)
        }
    }
}

struct DailyProgress: Identifiable {
    let id = UUID()
    let dayOfWeek: String
    let count: Int
}

@MainActor
class ReviewQueueViewModel: ObservableObject {
    @Published var dueWords: [Word] = []
    
    @Inject private var srsService: SRSServiceProtocol
    
    func loadDueWords() async {
        do {
            dueWords = try await srsService.getDueWords()
        } catch {
            print("Failed to load due words: \(error)")
        }
    }
}

@MainActor
class WordStatisticsViewModel: ObservableObject {
    @Published var totalWords = 0
    @Published var masteredWords = 0
    @Published var learningWords = 0
    @Published var difficultyDistribution: [WordDifficulty: Int] = [:]
    @Published var weeklyProgress: [DailyProgress] = []
    
    @Inject private var wordRepository: WordRepositoryProtocol
    
    func loadStatistics() async {
        do {
            let words = try await wordRepository.fetchAllWords()
            
            totalWords = words.count
            masteredWords = words.filter { $0.easeFactor >= 2.5 && $0.reviewCount >= 5 }.count
            learningWords = words.filter { $0.reviewCount < 5 }.count
            
            // Calculate difficulty distribution
            for difficulty in WordDifficulty.allCases {
                difficultyDistribution[difficulty] = words.filter { $0.difficulty == difficulty }.count
            }
            
            // Generate sample weekly progress (replace with actual data)
            let days = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"]
            weeklyProgress = days.map { DailyProgress(dayOfWeek: $0, count: Int.random(in: 0...10)) }
            
        } catch {
            print("Failed to load statistics: \(error)")
        }
    }
}
