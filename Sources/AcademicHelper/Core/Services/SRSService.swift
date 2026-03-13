import Foundation

protocol SRSServiceProtocol {
    func calculateNextReview(quality: ReviewQuality, word: Word) -> Word
    func getDueWords() async throws -> [Word]
    func scheduleReview(word: Word, quality: ReviewQuality) async throws
}

@MainActor
final class SRSService: SRSServiceProtocol {
    private let wordRepository: WordRepositoryProtocol
    
    init(wordRepository: WordRepositoryProtocol) {
        self.wordRepository = wordRepository
    }
    
    func calculateNextReview(quality: ReviewQuality, word: Word) -> Word {
        var updatedWord = word
        
        let easeFactor = word.easeFactor
        let interval = word.interval
        let repetitions = word.reviewCount
        
        let newEaseFactor = max(1.3, easeFactor + (0.1 - (5 - quality.rawValue) * (0.08 + (5 - quality.rawValue) * 0.02)))
        
        var newInterval: Int
        var newRepetitions: Int
        
        if quality.rawValue < 3 {
            newRepetitions = 0
            newInterval = 0
        } else {
            newRepetitions = repetitions + 1
            
            if newRepetitions == 1 {
                newInterval = 1
            } else if newRepetitions == 2 {
                newInterval = 6
            } else {
                newInterval = Int(Double(interval) * newEaseFactor)
            }
        }
        
        updatedWord.easeFactor = newEaseFactor
        updatedWord.interval = newInterval
        updatedWord.reviewCount = newRepetitions
        updatedWord.lastReviewedAt = Date()
        
        let calendar = Calendar.current
        if let nextReview = calendar.date(byAdding: .day, value: newInterval, to: Date()) {
            updatedWord.nextReviewAt = nextReview
        }
        
        return updatedWord
    }
    
    func getDueWords() async throws -> [Word] {
        return try await wordRepository.fetchWordsDueForReview()
    }
    
    func scheduleReview(word: Word, quality: ReviewQuality) async throws {
        let updatedWord = calculateNextReview(quality: quality, word: word)
        try await wordRepository.updateWord(updatedWord)
    }
}
