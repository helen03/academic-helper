import SwiftUI
import PDFKit

struct LiteratureManagementView: View {
    @State private var selectedTab: LiteratureTab = .library
    @State private var selectedDocument: LiteratureDocument?
    
    enum LiteratureTab: String, CaseIterable {
        case library = "文献库"
        case recent = "最近阅读"
        case favorites = "收藏"
        
        var icon: String {
            switch self {
            case .library: return "folder.fill"
            case .recent: return "clock.fill"
            case .favorites: return "star.fill"
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            LiteratureSidebar(selectedTab: $selectedTab)
        } detail: {
            switch selectedTab {
            case .library:
                LiteratureLibraryView(selectedDocument: $selectedDocument)
            case .recent:
                RecentDocumentsView(selectedDocument: $selectedDocument)
            case .favorites:
                FavoriteDocumentsView(selectedDocument: $selectedDocument)
            }
        }
        .sheet(item: $selectedDocument) { document in
            PDFReaderView(document: document)
        }
    }
}

struct LiteratureSidebar: View {
    @Binding var selectedTab: LiteratureManagementView.LiteratureTab
    
    var body: some View {
        List(LiteratureManagementView.LiteratureTab.allCases, selection: $selectedTab) { tab in
            Label(tab.rawValue, systemImage: tab.icon)
                .tag(tab)
        }
        .listStyle(.sidebar)
        .frame(minWidth: 150)
    }
}

struct LiteratureLibraryView: View {
    @StateObject private var viewModel = LiteratureLibraryViewModel()
    @Binding var selectedDocument: LiteratureDocument?
    @State private var searchText = ""
    @State private var showingImportDialog = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                SearchBar(text: $searchText)
                    .frame(width: 250)
                
                Spacer()
                
                Button(action: { showingImportDialog = true }) {
                    Label("导入 PDF", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            Divider()
            
            // Document list
            if viewModel.documents.isEmpty {
                EmptyLibraryView()
            } else {
                List(viewModel.filteredDocuments, selection: $selectedDocument) { document in
                    LiteratureRow(document: document)
                        .tag(document)
                        .contextMenu {
                            Button {
                                viewModel.openDocument(document)
                            } label: {
                                Label("打开", systemImage: "doc.text")
                            }
                            
                            Button {
                                viewModel.toggleFavorite(document)
                            } label: {
                                Label("收藏", systemImage: "star")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive) {
                                viewModel.deleteDocument(document)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                }
                .listStyle(.plain)
            }
        }
        .fileImporter(
            isPresented: $showingImportDialog,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: true
        ) { result in
            handleImportResult(result)
        }
        .task {
            await viewModel.loadDocuments()
        }
        .onChange(of: searchText) { _, newValue in
            viewModel.search(query: newValue)
        }
    }
    
    private func handleImportResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            Task {
                for url in urls {
                    await viewModel.importDocument(from: url)
                }
            }
        case .failure(let error):
            print("Import failed: \(error)")
        }
    }
}

struct LiteratureRow: View {
    let document: LiteratureDocument
    
    var body: some View {
        HStack(spacing: 12) {
            // PDF icon
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 40, height: 50)
                
                Image(systemName: "doc.text")
                    .font(.title3)
                    .foregroundStyle(.red)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(document.title)
                    .font(.headline)
                    .lineLimit(1)
                
                if !document.authors.isEmpty {
                    Text(document.authors.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                HStack(spacing: 8) {
                    Text("\(document.pageCount) 页")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Text("•")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Text(formatFileSize(document.fileSize))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    if let lastOpened = document.lastOpenedAt {
                        Text("•")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        
                        Text(formatDate(lastOpened))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Linked words count
            if !document.linkedWordIDs.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "link")
                        .font(.caption)
                    Text("\(document.linkedWordIDs.count)")
                        .font(.caption)
                }
                .foregroundStyle(.blue)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatFileSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct EmptyLibraryView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("文献库为空")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("点击右上角的按钮导入 PDF 文件")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct RecentDocumentsView: View {
    @StateObject private var viewModel = RecentDocumentsViewModel()
    @Binding var selectedDocument: LiteratureDocument?
    
    var body: some View {
        VStack {
            if viewModel.recentDocuments.isEmpty {
                EmptyStateView(
                    icon: "clock",
                    title: "没有最近阅读的文献",
                    message: "打开文献后会显示在这里"
                )
            } else {
                List(viewModel.recentDocuments, selection: $selectedDocument) { document in
                    LiteratureRow(document: document)
                        .tag(document)
                }
                .listStyle(.plain)
            }
        }
        .task {
            await viewModel.loadRecentDocuments()
        }
    }
}

struct FavoriteDocumentsView: View {
    @StateObject private var viewModel = FavoriteDocumentsViewModel()
    @Binding var selectedDocument: LiteratureDocument?
    
    var body: some View {
        VStack {
            if viewModel.favoriteDocuments.isEmpty {
                EmptyStateView(
                    icon: "star",
                    title: "没有收藏的文献",
                    message: "在文献库中收藏文献后会显示在这里"
                )
            } else {
                List(viewModel.favoriteDocuments, selection: $selectedDocument) { document in
                    LiteratureRow(document: document)
                        .tag(document)
                }
                .listStyle(.plain)
            }
        }
        .task {
            await viewModel.loadFavoriteDocuments()
        }
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text(title)
                .font(.title2)
                .fontWeight(.medium)
            
            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

@MainActor
class LiteratureLibraryViewModel: ObservableObject {
    @Published var documents: [LiteratureDocument] = []
    @Published var filteredDocuments: [LiteratureDocument] = []
    
    @Inject private var pdfService: PDFServiceProtocol
    @Inject private var literatureRepository: LiteratureRepositoryProtocol
    
    func loadDocuments() async {
        do {
            documents = try await literatureRepository.fetchAllDocuments()
            filteredDocuments = documents
        } catch {
            print("Failed to load documents: \(error)")
        }
    }
    
    func importDocument(from url: URL) async {
        do {
            let document = try await pdfService.importDocument(from: url)
            try await literatureRepository.saveDocument(document)
            await loadDocuments()
        } catch {
            print("Failed to import document: \(error)")
        }
    }
    
    func deleteDocument(_ document: LiteratureDocument) {
        Task {
            do {
                try await literatureRepository.deleteDocument(id: document.id)
                await loadDocuments()
            } catch {
                print("Failed to delete document: \(error)")
            }
        }
    }
    
    func openDocument(_ document: LiteratureDocument) {
        var updatedDocument = document
        updatedDocument.lastOpenedAt = Date()
        
        Task {
            do {
                try await literatureRepository.updateDocument(updatedDocument)
            } catch {
                print("Failed to update document: \(error)")
            }
        }
    }
    
    func toggleFavorite(_ document: LiteratureDocument) {
        // Implement favorite functionality
    }
    
    func search(query: String) {
        if query.isEmpty {
            filteredDocuments = documents
        } else {
            Task {
                do {
                    filteredDocuments = try await literatureRepository.searchDocuments(query: query)
                } catch {
                    print("Search failed: \(error)")
                }
            }
        }
    }
}

@MainActor
class RecentDocumentsViewModel: ObservableObject {
    @Published var recentDocuments: [LiteratureDocument] = []
    
    @Inject private var literatureRepository: LiteratureRepositoryProtocol
    
    func loadRecentDocuments() async {
        do {
            let allDocuments = try await literatureRepository.fetchAllDocuments()
            recentDocuments = allDocuments
                .filter { $0.lastOpenedAt != nil }
                .sorted { ($0.lastOpenedAt ?? Date()) > ($1.lastOpenedAt ?? Date()) }
                .prefix(20)
                .map { $0 }
        } catch {
            print("Failed to load recent documents: \(error)")
        }
    }
}

@MainActor
class FavoriteDocumentsViewModel: ObservableObject {
    @Published var favoriteDocuments: [LiteratureDocument] = []
    
    func loadFavoriteDocuments() async {
        // Implement favorite loading logic
    }
}
