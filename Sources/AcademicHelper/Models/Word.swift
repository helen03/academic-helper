import Foundation

struct Word: Identifiable, Codable, Equatable {
    let id: UUID
    var text: String
    var phonetic: String?
    var definition: String?
    var partOfSpeech: String?
    var examples: [String]
    var difficulty: WordDifficulty
    var source: String?
    let createdAt: Date
    var lastReviewedAt: Date?
    var nextReviewAt: Date?
    var reviewCount: Int
    var interval: Int
    var easeFactor: Double
    var linkedDocumentIDs: [UUID]
    
    init(
        id: UUID = UUID(),
        text: String,
        phonetic: String? = nil,
        definition: String? = nil,
        partOfSpeech: String? = nil,
        examples: [String] = [],
        difficulty: WordDifficulty = .medium,
        source: String? = nil,
        createdAt: Date = Date(),
        lastReviewedAt: Date? = nil,
        nextReviewAt: Date? = nil,
        reviewCount: Int = 0,
        interval: Int = 0,
        easeFactor: Double = 2.5,
        linkedDocumentIDs: [UUID] = []
    ) {
        self.id = id
        self.text = text
        self.phonetic = phonetic
        self.definition = definition
        self.partOfSpeech = partOfSpeech
        self.examples = examples
        self.difficulty = difficulty
        self.source = source
        self.createdAt = createdAt
        self.lastReviewedAt = lastReviewedAt
        self.nextReviewAt = nextReviewAt
        self.reviewCount = reviewCount
        self.interval = interval
        self.easeFactor = easeFactor
        self.linkedDocumentIDs = linkedDocumentIDs
    }
}

enum WordDifficulty: Int16, Codable, CaseIterable {
    case easy = 0
    case medium = 1
    case hard = 2
    case veryHard = 3
    
    var description: String {
        switch self {
        case .easy: return "简单"
        case .medium: return "中等"
        case .hard: return "困难"
        case .veryHard: return "非常困难"
        }
    }
}

struct WordDefinition: Codable {
    let word: String
    let phonetic: String?
    let meanings: [Meaning]
    
    struct Meaning: Codable {
        let partOfSpeech: String
        let definitions: [Definition]
    }
    
    struct Definition: Codable {
        let definition: String
        let example: String?
        let synonyms: [String]
    }
}

enum ReviewQuality: Int {
    case again = 0
    case hard = 1
    case good = 2
    case easy = 3
    
    var description: String {
        switch self {
        case .again: return "重来"
        case .hard: return "困难"
        case .good: return "良好"
        case .easy: return "简单"
        }
    }
}
