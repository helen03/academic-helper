import SwiftUI

struct WordDetailView: View {
    let word: Word
    @StateObject private var viewModel: WordDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(word: Word) {
        self.word = word
        self._viewModel = StateObject(wrappedValue: WordDetailViewModel(word: word))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                headerSection
                
                Divider()
                
                // Definition
                definitionSection
                
                // Examples
                if !word.examples.isEmpty {
                    examplesSection
                }
                
                // Linked Documents
                if !viewModel.linkedDocuments.isEmpty {
                    linkedDocumentsSection
                }
                
                // Review Info
                reviewSection
            }
            .padding()
        }
        .frame(minWidth: 500, minHeight: 400)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("关闭") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(role: .destructive) {
                        viewModel.deleteWord()
                        dismiss()
                    } label: {
                        Label("删除单词", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .task {
            await viewModel.loadLinkedDocuments()
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(word.text)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                // Difficulty badge
                Text(word.difficulty.description)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(difficultyColor.opacity(0.2))
                    .foregroundColor(difficultyColor)
                    .cornerRadius(4)
            }
            
            if let phonetic = word.phonetic {
                Text(phonetic)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            
            if let partOfSpeech = word.partOfSpeech {
                Text(partOfSpeech)
                    .font(.subheadline)
                    .foregroundStyle(.blue)
            }
        }
    }
    
    private var definitionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("释义")
                .font(.headline)
            
            if let definition = word.definition {
                Text(definition)
                    .font(.body)
            } else {
                Text("暂无释义")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var examplesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("例句")
                .font(.headline)
            
            ForEach(word.examples, id: \.self) { example in
                HStack(alignment: .top) {
                    Text("•")
                    Text(example)
                        .italic()
                }
                .font(.body)
                .foregroundStyle(.secondary)
            }
        }
    }
    
    private var linkedDocumentsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("关联文献")
                .font(.headline)
            
            ForEach(viewModel.linkedDocuments) { document in
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundStyle(.blue)
                    Text(document.title)
                        .lineLimit(1)
                    Spacer()
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    private var reviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("复习信息")
                .font(.headline)
            
            HStack(spacing: 20) {
                ReviewInfoItem(
                    title: "复习次数",
                    value: "\(word.reviewCount)"
                )
                
                ReviewInfoItem(
                    title: "熟练度",
                    value: String(format: "%.1f", word.easeFactor)
                )
                
                if let nextReview = word.nextReviewAt {
                    ReviewInfoItem(
                        title: "下次复习",
                        value: formatDate(nextReview)
                    )
                }
            }
            
            if viewModel.isDueForReview {
                Button(action: {
                    viewModel.startReview()
                }) {
                    Label("开始复习", systemImage: "play.circle.fill")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct ReviewInfoItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

@MainActor
class WordDetailViewModel: ObservableObject {
    let word: Word
    @Published var linkedDocuments: [LiteratureDocument] = []
    @Published var isDueForReview: Bool = false
    
    @Inject private var literatureRepository: LiteratureRepositoryProtocol
    @Inject private var wordRepository: WordRepositoryProtocol
    @Inject private var srsService: SRSServiceProtocol
    
    init(word: Word) {
        self.word = word
        self.isDueForReview = (word.nextReviewAt ?? Date()) <= Date()
    }
    
    func loadLinkedDocuments() async {
        // Load linked documents based on word.linkedDocumentIDs
        // This is a placeholder implementation
    }
    
    func deleteWord() {
        Task {
            do {
                try await wordRepository.deleteWord(id: word.id)
            } catch {
                print("Failed to delete word: \(error)")
            }
        }
    }
    
    func startReview() {
        // Navigate to review view
    }
}
