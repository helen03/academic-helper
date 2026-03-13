import SwiftUI

struct ReviewView: View {
    @StateObject private var viewModel = ReviewViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // Progress
            ProgressView(value: viewModel.progress)
                .padding(.horizontal)
            
            Text("\(viewModel.currentIndex + 1) / \(viewModel.totalWords)")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            if let word = viewModel.currentWord {
                // Word card
                WordReviewCard(
                    word: word,
                    showAnswer: viewModel.showAnswer,
                    onFlip: { viewModel.flipCard() }
                )
                .padding(.horizontal)
                
                // Rating buttons (only show after flipping)
                if viewModel.showAnswer {
                    RatingButtons { quality in
                        viewModel.rateWord(quality: quality)
                    }
                    .padding(.horizontal)
                    .transition(.move(edge: .bottom))
                }
            } else {
                // Completion view
                ReviewCompletionView(
                    stats: viewModel.sessionStats,
                    onDismiss: { dismiss() }
                )
            }
            
            Spacer()
        }
        .padding(.vertical)
        .frame(minWidth: 500, minHeight: 500)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("结束") {
                    dismiss()
                }
            }
        }
        .task {
            await viewModel.loadWordsForReview()
        }
    }
}

struct WordReviewCard: View {
    let word: Word
    let showAnswer: Bool
    let onFlip: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            if !showAnswer {
                // Front of card - show word
                VStack(spacing: 12) {
                    Text(word.text)
                        .font(.system(size: 36, weight: .bold))
                    
                    if let phonetic = word.phonetic {
                        Text(phonetic)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 200)
                .contentShape(Rectangle())
                .onTapGesture {
                    onFlip()
                }
                
                Text("点击显示释义")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                // Back of card - show definition
                VStack(alignment: .leading, spacing: 12) {
                    Text(word.text)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let phonetic = word.phonetic {
                        Text(phonetic)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Divider()
                    
                    if let definition = word.definition {
                        Text(definition)
                            .font(.body)
                    }
                    
                    if let partOfSpeech = word.partOfSpeech {
                        Text(partOfSpeech)
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                    
                    if !word.examples.isEmpty {
                        Divider()
                        
                        Text("例句:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        ForEach(word.examples.prefix(2), id: \.self) { example in
                            Text("• \(example)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .italic()
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct RatingButtons: View {
    let onRate: (ReviewQuality) -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            Text("记得如何？")
                .font(.headline)
            
            HStack(spacing: 12) {
                RatingButton(
                    quality: .again,
                    color: .red,
                    onTap: { onRate(.again) }
                )
                
                RatingButton(
                    quality: .hard,
                    color: .orange,
                    onTap: { onRate(.hard) }
                )
                
                RatingButton(
                    quality: .good,
                    color: .blue,
                    onTap: { onRate(.good) }
                )
                
                RatingButton(
                    quality: .easy,
                    color: .green,
                    onTap: { onRate(.easy) }
                )
            }
        }
    }
}

struct RatingButton: View {
    let quality: ReviewQuality
    let color: Color
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(quality.description)
                    .font(.headline)
                
                Text(intervalText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
    
    private var intervalText: String {
        switch quality {
        case .again:
            return "< 1m"
        case .hard:
            return "2d"
        case .good:
            return "4d"
        case .easy:
            return "7d"
        }
    }
}

struct ReviewCompletionView: View {
    let stats: ReviewSessionStats
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)
            
            Text("复习完成！")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            HStack(spacing: 30) {
                StatBox(title: "复习单词", value: "\(stats.totalWords)")
                StatBox(title: "正确率", value: "\(stats.accuracyPercentage)%")
                StatBox(title: "用时", value: stats.durationText)
            }
            
            Button(action: onDismiss) {
                Text("完成")
                    .font(.headline)
                    .frame(maxWidth: 200)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
}

struct StatBox: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 80)
    }
}

struct ReviewSessionStats {
    let totalWords: Int
    let correctCount: Int
    let duration: TimeInterval
    
    var accuracyPercentage: Int {
        guard totalWords > 0 else { return 0 }
        return Int(Double(correctCount) / Double(totalWords) * 100)
    }
    
    var durationText: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}

@MainActor
class ReviewViewModel: ObservableObject {
    @Published var words: [Word] = []
    @Published var currentIndex = 0
    @Published var showAnswer = false
    @Published var sessionStartTime = Date()
    
    @Inject private var srsService: SRSServiceProtocol
    @Inject private var wordRepository: WordRepositoryProtocol
    
    var currentWord: Word? {
        guard currentIndex < words.count else { return nil }
        return words[currentIndex]
    }
    
    var totalWords: Int {
        words.count
    }
    
    var progress: Double {
        guard !words.isEmpty else { return 0 }
        return Double(currentIndex) / Double(words.count)
    }
    
    var sessionStats: ReviewSessionStats {
        let duration = Date().timeIntervalSince(sessionStartTime)
        return ReviewSessionStats(
            totalWords: words.count,
            correctCount: currentIndex,
            duration: duration
        )
    }
    
    func loadWordsForReview() async {
        do {
            words = try await srsService.getDueWords()
            sessionStartTime = Date()
        } catch {
            print("Failed to load words for review: \(error)")
        }
    }
    
    func flipCard() {
        showAnswer = true
    }
    
    func rateWord(quality: ReviewQuality) {
        guard let word = currentWord else { return }
        
        Task {
            do {
                try await srsService.scheduleReview(word: word, quality: quality)
                
                await MainActor.run {
                    showAnswer = false
                    currentIndex += 1
                }
            } catch {
                print("Failed to schedule review: \(error)")
            }
        }
    }
}
