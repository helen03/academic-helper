import Foundation

@MainActor
final class EventBus {
    static let shared = EventBus()
    
    private var subscribers: [String: [(any Event) -> Void]] = [:]
    private let lock = NSLock()
    
    private init() {}
    
    func subscribe<E: Event>(_ eventType: E.Type, handler: @escaping (E) -> Void) {
        let key = String(describing: eventType)
        lock.lock()
        if subscribers[key] == nil {
            subscribers[key] = []
        }
        subscribers[key]?.append { event in
            if let typedEvent = event as? E {
                handler(typedEvent)
            }
        }
        lock.unlock()
    }
    
    func publish<E: Event>(_ event: E) {
        let key = String(describing: type(of: event))
        lock.lock()
        let handlers = subscribers[key] ?? []
        lock.unlock()
        
        handlers.forEach { $0(event) }
    }
    
    func unsubscribe<E: Event>(_ eventType: E.Type) {
        let key = String(describing: eventType)
        lock.lock()
        subscribers.removeValue(forKey: key)
        lock.unlock()
    }
}

protocol Event {
    var timestamp: Date { get }
}

extension Event {
    var timestamp: Date { Date() }
}

enum AppEvents {
    enum Application: Event {
        case didFinishLaunching
        case willTerminate
        case didBecomeActive
        case willResignActive
    }
    
    enum WordCapture: Event {
        case wordCaptured(word: String, context: String?)
        case lookupStarted(word: String)
        case lookupCompleted(word: String, result: WordDefinition?)
        case lookupFailed(word: String, error: Error)
    }
    
    enum Vocabulary: Event {
        case wordAdded(word: Word)
        case wordUpdated(word: Word)
        case wordDeleted(wordID: UUID)
        case reviewDue(words: [Word])
    }
    
    enum Literature: Event {
        case documentImported(document: LiteratureDocument)
        case documentDeleted(documentID: UUID)
        case textExtracted(documentID: UUID, text: String)
        case wordLinked(wordID: UUID, documentID: UUID)
    }
    
    enum Expression: Event {
        case expressionRecognized(expression: AcademicExpression)
        case expressionSaved(expression: AcademicExpression)
        case expressionDeleted(expressionID: UUID)
    }
    
    enum Settings: Event {
        case settingsChanged(key: String, value: Any)
        case syncEnabled
        case syncDisabled
    }
}
