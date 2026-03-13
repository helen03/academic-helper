import Foundation
import CloudKit
import CoreData

@MainActor
protocol SyncServiceProtocol {
    func enableSync() async throws
    func disableSync()
    func syncNow() async throws
    var syncStatus: SyncStatus { get }
    var lastSyncDate: Date? { get }
}

enum SyncStatus: String {
    case disabled = "未启用"
    case syncing = "同步中"
    case synced = "已同步"
    case error = "同步错误"
    case offline = "离线"
}

@MainActor
final class SyncService: SyncServiceProtocol {
    static let shared = SyncService()
    
    @Published private(set) var syncStatus: SyncStatus = .disabled
    @Published private(set) var lastSyncDate: Date?
    @Published private(set) var syncError: Error?
    
    private let container: CKContainer
    private let privateDatabase: CKDatabase
    private var isSyncEnabled = false
    private var syncTimer: Timer?
    
    @Inject private var coreDataStack: CoreDataStack
    
    private init() {
        container = CKContainer.default()
        privateDatabase = container.privateCloudDatabase
        
        setupCloudKitSubscription()
    }
    
    func enableSync() async throws {
        // Check iCloud account status
        let accountStatus = try await container.accountStatus()
        
        guard accountStatus == .available else {
            throw SyncError.iCloudNotAvailable
        }
        
        isSyncEnabled = true
        syncStatus = .synced
        
        // Perform initial sync
        try await syncNow()
        
        // Setup periodic sync
        setupPeriodicSync()
        
        // Setup remote change notification
        setupRemoteChangeNotification()
    }
    
    func disableSync() {
        isSyncEnabled = false
        syncStatus = .disabled
        syncTimer?.invalidate()
        syncTimer = nil
    }
    
    func syncNow() async throws {
        guard isSyncEnabled else { return }
        
        syncStatus = .syncing
        
        do {
            // Sync words
            try await syncWords()
            
            // Sync literature
            try await syncLiterature()
            
            // Sync expressions
            try await syncExpressions()
            
            await MainActor.run {
                self.lastSyncDate = Date()
                self.syncStatus = .synced
            }
        } catch {
            await MainActor.run {
                self.syncError = error
                self.syncStatus = .error
            }
            throw error
        }
    }
    
    private func syncWords() async throws {
        let context = coreDataStack.viewContext
        
        // Fetch local changes
        let fetchRequest: NSFetchRequest<WordEntity> = WordEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "needsSync == YES")
        
        let localChanges = try context.fetch(fetchRequest)
        
        // Upload local changes to CloudKit
        for wordEntity in localChanges {
            let record = try createWordRecord(from: wordEntity)
            let (_, _) = try await privateDatabase.modifyRecords(saving: [record], deleting: [])
            wordEntity.setValue(false, forKey: "needsSync")
        }
        
        // Fetch remote changes
        let query = CKQuery(recordType: "Word", predicate: NSPredicate(value: true))
        let (results, _) = try await privateDatabase.records(matching: query)
        
        // Merge remote changes
        for (_, result) in results {
            switch result {
            case .success(let record):
                try await mergeWordRecord(record, context: context)
            case .failure(let error):
                print("Failed to fetch word record: \(error)")
            }
        }
        
        coreDataStack.save()
    }
    
    private func syncLiterature() async throws {
        // Similar implementation for literature
    }
    
    private func syncExpressions() async throws {
        // Similar implementation for expressions
    }
    
    private func createWordRecord(from entity: WordEntity) throws -> CKRecord {
        let record = CKRecord(recordType: "Word")
        record["text"] = entity.text
        record["phonetic"] = entity.phonetic
        record["definition"] = entity.definition
        record["partOfSpeech"] = entity.partOfSpeech
        record["difficulty"] = entity.difficulty
        record["createdAt"] = entity.createdAt
        record["lastReviewedAt"] = entity.lastReviewedAt
        record["nextReviewAt"] = entity.nextReviewAt
        record["reviewCount"] = entity.reviewCount
        record["interval"] = entity.interval
        record["easeFactor"] = entity.easeFactor
        
        return record
    }
    
    private func mergeWordRecord(_ record: CKRecord, context: NSManagedObjectContext) async throws {
        let fetchRequest: NSFetchRequest<WordEntity> = WordEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", record.recordID.recordName)
        
        let existing = try context.fetch(fetchRequest)
        
        if let entity = existing.first {
            // Update existing record
            entity.text = record["text"] as? String
            entity.phonetic = record["phonetic"] as? String
            entity.definition = record["definition"] as? String
            // ... update other fields
        } else {
            // Create new record
            let newEntity = WordEntity(context: context)
            newEntity.id = UUID(uuidString: record.recordID.recordName)
            newEntity.text = record["text"] as? String
            newEntity.phonetic = record["phonetic"] as? String
            newEntity.definition = record["definition"] as? String
            // ... set other fields
        }
    }
    
    private func setupPeriodicSync() {
        syncTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task {
                try? await self?.syncNow()
            }
        }
    }
    
    private func setupRemoteChangeNotification() {
        // Setup notification for remote changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRemoteChange),
            name: NSPersistentCloudKitContainer.eventChangedNotification,
            object: nil
        )
    }
    
    @objc private func handleRemoteChange(_ notification: Notification) {
        guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                as? NSPersistentCloudKitContainer.Event else {
            return
        }
        
        switch event.type {
        case .import:
            print("CloudKit import completed")
        case .export:
            print("CloudKit export completed")
        case .setup:
            print("CloudKit setup completed")
        @unknown default:
            break
        }
    }
    
    private func setupCloudKitSubscription() {
        // Setup subscription for remote notifications
    }
}

enum SyncError: Error {
    case iCloudNotAvailable
    case syncFailed(Error)
    case conflictResolutionFailed
    case networkError
}
