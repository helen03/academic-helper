import XCTest
@testable import AcademicHelper

@MainActor
final class ExpressionRecognitionTests: XCTestCase {
    
    var expressionService: ExpressionRecognitionService!
    
    override func setUp() {
        super.setUp()
        expressionService = ExpressionRecognitionService()
    }
    
    override func tearDown() {
        expressionService = nil
        super.tearDown()
    }
    
    // MARK: - Expression Recognition Tests
    
    func testRecognizeExpression_TransitionExpressions() async throws {
        // Given
        let text = "In order to understand the problem, we need to analyze the data. Moreover, we should consider alternative approaches."
        
        // When
        let expressions = try await expressionService.recognizeExpression(in: text)
        
        // Then
        let transitionExpressions = expressions.filter { $0.expression.category == .transition }
        XCTAssertGreaterThanOrEqual(transitionExpressions.count, 2)
        XCTAssertTrue(expressions.contains { $0.expression.text.lowercased().contains("in order to") })
        XCTAssertTrue(expressions.contains { $0.expression.text.lowercased().contains("moreover") })
    }
    
    func testRecognizeExpression_CauseEffectExpressions() async throws {
        // Given
        let text = "As a result of the experiment, we observed significant changes. Therefore, we can conclude that the hypothesis is correct."
        
        // When
        let expressions = try await expressionService.recognizeExpression(in: text)
        
        // Then
        let causeEffectExpressions = expressions.filter { $0.expression.category == .causeEffect }
        XCTAssertGreaterThanOrEqual(causeEffectExpressions.count, 2)
    }
    
    func testRecognizeExpression_ConclusionExpressions() async throws {
        // Given
        let text = "In conclusion, our findings suggest that the proposed method is effective. To summarize, we have demonstrated the feasibility of this approach."
        
        // When
        let expressions = try await expressionService.recognizeExpression(in: text)
        
        // Then
        let conclusionExpressions = expressions.filter { $0.expression.category == .conclusion }
        XCTAssertGreaterThanOrEqual(conclusionExpressions.count, 1)
    }
    
    func testRecognizeExpression_ResultExpressions() async throws {
        // Given
        let text = "This study demonstrates the effectiveness of the proposed algorithm. The results indicate a significant improvement over existing methods."
        
        // When
        let expressions = try await expressionService.recognizeExpression(in: text)
        
        // Then
        let resultExpressions = expressions.filter { $0.expression.category == .result }
        XCTAssertGreaterThanOrEqual(resultExpressions.count, 2)
    }
    
    func testRecognizeExpression_ContextExtraction() async throws {
        // Given
        let text = "Previous research has shown that machine learning techniques can be applied to this problem. However, there are still challenges to overcome."
        
        // When
        let expressions = try await expressionService.recognizeExpression(in: text)
        
        // Then
        XCTAssertFalse(expressions.isEmpty)
        for expression in expressions {
            XCTAssertFalse(expression.context.isEmpty)
            XCTAssertGreaterThan(expression.context.count, 10)
        }
    }
    
    func testRecognizeExpression_ConfidenceScore() async throws {
        // Given
        let text = "In conclusion, our findings suggest that the proposed method is effective."
        
        // When
        let expressions = try await expressionService.recognizeExpression(in: text)
        
        // Then
        for expression in expressions {
            XCTAssertGreaterThanOrEqual(expression.confidence, 0.0)
            XCTAssertLessThanOrEqual(expression.confidence, 1.0)
        }
    }
    
    func testRecognizeExpression_EmptyText() async throws {
        // Given
        let text = ""
        
        // When
        let expressions = try await expressionService.recognizeExpression(in: text)
        
        // Then
        XCTAssertTrue(expressions.isEmpty)
    }
    
    func testRecognizeExpression_NoAcademicExpressions() async throws {
        // Given
        let text = "Hello world. This is a simple test. Nothing special here."
        
        // When
        let expressions = try await expressionService.recognizeExpression(in: text)
        
        // Then
        XCTAssertTrue(expressions.isEmpty)
    }
    
    // MARK: - Classification Tests
    
    func testClassifyExpression_Conclusion() async throws {
        // Given
        let text = "In conclusion"
        
        // When
        let category = try await expressionService.classifyExpression(text)
        
        // Then
        XCTAssertEqual(category, .conclusion)
    }
    
    func testClassifyExpression_Result() async throws {
        // Given
        let text = "The results demonstrate"
        
        // When
        let category = try await expressionService.classifyExpression(text)
        
        // Then
        XCTAssertEqual(category, .result)
    }
    
    func testClassifyExpression_Methodology() async throws {
        // Given
        let text = "We conducted experiments"
        
        // When
        let category = try await expressionService.classifyExpression(text)
        
        // Then
        XCTAssertEqual(category, .methodology)
    }
    
    func testClassifyExpression_Other() async throws {
        // Given
        let text = "Random text without academic meaning"
        
        // When
        let category = try await expressionService.classifyExpression(text)
        
        // Then
        XCTAssertEqual(category, .other)
    }
    
    // MARK: - Context Extraction Tests
    
    func testExtractContext() {
        // Given
        let text = "This is a long text with many words and the target expression is here in the middle of everything."
        let range = text.range(of: "target expression")!
        
        // When
        let context = expressionService.extractContext(from: text, around: range)
        
        // Then
        XCTAssertTrue(context.contains("target expression"))
        XCTAssertTrue(context.hasPrefix("...") || text.distance(from: text.startIndex, to: range.lowerBound) < 50)
        XCTAssertTrue(context.hasSuffix("...") || text.distance(from: range.upperBound, to: text.endIndex) < 50)
    }
}
