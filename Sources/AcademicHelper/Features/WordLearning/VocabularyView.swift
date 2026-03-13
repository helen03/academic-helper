import SwiftUI

struct VocabularyView: View {
    @StateObject private var viewModel = VocabularyViewModel()
    @State private var selectedWord: Word?
    @State private var showingAddWordSheet = false
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            SearchBar(text: $searchText)
                .padding()
            
            // Stats
            statsSection
                .padding(.horizontal)
            
            // Filter tabs
            Picker("筛选", selection: $viewModel.filter) {
                ForEach(VocabularyFilter.allCases) { filter in
                    Text(filter.description)
                        .tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            // Word list
            List(selection: $selectedWord) {
                ForEach(viewModel.filteredWords) { word in
                    WordRow(word: word)
                        .tag(word)
                        .contextMenu {
                            Button {
                                viewModel.deleteWord(word)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                }
            }
            .listStyle(.plain)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddWordSheet = true }) {
                    Image(systemName: "plus")
                }
            }
            
            ToolbarItem(placement: .status) {
                Text("共 \(viewModel.words.count) 个单词")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .sheet(item: $selectedWord) { word in
            WordDetailView(word: word)
        }
        .sheet(isPresented: $showingAddWordSheet) {
            AddWordView { word in
                viewModel.addWord(word)
            }
        }
        .task {
            await viewModel.loadWords()
        }
        .onChange(of: searchText) { _, newValue in
            viewModel.search(query: newValue)
        }
    }
    
    private var statsSection: some View {
        HStack(spacing: 20) {
            StatItem(
                title: "待复习",
                value: viewModel.dueForReviewCount,
                color: .orange
            )
            
            StatItem(
                title: "今日已学",
                value: viewModel.todayLearnedCount,
                color: .green
            )
            
            StatItem(
                title: "掌握度",
                value: viewModel.masteryPercentage,
                color: .blue
            )
        }
    }
}

struct WordRow: View {
    let word: Word
    
    var body: some View {
        HStack(spacing: 12) {
            // Difficulty indicator
            Circle()
                .fill(difficultyColor)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(word.text)
                        .font(.headline)
                    
                    if let phonetic = word.phonetic {
                        Text(phonetic)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    if isDueForReview {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.orange)
                            .font(.caption)
                    }
                }
                
                if let definition = word.definition {
                    Text(definition)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Review status
            if word.reviewCount > 0 {
                Text("\(word.reviewCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var difficultyColor: Color {
        switch word.difficulty {
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
    
    private var isDueForReview: Bool {
        (word.nextReviewAt ?? Date()) <= Date()
    }
}

struct StatItem: View {
    let title: String
    let value: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            
            TextField("搜索单词...", text: $text)
                .textFieldStyle(.plain)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct AddWordView: View {
    let onAdd: (Word) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var text = ""
    @State private var definition = ""
    @State private var selectedDifficulty: WordDifficulty = .medium
    
    var body: some View {
        NavigationStack {
            Form {
                Section("单词") {
                    TextField("输入单词", text: $text)
                }
                
                Section("释义") {
                    TextEditor(text: $definition)
                        .frame(minHeight: 60)
                }
                
                Section("难度") {
                    Picker("难度", selection: $selectedDifficulty) {
                        ForEach(WordDifficulty.allCases, id: \.self) { difficulty in
                            Text(difficulty.description)
                                .tag(difficulty)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("添加单词")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
                        let word = Word(
                            text: text,
                            definition: definition,
                            difficulty: selectedDifficulty
                        )
                        onAdd(word)
                        dismiss()
                    }
                    .disabled(text.isEmpty)
                }
            }
        }
        .frame(minWidth: 400, minHeight: 300)
    }
}

enum VocabularyFilter: CaseIterable, Identifiable {
    case all
    case dueForReview
    case recentlyAdded
    case mastered
    
    var id: Self { self }
    
    var description: String {
        switch self {
        case .all:
            return "全部"
        case .dueForReview:
            return "待复习"
        case .recentlyAdded:
            return "最近添加"
        case .mastered:
            return "已掌握"
        }
    }
}

@MainActor
class VocabularyViewModel: ObservableObject {
    @Published var words: [Word] = []
    @Published var filter: VocabularyFilter = .all
    @Published var dueForReviewCount = 0
    @Published var todayLearnedCount = 0
    @Published var masteryPercentage = 0
    
    @Inject private var wordRepository: WordRepositoryProtocol
    @Inject private var srsService: SRSServiceProtocol
    
    var filteredWords: [Word] {
        switch filter {
        case .all:
            return words
        case .dueForReview:
            return words.filter { ($0.nextReviewAt ?? Date()) <= Date() }
        case .recentlyAdded:
            let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
            return words.filter { $0.createdAt >= weekAgo }
        case .mastered:
            return words.filter { $0.easeFactor >= 2.5 && $0.reviewCount >= 5 }
        }
    }
    
    func loadWords() async {
        do {
            words = try await wordRepository.fetchAllWords()
            updateStats()
        } catch {
            print("Failed to load words: \(error)")
        }
    }
    
    func addWord(_ word: Word) {
        Task {
            do {
                try await wordRepository.saveWord(word)
                await loadWords()
            } catch {
                print("Failed to add word: \(error)")
            }
        }
    }
    
    func deleteWord(_ word: Word) {
        Task {
            do {
                try await wordRepository.deleteWord(id: word.id)
                await loadWords()
            } catch {
                print("Failed to delete word: \(error)")
            }
        }
    }
    
    func search(query: String) {
        // Implement search logic
    }
    
    private func updateStats() {
        dueForReviewCount = words.filter { ($0.nextReviewAt ?? Date()) <= Date() }.count
        
        let calendar = Calendar.current
        todayLearnedCount = words.filter {
            calendar.isDate($0.createdAt, inSameDayAs: Date())
        }.count
        
        let masteredCount = words.filter { $0.easeFactor >= 2.5 && $0.reviewCount >= 5 }.count
        masteryPercentage = words.isEmpty ? 0 : Int(Double(masteredCount) / Double(words.count) * 100)
    }
}
