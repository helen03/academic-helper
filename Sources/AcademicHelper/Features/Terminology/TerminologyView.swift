import SwiftUI

struct TerminologyView: View {
    @StateObject private var viewModel = TerminologyViewModel()
    
    var body: some View {
        NavigationView {
            SidebarView(viewModel: viewModel)
            
            if let selectedTerm = viewModel.selectedTerm {
                TermDetailView(term: selectedTerm, viewModel: viewModel)
            } else {
                EmptyStateView()
            }
        }
        .navigationTitle("术语库")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { viewModel.showAddTermSheet = true }) {
                    Label("添加术语", systemImage: "plus")
                }
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "搜索术语")
    }
}

// MARK: - Sidebar

struct SidebarView: View {
    @ObservedObject var viewModel: TerminologyViewModel
    
    var body: some View {
        List(selection: $viewModel.selectedCategory) {
            Section("收藏") {
                Label("我的收藏", systemImage: "star.fill")
                    .tag(Optional<TermCategory>(nil))
                    .badge(viewModel.favoriteCount)
                
                Label("最近查看", systemImage: "clock")
                    .tag(Optional<TermCategory>(nil))
            }
            
            Section("分类") {
                ForEach(TermCategory.allCases) { category in
                    Label {
                        Text(category.rawValue)
                    } icon: {
                        Text(category.icon)
                    }
                    .tag(Optional(category))
                    .badge(viewModel.termCount(for: category))
                }
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 200)
    }
}

// MARK: - Term Detail View

struct TermDetailView: View {
    let term: Term
    @ObservedObject var viewModel: TerminologyViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 标题区域
                HeaderSection(term: term, viewModel: viewModel)
                
                Divider()
                
                // 定义
                DefinitionSection(term: term)
                
                // 示例
                if !term.examples.isEmpty {
                    ExamplesSection(examples: term.examples)
                }
                
                // 相关术语
                if !term.relatedTerms.isEmpty {
                    RelatedTermsSection(relatedTerms: viewModel.getRelatedTerms(for: term))
                }
                
                // 来源
                if !term.sources.isEmpty {
                    SourcesSection(sources: term.sources)
                }
            }
            .padding()
        }
        .frame(minWidth: 500)
    }
}

struct HeaderSection: View {
    let term: Term
    @ObservedObject var viewModel: TerminologyViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(term.text)
                    .font(.system(size: 32, weight: .bold))
                
                HStack(spacing: 12) {
                    Label(term.category.rawValue, systemImage: "folder")
                        .font(.subheadline)
                    
                    DifficultyBadge(level: term.difficulty)
                }
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: { viewModel.toggleFavorite(term) }) {
                Image(systemName: term.isFavorite ? "star.fill" : "star")
                    .font(.title2)
                    .foregroundColor(term.isFavorite ? .yellow : .gray)
            }
            .buttonStyle(.borderless)
        }
    }
}

struct DefinitionSection: View {
    let term: Term
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("定义")
                .font(.headline)
            
            Text(term.definition)
                .font(.body)
                .lineSpacing(4)
        }
    }
}

struct ExamplesSection: View {
    let examples: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("示例")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(examples, id: \.self) { example in
                    HStack(alignment: .top) {
                        Text("•")
                        Text(example)
                    }
                }
            }
        }
    }
}

struct RelatedTermsSection: View {
    let relatedTerms: [Term]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("相关术语")
                .font(.headline)
            
            FlowLayout(spacing: 8) {
                ForEach(relatedTerms) { term in
                    RelatedTermChip(term: term)
                }
            }
        }
    }
}

struct RelatedTermChip: View {
    let term: Term
    
    var body: some View {
        Text(term.text)
            .font(.subheadline)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(16)
    }
}

struct SourcesSection: View {
    let sources: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("参考来源")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(sources, id: \.self) { source in
                    Link(destination: URL(string: source)!) {
                        Text(source)
                            .font(.caption)
                            .lineLimit(1)
                    }
                }
            }
        }
    }
}

struct DifficultyBadge: View {
    let level: DifficultyLevel
    
    var color: Color {
        switch level {
        case .beginner: return .green
        case .intermediate: return .blue
        case .advanced: return .orange
        case .expert: return .red
        }
    }
    
    var body: some View {
        Text(level.rawValue)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .cornerRadius(4)
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("选择一个术语查看详情")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("或者使用搜索功能查找术语")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

// MARK: - View Model

@MainActor
class TerminologyViewModel: ObservableObject {
    @Published var terms: [Term] = []
    @Published var selectedTerm: Term?
    @Published var selectedCategory: TermCategory?
    @Published var searchText = ""
    @Published var showAddTermSheet = false
    
    var filteredTerms: [Term] {
        var result = terms
        
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }
        
        if !searchText.isEmpty {
            result = result.filter {
                $0.text.localizedCaseInsensitiveContains(searchText) ||
                $0.definition.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return result.sorted { $0.text < $1.text }
    }
    
    var favoriteCount: Int {
        terms.filter { $0.isFavorite }.count
    }
    
    init() {
        loadTerms()
    }
    
    func loadTerms() {
        // 加载默认术语
        terms = [
            Term(text: "Algorithm", definition: "解决特定问题的一系列明确步骤和规则", category: .algorithms, difficulty: .beginner,
                 examples: ["排序算法", "搜索算法", "图算法"]),
            Term(text: "Machine Learning", definition: "让计算机通过数据自动学习和改进的技术", category: .machineLearning, difficulty: .beginner,
                 examples: ["监督学习", "无监督学习", "强化学习"]),
            Term(text: "Neural Network", definition: "受人脑神经元结构启发的计算模型", category: .machineLearning, difficulty: .intermediate,
                 examples: ["前馈神经网络", "卷积神经网络", "循环神经网络"]),
            Term(text: "Database", definition: "有组织的数据集合，支持高效的数据存储和检索", category: .databases, difficulty: .beginner,
                 examples: ["关系型数据库", "NoSQL数据库", "图数据库"]),
            Term(text: "TCP/IP", definition: "互联网通信的基础协议套件", category: .networks, difficulty: .intermediate,
                 examples: ["三次握手", "流量控制", "拥塞控制"])
        ]
    }
    
    func termCount(for category: TermCategory) -> Int {
        terms.filter { $0.category == category }.count
    }
    
    func toggleFavorite(_ term: Term) {
        if let index = terms.firstIndex(where: { $0.id == term.id }) {
            terms[index].isFavorite.toggle()
        }
    }
    
    func getRelatedTerms(for term: Term) -> [Term] {
        term.relatedTerms.compactMap { relatedId in
            terms.first { $0.id == relatedId }
        }
    }
}

// MARK: - Supporting Types

enum TermCategory: String, CaseIterable, Identifiable {
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

enum DifficultyLevel: String, CaseIterable {
    case beginner = "初级"
    case intermediate = "中级"
    case advanced = "高级"
    case expert = "专家"
}

struct Term: Identifiable {
    let id = UUID()
    var text: String
    var definition: String
    var category: TermCategory
    var difficulty: DifficultyLevel
    var relatedTerms: [UUID] = []
    var examples: [String] = []
    var sources: [String] = []
    var isFavorite: Bool = false
}
