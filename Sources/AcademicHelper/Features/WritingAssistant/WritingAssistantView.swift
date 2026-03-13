import SwiftUI
import NaturalLanguage

struct WritingAssistantView: View {
    @State private var selectedTab: WritingTab = .editor
    @StateObject private var viewModel = WritingAssistantViewModel()
    
    enum WritingTab: String, CaseIterable {
        case editor = "写作编辑器"
        case expressions = "表达库"
        case favorites = "收藏"
        
        var icon: String {
            switch self {
            case .editor: return "pencil"
            case .expressions: return "text.quote"
            case .favorites: return "star"
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            WritingSidebar(selectedTab: $selectedTab)
        } detail: {
            switch selectedTab {
            case .editor:
                WritingEditorView(viewModel: viewModel)
            case .expressions:
                ExpressionLibraryView()
            case .favorites:
                FavoriteExpressionsView()
            }
        }
    }
}

struct WritingSidebar: View {
    @Binding var selectedTab: WritingAssistantView.WritingTab
    
    var body: some View {
        List(WritingAssistantView.WritingTab.allCases, selection: $selectedTab) { tab in
            Label(tab.rawValue, systemImage: tab.icon)
                .tag(tab)
        }
        .listStyle(.sidebar)
        .frame(minWidth: 150)
    }
}

struct WritingEditorView: View {
    @ObservedObject var viewModel: WritingAssistantViewModel
    @State private var showingRecognitionResults = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Text("学术写作助手")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    viewModel.recognizeExpressions()
                    showingRecognitionResults = true
                }) {
                    Label("识别表达", systemImage: "text.magnifyingglass")
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.inputText.isEmpty)
                
                Button(action: {
                    viewModel.clearText()
                }) {
                    Label("清空", systemImage: "trash")
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.inputText.isEmpty)
            }
            .padding()
            
            Divider()
            
            // Editor
            HSplitView {
                // Input area
                VStack(alignment: .leading, spacing: 8) {
                    Text("输入文本")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    TextEditor(text: $viewModel.inputText)
                        .font(.body)
                        .frame(minWidth: 300)
                }
                .padding()
                
                // Output area
                VStack(alignment: .leading, spacing: 8) {
                    Text("识别结果")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    if viewModel.recognizedExpressions.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "text.magnifyingglass")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)
                            
                            Text("点击"识别表达"按钮\n分析文本中的学术表达")
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List(viewModel.recognizedExpressions) { item in
                            RecognizedExpressionRow(item: item) { expression in
                                viewModel.saveExpression(expression)
                            }
                        }
                        .listStyle(.plain)
                    }
                }
                .padding()
                .frame(minWidth: 300)
            }
        }
        .sheet(isPresented: $showingRecognitionResults) {
            RecognitionResultsView(viewModel: viewModel)
        }
    }
}

struct RecognizedExpressionRow: View {
    let item: RecognizedExpressionItem
    let onSave: (AcademicExpression) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.expression.text)
                    .font(.headline)
                
                Spacer()
                
                CategoryBadge(category: item.expression.category)
                
                Button(action: {
                    onSave(item.expression)
                }) {
                    Image(systemName: item.isSaved ? "star.fill" : "star")
                        .foregroundStyle(item.isSaved ? .yellow : .secondary)
                }
                .buttonStyle(.plain)
            }
            
            if let meaning = item.expression.meaning {
                Text(meaning)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Text("上下文: \"...\(item.context)...\"")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .italic()
        }
        .padding(.vertical, 4)
    }
}

struct CategoryBadge: View {
    let category: ExpressionCategory
    
    var body: some View {
        Text(category.rawValue)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(categoryColor.opacity(0.2))
            .foregroundColor(categoryColor)
            .cornerRadius(4)
    }
    
    private var categoryColor: Color {
        switch category {
        case .transition:
            return .blue
        case .emphasis:
            return .orange
        case .comparison:
            return .purple
        case .causeEffect:
            return .red
        case .conclusion:
            return .green
        case .methodology:
            return .teal
        case .result:
            return .indigo
        case .discussion:
            return .pink
        case .introduction:
            return .cyan
        case .other:
            return .gray
        }
    }
}

struct RecognitionResultsView: View {
    @ObservedObject var viewModel: WritingAssistantViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.recognizedExpressions.isEmpty {
                    EmptyRecognitionView()
                } else {
                    List {
                        ForEach(ExpressionCategory.allCases, id: \.self) { category in
                            let items = viewModel.expressions(for: category)
                            if !items.isEmpty {
                                Section(header: Text(category.rawValue)) {
                                    ForEach(items) { item in
                                        RecognizedExpressionRow(item: item) { expression in
                                            viewModel.saveExpression(expression)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("识别到的学术表达")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("保存全部") {
                        viewModel.saveAllExpressions()
                    }
                    .disabled(viewModel.recognizedExpressions.isEmpty)
                }
            }
        }
        .frame(minWidth: 500, minHeight: 400)
    }
}

struct EmptyRecognitionView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("未识别到学术表达")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("尝试输入更长的学术文本，\n或检查文本是否包含常用学术表达。")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ExpressionLibraryView: View {
    @StateObject private var viewModel = ExpressionLibraryViewModel()
    @State private var selectedCategory: ExpressionCategory?
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                SearchBar(text: $searchText)
                    .frame(width: 250)
                
                Spacer()
                
                Picker("分类", selection: $selectedCategory) {
                    Text("全部").tag(nil as ExpressionCategory?)
                    ForEach(ExpressionCategory.allCases, id: \.self) { category in
                        Text(category.rawValue).tag(category as ExpressionCategory?)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 150)
            }
            .padding()
            
            Divider()
            
            // Expression list
            if viewModel.expressions.isEmpty {
                EmptyLibraryView()
            } else {
                List(viewModel.filteredExpressions(category: selectedCategory, search: searchText)) { expression in
                    ExpressionRow(expression: expression)
                }
                .listStyle(.plain)
            }
        }
        .task {
            await viewModel.loadExpressions()
        }
    }
}

struct ExpressionRow: View {
    let expression: AcademicExpression
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(expression.text)
                    .font(.headline)
                
                Spacer()
                
                CategoryBadge(category: expression.category)
                
                if expression.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption)
                }
            }
            
            if let meaning = expression.meaning {
                Text(meaning)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            if let usage = expression.usage {
                Text("用法: \(usage)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if !expression.examples.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(expression.examples.prefix(2), id: \.self) { example in
                        Text("• \(example)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .italic()
                    }
                }
            }
            
            if !expression.alternatives.isEmpty {
                Text("替代表达: \(expression.alternatives.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}

struct FavoriteExpressionsView: View {
    @StateObject private var viewModel = FavoriteExpressionsViewModel()
    
    var body: some View {
        VStack {
            if viewModel.favoriteExpressions.isEmpty {
                EmptyStateView(
                    icon: "star",
                    title: "没有收藏的学术表达",
                    message: "在写作编辑器中识别并收藏表达后会显示在这里"
                )
            } else {
                List(viewModel.favoriteExpressions) { expression in
                    ExpressionRow(expression: expression)
                }
                .listStyle(.plain)
            }
        }
        .task {
            await viewModel.loadFavoriteExpressions()
        }
    }
}

struct RecognizedExpressionItem: Identifiable {
    let id = UUID()
    let expression: AcademicExpression
    let context: String
    let confidence: Double
    var isSaved: Bool = false
}

@MainActor
class WritingAssistantViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published var recognizedExpressions: [RecognizedExpressionItem] = []
    
    @Inject private var expressionRecognitionService: ExpressionRecognitionServiceProtocol
    @Inject private var expressionRepository: ExpressionRepositoryProtocol
    
    func recognizeExpressions() {
        Task {
            do {
                let expressions = try await expressionRecognitionService.recognizeExpression(in: inputText)
                
                let items = expressions.map { recognized in
                    RecognizedExpressionItem(
                        expression: recognized.expression,
                        context: recognized.context,
                        confidence: recognized.confidence
                    )
                }
                
                await MainActor.run {
                    self.recognizedExpressions = items
                }
            } catch {
                print("Failed to recognize expressions: \(error)")
            }
        }
    }
    
    func saveExpression(_ expression: AcademicExpression) {
        Task {
            do {
                try await expressionRepository.saveExpression(expression)
                
                // Update UI to show saved state
                if let index = recognizedExpressions.firstIndex(where: { $0.expression.text == expression.text }) {
                    await MainActor.run {
                        recognizedExpressions[index].isSaved = true
                    }
                }
            } catch {
                print("Failed to save expression: \(error)")
            }
        }
    }
    
    func saveAllExpressions() {
        Task {
            for item in recognizedExpressions where !item.isSaved {
                await saveExpression(item.expression)
            }
        }
    }
    
    func clearText() {
        inputText = ""
        recognizedExpressions = []
    }
    
    func expressions(for category: ExpressionCategory) -> [RecognizedExpressionItem] {
        recognizedExpressions.filter { $0.expression.category == category }
    }
}

@MainActor
class ExpressionLibraryViewModel: ObservableObject {
    @Published var expressions: [AcademicExpression] = []
    
    @Inject private var expressionRepository: ExpressionRepositoryProtocol
    
    func loadExpressions() async {
        do {
            expressions = try await expressionRepository.fetchAllExpressions()
        } catch {
            print("Failed to load expressions: \(error)")
        }
    }
    
    func filteredExpressions(category: ExpressionCategory?, search: String) -> [AcademicExpression] {
        var result = expressions
        
        if let category = category {
            result = result.filter { $0.category == category }
        }
        
        if !search.isEmpty {
            result = result.filter {
                $0.text.localizedCaseInsensitiveContains(search) ||
                ($0.meaning?.localizedCaseInsensitiveContains(search) ?? false)
            }
        }
        
        return result
    }
}

@MainActor
class FavoriteExpressionsViewModel: ObservableObject {
    @Published var favoriteExpressions: [AcademicExpression] = []
    
    @Inject private var expressionRepository: ExpressionRepositoryProtocol
    
    func loadFavoriteExpressions() async {
        do {
            favoriteExpressions = try await expressionRepository.fetchFavoriteExpressions()
        } catch {
            print("Failed to load favorite expressions: \(error)")
        }
    }
}
