import Foundation

// MARK: - Terminology Models

struct Term: Codable, Identifiable, Equatable {
    let id: UUID
    var text: String
    var definition: String
    var category: TermCategory
    var subcategory: String?
    var difficulty: DifficultyLevel
    var relatedTerms: [UUID]
    var examples: [String]
    var sources: [String]
    var isFavorite: Bool
    var addedAt: Date
    var lastAccessedAt: Date?
    var accessCount: Int
    
    init(
        id: UUID = UUID(),
        text: String,
        definition: String,
        category: TermCategory,
        subcategory: String? = nil,
        difficulty: DifficultyLevel = .intermediate,
        relatedTerms: [UUID] = [],
        examples: [String] = [],
        sources: [String] = [],
        isFavorite: Bool = false
    ) {
        self.id = id
        self.text = text
        self.definition = definition
        self.category = category
        self.subcategory = subcategory
        self.difficulty = difficulty
        self.relatedTerms = relatedTerms
        self.examples = examples
        self.sources = sources
        self.isFavorite = isFavorite
        self.addedAt = Date()
        self.lastAccessedAt = nil
        self.accessCount = 0
    }
}

enum TermCategory: String, Codable, CaseIterable, Identifiable {
    case algorithms = "算法"
    case dataStructures = "数据结构"
    case machineLearning = "机器学习"
    case deepLearning = "深度学习"
    case computerVision = "计算机视觉"
    case nlp = "自然语言处理"
    case robotics = "机器人学"
    case computerGraphics = "计算机图形学"
    case operatingSystems = "操作系统"
    case networks = "计算机网络"
    case databases = "数据库"
    case softwareEngineering = "软件工程"
    case programmingLanguages = "编程语言"
    case computerArchitecture = "计算机体系结构"
    case distributedSystems = "分布式系统"
    case security = "信息安全"
    case theory = "计算理论"
    case other = "其他"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .algorithms: return "📊"
        case .dataStructures: return "🗄️"
        case .machineLearning: return "🤖"
        case .deepLearning: return "🧠"
        case .computerVision: return "👁️"
        case .nlp: return "💬"
        case .robotics: return "🦾"
        case .computerGraphics: return "🎨"
        case .operatingSystems: return "⚙️"
        case .networks: return "🌐"
        case .databases: return "🗃️"
        case .softwareEngineering: return "🛠️"
        case .programmingLanguages: return "💻"
        case .computerArchitecture: return "🔧"
        case .distributedSystems: return "🌩️"
        case .security: return "🔒"
        case .theory: return "📐"
        case .other: return "📦"
        }
    }
}

enum DifficultyLevel: String, Codable, CaseIterable {
    case beginner = "初级"
    case intermediate = "中级"
    case advanced = "高级"
    case expert = "专家"
}

struct TermCollection: Codable, Identifiable {
    let id: UUID
    var name: String
    var description: String
    var category: TermCategory
    var termIds: [UUID]
    var isSystem: Bool
    var createdAt: Date
    var updatedAt: Date
}

struct TermSearchResult {
    let term: Term
    let relevanceScore: Double
    let matchedFields: [MatchedField]
    
    enum MatchedField {
        case text, definition, category, examples
    }
}

// MARK: - Terminology Service Protocol

@MainActor
protocol TerminologyServiceProtocol {
    func getAllTerms() async -> [Term]
    func getTerms(for category: TermCategory) async -> [Term]
    func getTerm(byId id: UUID) async -> Term?
    func searchTerms(query: String, in categories: [TermCategory]?) async -> [TermSearchResult]
    func addTerm(_ term: Term) async throws
    func updateTerm(_ term: Term) async throws
    func deleteTerm(id: UUID) async throws
    func getRelatedTerms(for termId: UUID) async -> [Term]
    func getCollections() async -> [TermCollection]
    func getTerms(in collection: TermCollection) async -> [Term]
    func addToFavorites(termId: UUID) async
    func removeFromFavorites(termId: UUID) async
    func getFavoriteTerms() async -> [Term]
    func getRecentlyAccessedTerms(limit: Int) async -> [Term]
    func getRecommendedTerms() async -> [Term]
    func importTerms(from url: URL, format: ImportFormat) async throws -> ImportResult
    func exportTerms(to url: URL, format: ExportFormat) async throws
    func getStatistics() async -> TerminologyStatistics
}

struct TerminologyStatistics {
    let totalTerms: Int
    let termsByCategory: [TermCategory: Int]
    let termsByDifficulty: [DifficultyLevel: Int]
    let favoriteCount: Int
    let recentlyAddedCount: Int
    let mostAccessedTerms: [Term]
}

enum ImportFormat {
    case json
    case csv
    case markdown
}

enum ExportFormat {
    case json
    case csv
    case markdown
    case anki
}

struct ImportResult {
    let successCount: Int
    let failureCount: Int
    let errors: [String]
}

// MARK: - Terminology Service Implementation

@MainActor
final class TerminologyService: TerminologyServiceProtocol {
    
    private var terms: [UUID: Term] = [:]
    private var collections: [UUID: TermCollection] = [:]
    private let llmService: LLMIntelligenceServiceProtocol?
    
    init(llmService: LLMIntelligenceServiceProtocol? = nil) {
        self.llmService = llmService
        loadDefaultTerms()
    }
    
    // MARK: - CRUD Operations
    
    func getAllTerms() async -> [Term] {
        return Array(terms.values).sorted { $0.text < $1.text }
    }
    
    func getTerms(for category: TermCategory) async -> [Term] {
        return terms.values.filter { $0.category == category }.sorted { $0.text < $1.text }
    }
    
    func getTerm(byId id: UUID) async -> Term? {
        guard var term = terms[id] else { return nil }
        
        // 更新访问统计
        term.accessCount += 1
        term.lastAccessedAt = Date()
        terms[id] = term
        
        return term
    }
    
    func searchTerms(query: String, in categories: [TermCategory]?) async -> [TermSearchResult] {
        let searchText = query.lowercased()
        var results: [TermSearchResult] = []
        
        for term in terms.values {
            // 如果指定了分类，过滤
            if let categories = categories, !categories.contains(term.category) {
                continue
            }
            
            var score: Double = 0
            var matchedFields: [TermSearchResult.MatchedField] = []
            
            // 文本匹配
            if term.text.lowercased().contains(searchText) {
                score += 1.0
                matchedFields.append(.text)
            }
            
            // 定义匹配
            if term.definition.lowercased().contains(searchText) {
                score += 0.8
                matchedFields.append(.definition)
            }
            
            // 分类匹配
            if term.category.rawValue.lowercased().contains(searchText) {
                score += 0.5
                matchedFields.append(.category)
            }
            
            // 示例匹配
            if term.examples.contains(where: { $0.lowercased().contains(searchText) }) {
                score += 0.3
                matchedFields.append(.examples)
            }
            
            if score > 0 {
                results.append(TermSearchResult(term: term, relevanceScore: score, matchedFields: matchedFields))
            }
        }
        
        // 按相关性排序
        return results.sorted { $0.relevanceScore > $1.relevanceScore }
    }
    
    func addTerm(_ term: Term) async throws {
        terms[term.id] = term
        try await saveTerms()
    }
    
    func updateTerm(_ term: Term) async throws {
        terms[term.id] = term
        try await saveTerms()
    }
    
    func deleteTerm(id: UUID) async throws {
        terms.removeValue(forKey: id)
        try await saveTerms()
    }
    
    // MARK: - Related Terms
    
    func getRelatedTerms(for termId: UUID) async -> [Term] {
        guard let term = terms[termId] else { return [] }
        return term.relatedTerms.compactMap { terms[$0] }
    }
    
    // MARK: - Collections
    
    func getCollections() async -> [TermCollection] {
        return Array(collections.values).sorted { $0.name < $1.name }
    }
    
    func getTerms(in collection: TermCollection) async -> [Term] {
        return collection.termIds.compactMap { terms[$0] }
    }
    
    // MARK: - Favorites
    
    func addToFavorites(termId: UUID) async {
        guard var term = terms[termId] else { return }
        term.isFavorite = true
        terms[termId] = term
        try? await saveTerms()
    }
    
    func removeFromFavorites(termId: UUID) async {
        guard var term = terms[termId] else { return }
        term.isFavorite = false
        terms[termId] = term
        try? await saveTerms()
    }
    
    func getFavoriteTerms() async -> [Term] {
        return terms.values.filter { $0.isFavorite }.sorted { $0.text < $1.text }
    }
    
    // MARK: - Recently Accessed
    
    func getRecentlyAccessedTerms(limit: Int) async -> [Term] {
        return terms.values
            .filter { $0.lastAccessedAt != nil }
            .sorted { ($0.lastAccessedAt ?? Date()) > ($1.lastAccessedAt ?? Date()) }
            .prefix(limit)
            .map { $0 }
    }
    
    // MARK: - Recommendations
    
    func getRecommendedTerms() async -> [Term] {
        // 基于访问频率和最近添加推荐
        let sortedByAccess = terms.values.sorted { $0.accessCount > $1.accessCount }
        let recentlyAdded = terms.values.sorted { $0.addedAt > $1.addedAt }.prefix(10)
        
        // 合并并去重
        var recommendations: [Term] = []
        var seenIds = Set<UUID>()
        
        for term in sortedByAccess + recentlyAdded {
            if !seenIds.contains(term.id) {
                recommendations.append(term)
                seenIds.insert(term.id)
            }
            
            if recommendations.count >= 10 {
                break
            }
        }
        
        return recommendations
    }
    
    // MARK: - Import/Export
    
    func importTerms(from url: URL, format: ImportFormat) async throws -> ImportResult {
        let data = try Data(contentsOf: url)
        
        switch format {
        case .json:
            return try await importFromJSON(data: data)
        case .csv:
            return try await importFromCSV(data: data)
        case .markdown:
            return try await importFromMarkdown(data: data)
        }
    }
    
    func exportTerms(to url: URL, format: ExportFormat) async throws {
        let data: Data
        
        switch format {
        case .json:
            data = try exportAsJSON()
        case .csv:
            data = try exportAsCSV()
        case .markdown:
            data = try exportAsMarkdown()
        case .anki:
            data = try exportAsAnki()
        }
        
        try data.write(to: url)
    }
    
    // MARK: - Statistics
    
    func getStatistics() async -> TerminologyStatistics {
        let allTerms = Array(terms.values)
        
        var byCategory: [TermCategory: Int] = [:]
        var byDifficulty: [DifficultyLevel: Int] = [:]
        
        for term in allTerms {
            byCategory[term.category, default: 0] += 1
            byDifficulty[term.difficulty, default: 0] += 1
        }
        
        let mostAccessed = allTerms.sorted { $0.accessCount > $1.accessCount }.prefix(10).map { $0 }
        
        return TerminologyStatistics(
            totalTerms: allTerms.count,
            termsByCategory: byCategory,
            termsByDifficulty: byDifficulty,
            favoriteCount: allTerms.filter { $0.isFavorite }.count,
            recentlyAddedCount: allTerms.filter { Date().timeIntervalSince($0.addedAt) < 7 * 86400 }.count,
            mostAccessedTerms: mostAccessed
        )
    }
    
    // MARK: - Private Methods
    
    private func loadDefaultTerms() {
        // 加载预设的计算机科学术语
        let defaultTerms = getDefaultComputerScienceTerms()
        for term in defaultTerms {
            terms[term.id] = term
        }
        
        // 从本地存储加载用户添加的术语
        if let savedData = UserDefaults.standard.data(forKey: "terminology_terms"),
           let savedTerms = try? JSONDecoder().decode([Term].self, from: savedData) {
            for term in savedTerms {
                terms[term.id] = term
            }
        }
    }
    
    private func saveTerms() async throws {
        let allTerms = Array(terms.values)
        let data = try JSONEncoder().encode(allTerms)
        UserDefaults.standard.set(data, forKey: "terminology_terms")
    }
    
    private func importFromJSON(data: Data) async throws -> ImportResult {
        let importedTerms = try JSONDecoder().decode([Term].self, from: data)
        
        var successCount = 0
        var errors: [String] = []
        
        for term in importedTerms {
            do {
                try await addTerm(term)
                successCount += 1
            } catch {
                errors.append("Failed to import '\(term.text)': \(error.localizedDescription)")
            }
        }
        
        return ImportResult(
            successCount: successCount,
            failureCount: importedTerms.count - successCount,
            errors: errors
        )
    }
    
    private func importFromCSV(data: Data) async throws -> ImportResult {
        // CSV 导入实现
        return ImportResult(successCount: 0, failureCount: 0, errors: [])
    }
    
    private func importFromMarkdown(data: Data) async throws -> ImportResult {
        // Markdown 导入实现
        return ImportResult(successCount: 0, failureCount: 0, errors: [])
    }
    
    private func exportAsJSON() throws -> Data {
        let allTerms = Array(terms.values)
        return try JSONEncoder().encode(allTerms)
    }
    
    private func exportAsCSV() throws -> Data {
        var csv = "Text,Definition,Category,Difficulty\n"
        for term in terms.values {
            csv += "\(term.text),\(term.definition),\(term.category.rawValue),\(term.difficulty.rawValue)\n"
        }
        return csv.data(using: .utf8) ?? Data()
    }
    
    private func exportAsMarkdown() throws -> Data {
        var markdown = "# 计算机科学术语库\n\n"
        
        for category in TermCategory.allCases {
            let categoryTerms = terms.values.filter { $0.category == category }
            guard !categoryTerms.isEmpty else { continue }
            
            markdown += "## \(category.icon) \(category.rawValue)\n\n"
            
            for term in categoryTerms.sorted(by: { $0.text < $1.text }) {
                markdown += "### \(term.text)\n\n"
                markdown += "**定义**: \(term.definition)\n\n"
                
                if !term.examples.isEmpty {
                    markdown += "**示例**:\n"
                    for example in term.examples {
                        markdown += "- \(example)\n"
                    }
                    markdown += "\n"
                }
                
                markdown += "**难度**: \(term.difficulty.rawValue)\n\n"
                markdown += "---\n\n"
            }
        }
        
        return markdown.data(using: .utf8) ?? Data()
    }
    
    private func exportAsAnki() throws -> Data {
        var anki = "#separator:tab\n#html:false\n"
        for term in terms.values {
            anki += "\(term.text)\t\(term.definition)\n"
        }
        return anki.data(using: .utf8) ?? Data()
    }
    
    private func getDefaultComputerScienceTerms() -> [Term] {
        return [
            // 算法
            Term(
                text: "Algorithm",
                definition: "解决特定问题的一系列明确步骤和规则",
                category: .algorithms,
                difficulty: .beginner,
                examples: ["排序算法", "搜索算法", "图算法"]
            ),
            Term(
                text: "Time Complexity",
                definition: "算法执行时间随输入规模增长的变化趋势，通常用大O表示法表示",
                category: .algorithms,
                difficulty: .intermediate,
                examples: ["O(1) 常数时间", "O(n) 线性时间", "O(n²) 平方时间"]
            ),
            Term(
                text: "Dynamic Programming",
                definition: "通过将复杂问题分解为重叠子问题并存储子问题解来优化算法的技术",
                category: .algorithms,
                difficulty: .advanced,
                examples: ["斐波那契数列", "背包问题", "最长公共子序列"]
            ),
            
            // 数据结构
            Term(
                text: "Data Structure",
                definition: "组织和存储数据的方式，使得数据可以高效地被访问和修改",
                category: .dataStructures,
                difficulty: .beginner,
                examples: ["数组", "链表", "树", "图"]
            ),
            Term(
                text: "Binary Tree",
                definition: "每个节点最多有两个子节点的树形数据结构",
                category: .dataStructures,
                difficulty: .intermediate,
                examples: ["二叉搜索树", "AVL树", "红黑树"]
            ),
            Term(
                text: "Hash Table",
                definition: "通过哈希函数将键映射到值的数据结构，支持平均O(1)时间的查找",
                category: .dataStructures,
                difficulty: .intermediate,
                examples: ["字典", "集合", "缓存实现"]
            ),
            
            // 机器学习
            Term(
                text: "Machine Learning",
                definition: "让计算机通过数据自动学习和改进，而无需明确编程的技术",
                category: .machineLearning,
                difficulty: .beginner,
                examples: ["监督学习", "无监督学习", "强化学习"]
            ),
            Term(
                text: "Neural Network",
                definition: "受人脑神经元结构启发的计算模型，由相互连接的节点层组成",
                category: .machineLearning,
                difficulty: .intermediate,
                examples: ["前馈神经网络", "卷积神经网络", "循环神经网络"]
            ),
            Term(
                text: "Gradient Descent",
                definition: "通过迭代调整参数以最小化损失函数的优化算法",
                category: .machineLearning,
                difficulty: .intermediate,
                examples: ["批量梯度下降", "随机梯度下降", "小批量梯度下降"]
            ),
            
            // 深度学习
            Term(
                text: "Deep Learning",
                definition: "使用多层神经网络从大量数据中学习复杂模式的机器学习方法",
                category: .deepLearning,
                difficulty: .intermediate,
                examples: ["图像识别", "语音识别", "自然语言处理"]
            ),
            Term(
                text: "Backpropagation",
                definition: "通过计算损失函数对参数的梯度来训练神经网络的算法",
                category: .deepLearning,
                difficulty: .advanced,
                examples: ["反向传播算法", "链式法则应用"]
            ),
            Term(
                text: "Transformer",
                definition: "基于自注意力机制的深度学习架构，广泛用于NLP任务",
                category: .deepLearning,
                difficulty: .advanced,
                examples: ["BERT", "GPT", "T5"]
            ),
            
            // 操作系统
            Term(
                text: "Operating System",
                definition: "管理计算机硬件和软件资源，为应用程序提供服务的系统软件",
                category: .operatingSystems,
                difficulty: .beginner,
                examples: ["Windows", "macOS", "Linux"]
            ),
            Term(
                text: "Process",
                definition: "正在执行的程序实例，拥有独立的内存空间和系统资源",
                category: .operatingSystems,
                difficulty: .intermediate,
                examples: ["进程调度", "进程间通信", "多进程编程"]
            ),
            Term(
                text: "Virtual Memory",
                definition: "通过将物理内存和磁盘存储结合，为进程提供连续地址空间的技术",
                category: .operatingSystems,
                difficulty: .advanced,
                examples: ["分页", "分段", "页面置换算法"]
            ),
            
            // 数据库
            Term(
                text: "Database",
                definition: "有组织的数据集合，支持高效的数据存储、检索和管理",
                category: .databases,
                difficulty: .beginner,
                examples: ["关系型数据库", "NoSQL数据库", "图数据库"]
            ),
            Term(
                text: "SQL",
                definition: "用于管理和操作关系型数据库的标准查询语言",
                category: .databases,
                difficulty: .intermediate,
                examples: ["SELECT查询", "JOIN操作", "索引优化"]
            ),
            Term(
                text: "ACID",
                definition: "数据库事务的四个特性：原子性、一致性、隔离性、持久性",
                category: .databases,
                difficulty: .advanced,
                examples: ["事务管理", "并发控制", "故障恢复"]
            ),
            
            // 网络
            Term(
                text: "TCP/IP",
                definition: "互联网通信的基础协议套件，包括传输控制协议和网际协议",
                category: .networks,
                difficulty: .intermediate,
                examples: ["三次握手", "流量控制", "拥塞控制"]
            ),
            Term(
                text: "HTTP",
                definition: "超文本传输协议，用于Web浏览器和服务器之间的通信",
                category: .networks,
                difficulty: .beginner,
                examples: ["GET请求", "POST请求", "状态码"]
            ),
            
            // 软件工程
            Term(
                text: "Design Pattern",
                definition: "软件设计中常见问题的典型解决方案，是最佳实践的总结",
                category: .softwareEngineering,
                difficulty: .intermediate,
                examples: ["单例模式", "工厂模式", "观察者模式"]
            ),
            Term(
                text: "Agile",
                definition: "一种强调迭代开发、持续反馈和团队协作的软件开发方法论",
                category: .softwareEngineering,
                difficulty: .beginner,
                examples: ["Scrum", "Kanban", "Sprint"]
            ),
            
            // 编程语言
            Term(
                text: "Object-Oriented Programming",
                definition: "基于对象概念的编程范式，将数据和行为封装在对象中",
                category: .programmingLanguages,
                difficulty: .intermediate,
                examples: ["封装", "继承", "多态"]
            ),
            Term(
                text: "Functional Programming",
                definition: "将计算视为数学函数求值的编程范式，避免状态变化和可变数据",
                category: .programmingLanguages,
                difficulty: .advanced,
                examples: ["纯函数", "高阶函数", "不可变性"]
            ),
            
            // 安全
            Term(
                text: "Encryption",
                definition: "将明文转换为密文以保护数据安全的技术",
                category: .security,
                difficulty: .intermediate,
                examples: ["对称加密", "非对称加密", "哈希函数"]
            ),
            Term(
                text: "Authentication",
                definition: "验证用户身份的过程，确保用户是其所声称的人",
                category: .security,
                difficulty: .intermediate,
                examples: ["密码认证", "双因素认证", "生物识别"]
            )
        ]
    }
}
