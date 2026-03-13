import Foundation
import NaturalLanguage

@MainActor
protocol ExpressionRecognitionServiceProtocol {
    func recognizeExpression(in text: String) async throws -> [RecognizedExpression]
    func classifyExpression(_ text: String) async throws -> ExpressionCategory
    func extractContext(from text: String, around range: Range<String.Index>) -> String
}

@MainActor
final class ExpressionRecognitionService: ExpressionRecognitionServiceProtocol {
    
    private let patterns: [ExpressionPattern] = [
        ExpressionPattern(pattern: "(?i)in order to", category: .transition, confidence: 0.9),
        ExpressionPattern(pattern: "(?i)as a result", category: .causeEffect, confidence: 0.9),
        ExpressionPattern(pattern: "(?i)on the other hand", category: .comparison, confidence: 0.9),
        ExpressionPattern(pattern: "(?i)in conclusion", category: .conclusion, confidence: 0.95),
        ExpressionPattern(pattern: "(?i)it is worth noting", category: .emphasis, confidence: 0.85),
        ExpressionPattern(pattern: "(?i)this study demonstrates", category: .result, confidence: 0.9),
        ExpressionPattern(pattern: "(?i)we propose", category: .methodology, confidence: 0.85),
        ExpressionPattern(pattern: "(?i)previous research", category: .introduction, confidence: 0.85),
        ExpressionPattern(pattern: "(?i)our findings suggest", category: .discussion, confidence: 0.9),
        ExpressionPattern(pattern: "(?i)moreover|furthermore|additionally", category: .transition, confidence: 0.85),
        ExpressionPattern(pattern: "(?i)however|nevertheless|although", category: .comparison, confidence: 0.85),
        ExpressionPattern(pattern: "(?i)therefore|thus|consequently", category: .causeEffect, confidence: 0.85),
        ExpressionPattern(pattern: "(?i)in summary|to summarize", category: .conclusion, confidence: 0.9),
        ExpressionPattern(pattern: "(?i)significantly|notably|importantly", category: .emphasis, confidence: 0.8),
        ExpressionPattern(pattern: "(?i)the results indicate", category: .result, confidence: 0.9),
        ExpressionPattern(pattern: "(?i)we conducted|we performed", category: .methodology, confidence: 0.85),
        ExpressionPattern(pattern: "(?i)recent studies|recent research", category: .introduction, confidence: 0.85),
        ExpressionPattern(pattern: "(?i)these results suggest|our analysis shows", category: .discussion, confidence: 0.85)
    ]
    
    func recognizeExpression(in text: String) async throws -> [RecognizedExpression] {
        var recognizedExpressions: [RecognizedExpression] = []
        
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern.pattern, options: []) else {
                continue
            }
            
            let range = NSRange(text.startIndex..., in: text)
            let matches = regex.matches(in: text, options: [], range: range)
            
            for match in matches {
                guard let matchRange = Range(match.range, in: text) else { continue }
                
                let expressionText = String(text[matchRange])
                let context = extractContext(from: text, around: matchRange)
                
                let expression = AcademicExpression(
                    text: expressionText,
                    category: pattern.category
                )
                
                let recognized = RecognizedExpression(
                    expression: expression,
                    confidence: pattern.confidence,
                    context: context
                )
                
                recognizedExpressions.append(recognized)
            }
        }
        
        return recognizedExpressions.sorted { $0.confidence > $1.confidence }
    }
    
    func classifyExpression(_ text: String) async throws -> ExpressionCategory {
        let lowerText = text.lowercased()
        
        if lowerText.contains("conclusion") || lowerText.contains("summary") || lowerText.contains("conclude") {
            return .conclusion
        } else if lowerText.contains("result") || lowerText.contains("finding") || lowerText.contains("demonstrate") {
            return .result
        } else if lowerText.contains("method") || lowerText.contains("conduct") || lowerText.contains("perform") {
            return .methodology
        } else if lowerText.contains("discuss") || lowerText.contains("suggest") || lowerText.contains("imply") {
            return .discussion
        } else if lowerText.contains("however") || lowerText.contains("although") || lowerText.contains("compare") {
            return .comparison
        } else if lowerText.contains("therefore") || lowerText.contains("thus") || lowerText.contains("because") {
            return .causeEffect
        } else if lowerText.contains("moreover") || lowerText.contains("furthermore") || lowerText.contains("additionally") {
            return .transition
        } else if lowerText.contains("important") || lowerText.contains("significant") || lowerText.contains("notable") {
            return .emphasis
        } else if lowerText.contains("introduce") || lowerText.contains("background") || lowerText.contains("previous") {
            return .introduction
        }
        
        return .other
    }
    
    func extractContext(from text: String, around range: Range<String.Index>) -> String {
        let contextLength = 50
        
        let startIndex = text.index(
            range.lowerBound,
            offsetBy: -contextLength,
            limitedBy: text.startIndex
        ) ?? text.startIndex
        
        let endIndex = text.index(
            range.upperBound,
            offsetBy: contextLength,
            limitedBy: text.endIndex
        ) ?? text.endIndex
        
        var context = String(text[startIndex..<endIndex])
        
        if startIndex > text.startIndex {
            context = "..." + context
        }
        if endIndex < text.endIndex {
            context = context + "..."
        }
        
        return context.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
