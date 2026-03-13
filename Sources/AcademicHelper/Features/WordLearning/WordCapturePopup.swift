import SwiftUI

struct WordCapturePopup: View {
    let word: String
    let definition: WordDefinition?
    let isLoading: Bool
    let onAddToVocabulary: () -> Void
    let onDismiss: () -> Void
    let onViewDetails: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(word)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
            
            // Phonetic
            if let phonetic = definition?.phonetic {
                Text(phonetic)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Divider()
            
            // Content
            if isLoading {
                ProgressView("查询中...")
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else if let definition = definition {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(definition.meanings.prefix(2), id: \.partOfSpeech) { meaning in
                            MeaningView(meaning: meaning)
                        }
                    }
                }
                .frame(maxHeight: 200)
            } else {
                Text("未找到释义")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 100)
            }
            
            Divider()
            
            // Actions
            HStack(spacing: 12) {
                Button(action: onViewDetails) {
                    Label("查看详情", systemImage: "doc.text")
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button(action: onAddToVocabulary) {
                    Label("加入生词本", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading || definition == nil)
            }
        }
        .padding()
        .frame(width: 350)
        .background(.background)
        .cornerRadius(12)
        .shadow(radius: 8)
    }
}

struct MeaningView: View {
    let meaning: WordDefinition.Meaning
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(meaning.partOfSpeech)
                .font(.caption)
                .foregroundStyle(.blue)
                .fontWeight(.medium)
            
            ForEach(meaning.definitions.prefix(2), id: \.definition) { def in
                VStack(alignment: .leading, spacing: 2) {
                    Text("• \(def.definition)")
                        .font(.subheadline)
                    
                    if let example = def.example {
                        Text("\"\(example)\"")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .italic()
                            .padding(.leading, 12)
                    }
                }
            }
        }
    }
}

// Floating popup window for word capture
class WordCaptureWindowController: NSWindowController {
    private let viewModel: WordCaptureViewModel
    
    init(word: String) {
        self.viewModel = WordCaptureViewModel(word: word)
        
        let window = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 350, height: 300),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        window.isFloatingPanel = true
        window.level = .popUpMenu
        window.backgroundColor = .clear
        window.hasShadow = true
        window.isOpaque = false
        
        super.init(window: window)
        
        let contentView = WordCapturePopup(
            word: word,
            definition: viewModel.definition,
            isLoading: viewModel.isLoading,
            onAddToVocabulary: { [weak self] in
                self?.viewModel.addToVocabulary()
                self?.close()
            },
            onDismiss: { [weak self] in
                self?.close()
            },
            onViewDetails: { [weak self] in
                self?.viewModel.viewDetails()
                self?.close()
            }
        )
        
        window.contentView = NSHostingView(rootView: contentView)
        
        // Position window near mouse cursor
        if let screen = NSScreen.main {
            let mouseLocation = NSEvent.mouseLocation
            let windowFrame = window.frame
            let screenFrame = screen.visibleFrame
            
            var x = mouseLocation.x - windowFrame.width / 2
            var y = mouseLocation.y - windowFrame.height - 10
            
            // Keep within screen bounds
            x = max(screenFrame.minX, min(x, screenFrame.maxX - windowFrame.width))
            y = max(screenFrame.minY, min(y, screenFrame.maxY - windowFrame.height))
            
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        // Load definition
        Task {
            await viewModel.loadDefinition()
            updateContent()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateContent() {
        guard let window = window else { return }
        
        let contentView = WordCapturePopup(
            word: viewModel.word,
            definition: viewModel.definition,
            isLoading: viewModel.isLoading,
            onAddToVocabulary: { [weak self] in
                self?.viewModel.addToVocabulary()
                self?.close()
            },
            onDismiss: { [weak self] in
                self?.close()
            },
            onViewDetails: { [weak self] in
                self?.viewModel.viewDetails()
                self?.close()
            }
        )
        
        window.contentView = NSHostingView(rootView: contentView)
    }
}

@MainActor
class WordCaptureViewModel: ObservableObject {
    let word: String
    @Published var definition: WordDefinition?
    @Published var isLoading = true
    
    @Inject private var dictionaryService: DictionaryServiceProtocol
    @Inject private var wordRepository: WordRepositoryProtocol
    @Inject private var eventBus: EventBus
    
    init(word: String) {
        self.word = word
    }
    
    func loadDefinition() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            definition = try await dictionaryService.lookup(word: word)
        } catch {
            print("Failed to load definition: \(error)")
        }
    }
    
    func addToVocabulary() {
        guard let definition = definition else { return }
        
        let word = Word(
            text: self.word,
            phonetic: definition.phonetic,
            definition: definition.meanings.first?.definitions.first?.definition,
            partOfSpeech: definition.meanings.first?.partOfSpeech,
            examples: definition.meanings.flatMap { $0.definitions.compactMap { $0.example } },
            source: "屏幕取词"
        )
        
        Task {
            do {
                try await wordRepository.saveWord(word)
                eventBus.publish(AppEvents.Vocabulary.wordAdded(word: word))
            } catch {
                print("Failed to save word: \(error)")
            }
        }
    }
    
    func viewDetails() {
        // Navigate to word detail view
        eventBus.publish(AppEvents.WordCapture.lookupCompleted(word: word, result: definition))
    }
}
