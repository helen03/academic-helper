import Foundation

@MainActor
final class ServiceContainer {
    static let shared = ServiceContainer()
    
    private var services: [String: Any] = [:]
    private let lock = NSLock()
    
    private init() {}
    
    func initialize() {
        registerCoreServices()
        registerDataServices()
        registerFeatureServices()
    }
    
    private func registerCoreServices() {
        register(EventBus.shared, as: EventBus.self)
        register(NotificationManager.shared, as: NotificationManager.self)
        register(PermissionManager.shared, as: PermissionManager.self)
    }
    
    private func registerDataServices() {
        let coreDataStack = CoreDataStack()
        register(coreDataStack, as: CoreDataStack.self)
        
        let wordRepository = WordRepository(coreDataStack: coreDataStack)
        register(wordRepository, as: WordRepositoryProtocol.self)
        
        let literatureRepository = LiteratureRepository(coreDataStack: coreDataStack)
        register(literatureRepository, as: LiteratureRepositoryProtocol.self)
        
        let expressionRepository = ExpressionRepository(coreDataStack: coreDataStack)
        register(expressionRepository, as: ExpressionRepositoryProtocol.self)
    }
    
    private func registerFeatureServices() {
        let wordCaptureService = WordCaptureService(
            permissionManager: resolve(PermissionManager.self)!
        )
        register(wordCaptureService, as: WordCaptureServiceProtocol.self)
        
        let dictionaryService = DictionaryService()
        register(dictionaryService, as: DictionaryServiceProtocol.self)
        
        let srsService = SRSService(wordRepository: resolve(WordRepositoryProtocol.self)!)
        register(srsService, as: SRSServiceProtocol.self)
        
        let pdfService = PDFService()
        register(pdfService, as: PDFServiceProtocol.self)
        
        let expressionRecognitionService = ExpressionRecognitionService()
        register(expressionRecognitionService, as: ExpressionRecognitionServiceProtocol.self)
    }
    
    func register<T>(_ service: T, as type: T.Type) {
        let key = String(describing: type)
        lock.lock()
        services[key] = service
        lock.unlock()
    }
    
    func resolve<T>(_ type: T.Type) -> T? {
        let key = String(describing: type)
        lock.lock()
        let service = services[key] as? T
        lock.unlock()
        return service
    }
}

@propertyWrapper
struct Inject<T> {
    var wrappedValue: T
    
    init() {
        guard let service = ServiceContainer.shared.resolve(T.self) else {
            fatalError("Failed to resolve dependency: \(String(describing: T.self))")
        }
        self.wrappedValue = service
    }
}
