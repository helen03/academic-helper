import XCTest
@testable import AcademicHelper

@MainActor
final class SRSServiceTests: XCTestCase {
    
    var srsService: SRSService!
    var mockWordRepository: MockWordRepository!
    
    override func setUp() {
        super.setUp()
        mockWordRepository = MockWordRepository()
        srsService = SRSService(wordRepository: mockWordRepository)
    }
    
    override func tearDown() {
        srsService = nil
        mockWordRepository = nil
        super.tearDown()
    }
    
    // MARK: - SM-2 Algorithm Tests
    
    func testCalculateNextReview_FirstReviewAgain() {
        // Given
        let word = Word(text: "test", reviewCount: 0, interval: 0, easeFactor: 2.5)
        
        // When
        let updatedWord = srsService.calculateNextReview(quality: .again, word: word)
        
        // Then
        XCTAssertEqual(updatedWord.reviewCount, 0)
        XCTAssertEqual(updatedWord.interval, 0)
        XCTAssertLessThan(updatedWord.easeFactor, 2.5)
    }
    
    func testCalculateNextReview_FirstReviewGood() {
        // Given
        let word = Word(text: "test", reviewCount: 0, interval: 0, easeFactor: 2.5)
        
        // When
        let updatedWord = srsService.calculateNextReview(quality: .good, word: word)
        
        // Then
        XCTAssertEqual(updatedWord.reviewCount, 1)
        XCTAssertEqual(updatedWord.interval, 1)
        XCTAssertGreaterThanOrEqual(updatedWord.easeFactor, 2.5)
    }
    
    func testCalculateNextReview_SecondReviewGood() {
        // Given
        let word = Word(text: "test", reviewCount: 1, interval: 1, easeFactor: 2.5)
        
        // When
        let updatedWord = srsService.calculateNextReview(quality: .good, word: word)
        
        // Then
        XCTAssertEqual(updatedWord.reviewCount, 2)
        XCTAssertEqual(updatedWord.interval, 6)
    }
    
    func testCalculateNextReview_ThirdReviewGood() {
        // Given
        let word = Word(text: "test", reviewCount: 2, interval: 6, easeFactor: 2.5)
        
        // When
        let updatedWord = srsService.calculateNextReview(quality: .good, word: word)
        
        // Then
        XCTAssertEqual(updatedWord.reviewCount, 3)
        XCTAssertEqual(updatedWord.interval, Int(6 * 2.5))
    }
    
    func testCalculateNextReview_EasyIncreasesEaseFactor() {
        // Given
        let word = Word(text: "test", reviewCount: 5, interval: 10, easeFactor: 2.5)
        
        // When
        let updatedWord = srsService.calculateNextReview(quality: .easy, word: word)
        
        // Then
        XCTAssertGreaterThan(updatedWord.easeFactor, 2.5)
    }
    
    func testCalculateNextReview_AgainDecreasesEaseFactor() {
        // Given
        let word = Word(text: "test", reviewCount: 5, interval: 10, easeFactor: 2.5)
        
        // When
        let updatedWord = srsService.calculateNextReview(quality: .again, word: word)
        
        // Then
        XCTAssertLessThan(updatedWord.easeFactor, 2.5)
        XCTAssertGreaterThanOrEqual(updatedWord.easeFactor, 1.3)
    }
    
    func testCalculateNextReview_NextReviewDateIsSet() {
        // Given
        let word = Word(text: "test", reviewCount: 1, interval: 1, easeFactor: 2.5)
        let beforeCalculation = Date()
        
        // When
        let updatedWord = srsService.calculateNextReview(quality: .good, word: word)
        
        // Then
        XCTAssertNotNil(updatedWord.nextReviewAt)
        XCTAssertNotNil(updatedWord.lastReviewedAt)
        XCTAssertGreaterThanOrEqual(updatedWord.lastReviewedAt!, beforeCalculation)
    }
}

// MARK: - Mock Repository

@MainActor
class MockWordRepository: WordRepositoryProtocol {
    var words: [Word] = []
    
    func fetchAllWords() async throws -> [Word] {
        return words
    }
    
    func fetchWordsDueForReview() async throws -> [Word] {
        let now = Date()
        return words.filter { word in
            guard let nextReview = word.nextReviewAt else { return true }
            return nextReview <= now
        }
    }
    
    func fetchWord(byID id: UUID) async throws -> Word? {
        return words.first { $0.id == id }
    }
    
    func fetchWord(byText text: String) async throws -> Word? {
        return words.first { $0.text.lowercased() == text.lowercased() }
    }
    
    func saveWord(_ word: Word) async throws {
        words.append(word)
    }
    
    func updateWord(_ word: Word) async throws {
        if let index = words.firstIndex(where: { $0.id == word.id }) {
            words[index] = word
        }
    }
    
    func deleteWord(id: UUID) async throws {
        words.removeAll { $0.id == id }
    }
    
    func searchWords(query: String) async throws -> [Word] {
        return words.filter {
            $0.text.localizedCaseInsensitiveContains(query) ||
            ($0.definition?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }
    
    func linkWordToDocument(wordID: UUID, documentID: UUID) async throws {
        // Mock implementation
    }
}
