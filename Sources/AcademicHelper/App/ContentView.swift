import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .wordLearning
    
    enum Tab: String, CaseIterable {
        case wordLearning = "单词学习"
        case literature = "文献管理"
        case writing = "写作辅助"
        case settings = "设置"
        
        var icon: String {
            switch self {
            case .wordLearning: return "character.book.closed"
            case .literature: return "doc.text"
            case .writing: return "pencil.line"
            case .settings: return "gear"
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            List(Tab.allCases, selection: $selectedTab) { tab in
                Label(tab.rawValue, systemImage: tab.icon)
                    .tag(tab)
            }
            .navigationTitle("AcademicHelper")
            .listStyle(.sidebar)
        } detail: {
            switch selectedTab {
            case .wordLearning:
                WordLearningView()
            case .literature:
                LiteratureManagementView()
            case .writing:
                WritingAssistantView()
            case .settings:
                SettingsView()
            }
        }
    }
}

struct SettingsView: View {
    var body: some View {
        VStack {
            Text("设置")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
