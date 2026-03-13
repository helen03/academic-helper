import SwiftUI
import PDFKit

struct PDFReaderView: View {
    let document: LiteratureDocument
    @StateObject private var viewModel: PDFReaderViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(document: LiteratureDocument) {
        self.document = document
        self._viewModel = StateObject(wrappedValue: PDFReaderViewModel(document: document))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Toolbar
                readerToolbar
                
                Divider()
                
                // PDF Content
                HStack(spacing: 0) {
                    // Main PDF view
                    PDFKitView(pdfDocument: viewModel.pdfDocument)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // Sidebar (optional)
                    if viewModel.showSidebar {
                        PDFSidebar(viewModel: viewModel)
                            .frame(width: 250)
                            .background(Color.gray.opacity(0.05))
                    }
                }
            }
            .navigationTitle(document.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    HStack {
                        Button(action: { viewModel.showSidebar.toggle() }) {
                            Image(systemName: "sidebar.right")
                        }
                        
                        Menu {
                            Button(action: { viewModel.showWordLinking() }) {
                                Label("关联单词", systemImage: "link")
                            }
                            
                            Button(action: { viewModel.extractText() }) {
                                Label("提取文本", systemImage: "text.quote")
                            }
                            
                            Divider()
                            
                            Button(action: { viewModel.toggleFavorite() }) {
                                Label("收藏", systemImage: "star")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingWordLinking) {
                WordLinkingView(document: document)
            }
            .alert("提取的文本", isPresented: $viewModel.showingExtractedText) {
                Button("确定", role: .cancel) {}
                Button("复制") {
                    viewModel.copyExtractedText()
                }
            } message: {
                Text(viewModel.extractedText.prefix(500))
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .task {
            await viewModel.loadPDF()
        }
    }
    
    private var readerToolbar: some View {
        HStack(spacing: 16) {
            // Page navigation
            HStack(spacing: 8) {
                Button(action: { viewModel.previousPage() }) {
                    Image(systemName: "chevron.left")
                }
                .disabled(viewModel.currentPage <= 1)
                
                Text("\(viewModel.currentPage) / \(viewModel.totalPages)")
                    .font(.caption)
                    .monospacedDigit()
                    .frame(minWidth: 60)
                
                Button(action: { viewModel.nextPage() }) {
                    Image(systemName: "chevron.right")
                }
                .disabled(viewModel.currentPage >= viewModel.totalPages)
            }
            
            Divider()
                .frame(height: 20)
            
            // Zoom controls
            HStack(spacing: 8) {
                Button(action: { viewModel.zoomOut() }) {
                    Image(systemName: "minus.magnifyingglass")
                }
                
                Text("\(Int(viewModel.zoomLevel * 100))%")
                    .font(.caption)
                    .monospacedDigit()
                    .frame(minWidth: 50)
                
                Button(action: { viewModel.zoomIn() }) {
                    Image(systemName: "plus.magnifyingglass")
                }
            }
            
            Spacer()
            
            // Search
            HStack(spacing: 4) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("搜索...", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                    .frame(width: 150)
            }
            .padding(6)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(6)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

struct PDFKitView: NSViewRepresentable {
    let pdfDocument: PDFDocument?
    
    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = pdfDocument
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        return pdfView
    }
    
    func updateNSView(_ pdfView: PDFView, context: Context) {
        pdfView.document = pdfDocument
    }
}

struct PDFSidebar: View {
    @ObservedObject var viewModel: PDFReaderViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Tabs
            Picker("", selection: $viewModel.sidebarTab) {
                Text("缩略图").tag(PDFReaderViewModel.SidebarTab.thumbnails)
                Text("大纲").tag(PDFReaderViewModel.SidebarTab.outline)
                Text("单词").tag(PDFReaderViewModel.SidebarTab.words)
            }
            .pickerStyle(.segmented)
            .padding()
            
            Divider()
            
            // Content
            switch viewModel.sidebarTab {
            case .thumbnails:
                ThumbnailView(viewModel: viewModel)
            case .outline:
                OutlineView(viewModel: viewModel)
            case .words:
                LinkedWordsView(viewModel: viewModel)
            }
        }
    }
}

struct ThumbnailView: View {
    @ObservedObject var viewModel: PDFReaderViewModel
    
    var body: some View {
        List(1...viewModel.totalPages, id: \.self) { pageNumber in
            Button(action: {
                viewModel.goToPage(pageNumber)
            }) {
                HStack {
                    Text("\(pageNumber)")
                        .font(.caption)
                        .frame(width: 30)
                    
                    if let thumbnail = viewModel.thumbnail(for: pageNumber) {
                        Image(nsImage: thumbnail)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 60)
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 60)
                    }
                }
            }
            .buttonStyle(.plain)
            .background(viewModel.currentPage == pageNumber ? Color.blue.opacity(0.2) : Color.clear)
            .cornerRadius(4)
        }
        .listStyle(.plain)
    }
}

struct OutlineView: View {
    @ObservedObject var viewModel: PDFReaderViewModel
    
    var body: some View {
        List {
            Text("文档大纲")
                .font(.headline)
            
            if let outline = viewModel.pdfDocument?.outlineRoot {
                OutlineItems(outlineItem: outline, viewModel: viewModel)
            } else {
                Text("无可用大纲")
                    .foregroundStyle(.secondary)
            }
        }
        .listStyle(.plain)
    }
}

struct OutlineItems: View {
    let outlineItem: PDFOutline
    let viewModel: PDFReaderViewModel
    
    var body: some View {
        if let label = outlineItem.label {
            Button(action: {
                if let destination = outlineItem.destination,
                   let page = destination.page {
                    viewModel.goToPage(page)
                }
            }) {
                Text(label)
                    .font(.subheadline)
            }
            .buttonStyle(.plain)
        }
        
        ForEach(0..<outlineItem.numberOfChildren, id: \.self) { index in
            if let child = outlineItem.child(at: index) {
                OutlineItems(outlineItem: child, viewModel: viewModel)
                    .padding(.leading, 16)
            }
        }
    }
}

struct LinkedWordsView: View {
    @ObservedObject var viewModel: PDFReaderViewModel
    
    var body: some View {
        List {
            Text("关联单词")
                .font(.headline)
            
            if viewModel.linkedWords.isEmpty {
                Text("暂无关联单词")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.linkedWords) { word in
                    HStack {
                        Text(word.text)
                            .font(.subheadline)
                        Spacer()
                        if let definition = word.definition {
                            Text(definition)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
    }
}

struct WordLinkingView: View {
    let document: LiteratureDocument
    @StateObject private var viewModel: WordLinkingViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(document: LiteratureDocument) {
        self.document = document
        self._viewModel = StateObject(wrappedValue: WordLinkingViewModel(document: document))
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // Search bar
                SearchBar(text: $viewModel.searchText)
                    .padding()
                
                // Word list
                List(viewModel.filteredWords) { word in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(word.text)
                                .font(.headline)
                            
                            if let definition = word.definition {
                                Text(definition)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        
                        Spacer()
                        
                        if viewModel.isLinked(word) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.toggleLink(word)
                    }
                }
            }
            .navigationTitle("关联单词")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.loadWords()
            }
        }
        .frame(minWidth: 400, minHeight: 500)
    }
}

@MainActor
class PDFReaderViewModel: ObservableObject {
    @Published var pdfDocument: PDFDocument?
    @Published var currentPage = 1
    @Published var totalPages = 0
    @Published var zoomLevel: CGFloat = 1.0
    @Published var showSidebar = false
    @Published var sidebarTab: SidebarTab = .thumbnails
    @Published var searchText = ""
    @Published var showingWordLinking = false
    @Published var showingExtractedText = false
    @Published var extractedText = ""
    @Published var linkedWords: [Word] = []
    
    let document: LiteratureDocument
    
    enum SidebarTab {
        case thumbnails
        case outline
        case words
    }
    
    @Inject private var pdfService: PDFServiceProtocol
    @Inject private var wordRepository: WordRepositoryProtocol
    
    init(document: LiteratureDocument) {
        self.document = document
    }
    
    func loadPDF() async {
        pdfDocument = pdfService.getPDFDocument(from: document)
        totalPages = pdfDocument?.pageCount ?? 0
        
        // Load linked words
        await loadLinkedWords()
    }
    
    func loadLinkedWords() async {
        // Load words linked to this document
        // This is a placeholder implementation
    }
    
    func previousPage() {
        guard currentPage > 1 else { return }
        currentPage -= 1
    }
    
    func nextPage() {
        guard currentPage < totalPages else { return }
        currentPage += 1
    }
    
    func goToPage(_ page: Int) {
        currentPage = max(1, min(page, totalPages))
    }
    
    func goToPage(_ page: PDFPage) {
        if let index = pdfDocument?.index(for: page) {
            currentPage = index + 1
        }
    }
    
    func zoomIn() {
        zoomLevel = min(zoomLevel + 0.25, 3.0)
    }
    
    func zoomOut() {
        zoomLevel = max(zoomLevel - 0.25, 0.5)
    }
    
    func thumbnail(for pageNumber: Int) -> NSImage? {
        guard let page = pdfDocument?.page(at: pageNumber - 1) else { return nil }
        return page.thumbnail(of: NSSize(width: 100, height: 150), for: .cropBox)
    }
    
    func showWordLinking() {
        showingWordLinking = true
    }
    
    func extractText() {
        Task {
            do {
                let extractedTexts = try await pdfService.extractText(from: document)
                extractedText = extractedTexts.map { $0.text }.joined(separator: "\n\n")
                await MainActor.run {
                    showingExtractedText = true
                }
            } catch {
                print("Failed to extract text: \(error)")
            }
        }
    }
    
    func copyExtractedText() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(extractedText, forType: .string)
    }
    
    func toggleFavorite() {
        // Implement favorite functionality
    }
}

@MainActor
class WordLinkingViewModel: ObservableObject {
    let document: LiteratureDocument
    @Published var allWords: [Word] = []
    @Published var filteredWords: [Word] = []
    @Published var linkedWordIDs: Set<UUID> = []
    @Published var searchText = ""
    
    @Inject private var wordRepository: WordRepositoryProtocol
    @Inject private var literatureRepository: LiteratureRepositoryProtocol
    
    init(document: LiteratureDocument) {
        self.document = document
        self.linkedWordIDs = Set(document.linkedWordIDs)
    }
    
    func loadWords() async {
        do {
            allWords = try await wordRepository.fetchAllWords()
            filterWords()
        } catch {
            print("Failed to load words: \(error)")
        }
    }
    
    func filterWords() {
        if searchText.isEmpty {
            filteredWords = allWords
        } else {
            filteredWords = allWords.filter {
                $0.text.localizedCaseInsensitiveContains(searchText) ||
                ($0.definition?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    func isLinked(_ word: Word) -> Bool {
        linkedWordIDs.contains(word.id)
    }
    
    func toggleLink(_ word: Word) {
        Task {
            do {
                if linkedWordIDs.contains(word.id) {
                    linkedWordIDs.remove(word.id)
                } else {
                    linkedWordIDs.insert(word.id)
                    try await literatureRepository.linkWordToDocument(wordID: word.id, documentID: document.id)
                }
            } catch {
                print("Failed to toggle link: \(error)")
            }
        }
    }
}
