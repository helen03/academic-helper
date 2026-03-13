import Foundation

// MARK: - Intelligence Service Protocol

@MainActor
protocol LLMIntelligenceServiceProtocol {
    func understandText(_ text: String, context: String?) async throws -> TextUnderstandingResult
    func generateText(prompt: String, style: WritingStyle, maxLength: Int) async throws -> String
    func answerQuestion(question: String, context: String?) async throws -> QuestionAnswer
    func summarizeText(_ text: String, maxSentences: Int) async throws -> String
    func translateText(_ text: String, from source: Language, to target: Language, style: TranslationStyle) async throws -> String
    func improveWriting(_ text: String, goal: ImprovementGoal) async throws -> WritingImprovement
    func explainConcept(_ concept: String, level: ExplanationLevel) async throws -> ConceptExplanation
    func generateStudyPlan(topic: String, duration: StudyDuration) async throws -> StudyPlan
}

// MARK: - Enums and Models

enum WritingStyle: String, CaseIterable {
    case academic = "学术"
    case casual = " casual"
    case formal = "正式"
    case creative = "创意"
    case technical = "技术"
    case persuasive = "说服"
}

enum TranslationStyle: String, CaseIterable {
    case literal = "直译"
    case natural = "意译"
    case academic = "学术"
}

enum ImprovementGoal: String, CaseIterable {
    case clarity = "清晰度"
    case conciseness = "简洁性"
    case grammar = "语法"
    case style = "风格"
    case vocabulary = "词汇"
    case overall = "整体"
}

enum ExplanationLevel: String, CaseIterable {
    case beginner = "初学者"
    case intermediate = "中级"
    case advanced = "高级"
    case expert = "专家"
}

enum StudyDuration: String, CaseIterable {
    case oneWeek = "1周"
    case twoWeeks = "2周"
    case oneMonth = "1个月"
    case threeMonths = "3个月"
}

struct TextUnderstandingResult {
    let mainTopics: [String]
    let keyEntities: [Entity]
    let sentiment: Sentiment
    let language: Language
    let complexity: ComplexityLevel
    let suggestedActions: [SuggestedAction]
    
    struct Entity {
        let name: String
        let type: EntityType
        let importance: Double
        
        enum EntityType {
            case person, organization, location, concept, term, other
        }
    }
    
    struct Sentiment {
        let polarity: Polarity
        let confidence: Double
        
        enum Polarity: String {
            case positive = "积极"
            case negative = "消极"
            case neutral = "中性"
            case mixed = "混合"
        }
    }
    
    enum ComplexityLevel: String {
        case simple = "简单"
        case moderate = "中等"
        case complex = "复杂"
        case veryComplex = "非常复杂"
    }
    
    struct SuggestedAction {
        let type: ActionType
        let description: String
        let confidence: Double
        
        enum ActionType {
            case summarize, translate, explain, define, cite, analyze
        }
    }
}

struct QuestionAnswer {
    let answer: String
    let confidence: Double
    let sources: [String]
    let relatedQuestions: [String]
    let certainty: CertaintyLevel
    
    enum CertaintyLevel: String {
        case definite = "确定"
        case probable = "很可能"
        case possible = "可能"
        case uncertain = "不确定"
    }
}

struct WritingImprovement {
    let improvedText: String
    let changes: [Change]
    let explanation: String
    let score: Double
    
    struct Change {
        let original: String
        let suggestion: String
        let type: ChangeType
        let reason: String
        
        enum ChangeType {
            case grammar, style, clarity, vocabulary, structure
        }
    }
}

struct ConceptExplanation {
    let concept: String
    let explanation: String
    let examples: [String]
    let analogies: [String]
    let relatedConcepts: [String]
    let difficulty: DifficultyLevel
    let estimatedReadTime: TimeInterval
    
    enum DifficultyLevel: String {
        case basic = "基础"
        case intermediate = "中级"
        case advanced = "高级"
    }
}

struct StudyPlan {
    let topic: String
    let duration: String
    let objectives: [String]
    let schedule: [StudySession]
    let resources: [Resource]
    let milestones: [Milestone]
    
    struct StudySession {
        let day: Int
        let title: String
        let description: String
        let estimatedTime: TimeInterval
        let tasks: [String]
    }
    
    struct Resource {
        let title: String
        let type: ResourceType
        let description: String
        let priority: Priority
        
        enum ResourceType {
            case book, article, video, course, paper, tool
        }
        
        enum Priority: String {
            case required = "必需"
            case recommended = "推荐"
            case optional = "可选"
        }
    }
    
    struct Milestone {
        let day: Int
        let description: String
        let deliverable: String
    }
}

// MARK: - Intelligence Service Implementation

@MainActor
final class LLMIntelligenceService: LLMIntelligenceServiceProtocol {
    
    private let llmService: LLMServiceProtocol
    private var defaultConfig: LLMConfiguration
    
    init(llmService: LLMServiceProtocol = LLMService(), config: LLMConfiguration? = nil) {
        self.llmService = llmService
        self.defaultConfig = config ?? LLMConfiguration(
            provider: .deepSeek,
            apiKey: "",
            temperature: 0.7,
            maxTokens: 2048
        )
    }
    
    func updateConfiguration(_ config: LLMConfiguration) {
        self.defaultConfig = config
    }
    
    // MARK: - Natural Language Understanding
    
    func understandText(_ text: String, context: String? = nil) async throws -> TextUnderstandingResult {
        let systemPrompt = """
        你是一个专业的文本分析助手。请分析以下文本，提取关键信息并以JSON格式返回：
        {
            "mainTopics": ["主题1", "主题2"],
            "keyEntities": [
                {"name": "实体名", "type": "person/organization/location/concept/term", "importance": 0.9}
            ],
            "sentiment": {"polarity": "positive/negative/neutral/mixed", "confidence": 0.8},
            "language": "zh/en",
            "complexity": "simple/moderate/complex/veryComplex",
            "suggestedActions": [
                {"type": "summarize/translate/explain/define/cite/analyze", "description": "建议描述", "confidence": 0.9}
            ]
        }
        """
        
        var messages: [LLMMessage] = [.system(systemPrompt)]
        if let context = context {
            messages.append(.user("上下文：\(context)"))
        }
        messages.append(.user("请分析这段文本：\(text)"))
        
        let request = LLMRequest(messages: messages, config: defaultConfig)
        let response = try await llmService.sendRequest(request)
        
        // 解析JSON响应
        return try parseUnderstandingResult(response.content)
    }
    
    // MARK: - Text Generation
    
    func generateText(prompt: String, style: WritingStyle, maxLength: Int) async throws -> String {
        let systemPrompt = """
        你是一个专业的写作助手。请根据用户的要求生成文本，风格要求：\(style.rawValue)。
        生成的文本应该：
        1. 符合指定的风格
        2. 内容连贯、有逻辑
        3. 语言自然流畅
        4. 长度控制在\(maxLength)字以内
        """
        
        let messages: [LLMMessage] = [
            .system(systemPrompt),
            .user(prompt)
        ]
        
        var config = defaultConfig
        config.maxTokens = min(maxLength * 2, 4096)
        
        let request = LLMRequest(messages: messages, config: config)
        let response = try await llmService.sendRequest(request)
        
        return response.content
    }
    
    // MARK: - Question Answering
    
    func answerQuestion(question: String, context: String? = nil) async throws -> QuestionAnswer {
        let systemPrompt = """
        你是一个知识渊博的学术助手。请回答用户的问题，并以JSON格式返回：
        {
            "answer": "详细答案",
            "confidence": 0.9,
            "sources": ["来源1", "来源2"],
            "relatedQuestions": ["相关问题1", "相关问题2"],
            "certainty": "definite/probable/possible/uncertain"
        }
        如果提供了上下文，请基于上下文回答；如果没有上下文，请基于你的知识回答。
        """
        
        var messages: [LLMMessage] = [.system(systemPrompt)]
        if let context = context {
            messages.append(.user("参考上下文：\(context)"))
        }
        messages.append(.user("问题：\(question)"))
        
        let request = LLMRequest(messages: messages, config: defaultConfig)
        let response = try await llmService.sendRequest(request)
        
        return try parseQuestionAnswer(response.content)
    }
    
    // MARK: - Text Summarization
    
    func summarizeText(_ text: String, maxSentences: Int) async throws -> String {
        let systemPrompt = """
        你是一个专业的文本摘要助手。请将以下文本总结为\(maxSentences)句话以内。
        摘要应该：
        1. 保留原文的核心观点和关键信息
        2. 语言简洁明了
        3. 逻辑连贯
        """
        
        let messages: [LLMMessage] = [
            .system(systemPrompt),
            .user("请总结这段文本：\(text)")
        ]
        
        let request = LLMRequest(messages: messages, config: defaultConfig)
        let response = try await llmService.sendRequest(request)
        
        return response.content
    }
    
    // MARK: - Translation
    
    func translateText(_ text: String, from source: Language, to target: Language, style: TranslationStyle) async throws -> String {
        let systemPrompt = """
        你是一个专业的翻译助手。请将以下文本从\(source.rawValue)翻译成\(target.rawValue)。
        翻译风格：\(style.rawValue)
        - 直译：保持原文结构和用词
        - 意译：注重自然流畅
        - 学术：使用学术规范用语
        """
        
        let messages: [LLMMessage] = [
            .system(systemPrompt),
            .user(text)
        ]
        
        let request = LLMRequest(messages: messages, config: defaultConfig)
        let response = try await llmService.sendRequest(request)
        
        return response.content
    }
    
    // MARK: - Writing Improvement
    
    func improveWriting(_ text: String, goal: ImprovementGoal) async throws -> WritingImprovement {
        let systemPrompt = """
        你是一个专业的写作改进助手。请改进以下文本，重点关注：\(goal.rawValue)
        以JSON格式返回：
        {
            "improvedText": "改进后的文本",
            "changes": [
                {
                    "original": "原文",
                    "suggestion": "建议",
                    "type": "grammar/style/clarity/vocabulary/structure",
                    "reason": "改进原因"
                }
            ],
            "explanation": "整体改进说明",
            "score": 0.85
        }
        """
        
        let messages: [LLMMessage] = [
            .system(systemPrompt),
            .user(text)
        ]
        
        let request = LLMRequest(messages: messages, config: defaultConfig)
        let response = try await llmService.sendRequest(request)
        
        return try parseWritingImprovement(response.content)
    }
    
    // MARK: - Concept Explanation
    
    func explainConcept(_ concept: String, level: ExplanationLevel) async throws -> ConceptExplanation {
        let systemPrompt = """
        你是一个知识渊博的教育助手。请以\(level.rawValue)水平解释以下概念。
        以JSON格式返回：
        {
            "concept": "概念名称",
            "explanation": "详细解释",
            "examples": ["例子1", "例子2"],
            "analogies": ["类比1", "类比2"],
            "relatedConcepts": ["相关概念1", "相关概念2"],
            "difficulty": "basic/intermediate/advanced",
            "estimatedReadTime": 300
        }
        """
        
        let messages: [LLMMessage] = [
            .system(systemPrompt),
            .user("请解释这个概念：\(concept)")
        ]
        
        let request = LLMRequest(messages: messages, config: defaultConfig)
        let response = try await llmService.sendRequest(request)
        
        return try parseConceptExplanation(response.content)
    }
    
    // MARK: - Study Plan Generation
    
    func generateStudyPlan(topic: String, duration: StudyDuration) async throws -> StudyPlan {
        let systemPrompt = """
        你是一个专业的学习规划助手。请为"\(topic)"制定一个\(duration.rawValue)的学习计划。
        以JSON格式返回：
        {
            "topic": "学习主题",
            "duration": "持续时间",
            "objectives": ["目标1", "目标2"],
            "schedule": [
                {
                    "day": 1,
                    "title": "标题",
                    "description": "描述",
                    "estimatedTime": 3600,
                    "tasks": ["任务1", "任务2"]
                }
            ],
            "resources": [
                {
                    "title": "资源名称",
                    "type": "book/article/video/course/paper/tool",
                    "description": "资源描述",
                    "priority": "required/recommended/optional"
                }
            ],
            "milestones": [
                {
                    "day": 7,
                    "description": "里程碑描述",
                    "deliverable": "交付物"
                }
            ]
        }
        """
        
        let messages: [LLMMessage] = [
            .system(systemPrompt),
            .user("请制定学习计划")
        ]
        
        let request = LLMRequest(messages: messages, config: defaultConfig)
        let response = try await llmService.sendRequest(request)
        
        return try parseStudyPlan(response.content, topic: topic, duration: duration)
    }
    
    // MARK: - Private Parsing Methods
    
    private func parseUnderstandingResult(_ jsonString: String) throws -> TextUnderstandingResult {
        // 简化实现，实际应该解析JSON
        return TextUnderstandingResult(
            mainTopics: ["主题1", "主题2"],
            keyEntities: [],
            sentiment: TextUnderstandingResult.Sentiment(polarity: .neutral, confidence: 0.8),
            language: .english,
            complexity: .moderate,
            suggestedActions: []
        )
    }
    
    private func parseQuestionAnswer(_ jsonString: String) throws -> QuestionAnswer {
        return QuestionAnswer(
            answer: jsonString,
            confidence: 0.9,
            sources: [],
            relatedQuestions: [],
            certainty: .probable
        )
    }
    
    private func parseWritingImprovement(_ jsonString: String) throws -> WritingImprovement {
        return WritingImprovement(
            improvedText: jsonString,
            changes: [],
            explanation: "",
            score: 0.8
        )
    }
    
    private func parseConceptExplanation(_ jsonString: String) throws -> ConceptExplanation {
        return ConceptExplanation(
            concept: "",
            explanation: jsonString,
            examples: [],
            analogies: [],
            relatedConcepts: [],
            difficulty: .intermediate,
            estimatedReadTime: 300
        )
    }
    
    private func parseStudyPlan(_ jsonString: String, topic: String, duration: StudyDuration) throws -> StudyPlan {
        return StudyPlan(
            topic: topic,
            duration: duration.rawValue,
            objectives: [],
            schedule: [],
            resources: [],
            milestones: []
        )
    }
}
