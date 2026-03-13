import Foundation
import CoreData

@objc(WordEntity)
public class WordEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var text: String?
    @NSManaged public var phonetic: String?
    @NSManaged public var definition: String?
    @NSManaged public var partOfSpeech: String?
    @NSManaged public var examples: NSObject?
    @NSManaged public var difficulty: Int16
    @NSManaged public var source: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var lastReviewedAt: Date?
    @NSManaged public var nextReviewAt: Date?
    @NSManaged public var reviewCount: Int32
    @NSManaged public var interval: Int32
    @NSManaged public var easeFactor: Double
    @NSManaged public var documents: NSSet?
}

extension WordEntity {
    @objc(addDocumentsObject:)
    @NSManaged public func addToDocuments(_ value: LiteratureDocumentEntity)

    @objc(removeDocumentsObject:)
    @NSManaged public func removeFromDocuments(_ value: LiteratureDocumentEntity)

    @objc(addDocuments:)
    @NSManaged public func addToDocuments(_ values: NSSet)

    @objc(removeDocuments:)
    @NSManaged public func removeFromDocuments(_ values: NSSet)
}

@objc(LiteratureDocumentEntity)
public class LiteratureDocumentEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var authors: NSObject?
    @NSManaged public var abstract: String?
    @NSManaged public var filePath: String?
    @NSManaged public var fileSize: Int64
    @NSManaged public var pageCount: Int32
    @NSManaged public var createdAt: Date?
    @NSManaged public var lastOpenedAt: Date?
    @NSManaged public var tags: NSObject?
    @NSManaged public var words: NSSet?
}

extension LiteratureDocumentEntity {
    @objc(addWordsObject:)
    @NSManaged public func addToWords(_ value: WordEntity)

    @objc(removeWordsObject:)
    @NSManaged public func removeFromWords(_ value: WordEntity)

    @objc(addWords:)
    @NSManaged public func addToWords(_ values: NSSet)

    @objc(removeWords:)
    @NSManaged public func removeFromWords(_ values: NSSet)
}

@objc(AcademicExpressionEntity)
public class AcademicExpressionEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var text: String?
    @NSManaged public var category: String?
    @NSManaged public var meaning: String?
    @NSManaged public var usage: String?
    @NSManaged public var examples: NSObject?
    @NSManaged public var alternatives: NSObject?
    @NSManaged public var sourceDocument: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var usageCount: Int32
    @NSManaged public var isFavorite: Bool
}

@objc(UserSettingsEntity)
public class UserSettingsEntity: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var key: String?
    @NSManaged public var value: Data?
    @NSManaged public var updatedAt: Date?
}
