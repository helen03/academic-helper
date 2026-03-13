import Foundation

struct AcademicExpression: Identifiable, Codable, Equatable {
    let id: UUID
    var text: String
    var category: ExpressionCategory
    var meaning: String?
    var usage: String?
    var examples: [String]
    var alternatives: [String]
    var sourceDocument: String?
    let createdAt: Date
    var usageCount: Int
    var isFavorite: Bool
    
    init(
        id: UUID = UUID(),
        text: String,
        category: ExpressionCategory,
        meaning: String? = nil,
        usage: String? = nil,
        examples: [String] = [],
        alternatives: [String] = [],
        sourceDocument: String? = nil,
        createdAt: Date = Date(),
        usageCount: Int = 0,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.text = text
        self.category = category
        self.meaning = meaning
        self.usage = usage
        self.examples = examples
        self.alternatives = alternatives
        self.sourceDocument = sourceDocument
        self.createdAt = createdAt
        self.usageCount = usageCount
        self.isFavorite = isFavorite
    }
}

enum ExpressionCategory: String, Codable, CaseIterable {
    case transition = "过渡连接"
    case emphasis = "强调说明"
    case comparison = "比较对比"
    case causeEffect = "因果关系"
    case conclusion = "总结结论"
    case methodology = "研究方法"
    case result = "结果陈述"
    case discussion = "讨论分析"
    case introduction = "引言背景"
    case other = "其他"
    
    var icon: String {
        switch self {
        case .transition: return "arrow.forward"
        case .emphasis: return "exclamationmark.circle"
        case .comparison: return "arrow.left.arrow.right"
        case .causeEffect: return "arrow.turn.right.down"
        case .conclusion: return "checkmark.circle"
        case .methodology: return "wrench"
        case .result: return "chart.bar"
        case .discussion: return "bubble.left"
        case .introduction: return "book.open"
        case .other: return "ellipsis.circle"
        }
    }
    
    var description: String {
        rawValue
    }
}

struct ExpressionPattern: Codable {
    let pattern: String
    let category: ExpressionCategory
    let confidence: Double
}

struct RecognizedExpression {
    let expression: AcademicExpression
    let confidence: Double
    let context: String
}
