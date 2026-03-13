import Foundation
import CoreData

protocol LiteratureRepositoryProtocol {
    func fetchAllDocuments() async throws -> [LiteratureDocument]
    func fetchDocument(byID id: UUID) async throws -> LiteratureDocument?
    func saveDocument(_ document: LiteratureDocument) async throws
    func updateDocument(_ document: LiteratureDocument) async throws
    func deleteDocument(id: UUID) async throws
    func searchDocuments(query: String) async throws -> [LiteratureDocument]
    func linkWordToDocument(wordID: UUID, documentID: UUID) async throws
}

@MainActor
final class LiteratureRepository: LiteratureRepositoryProtocol {
    private let coreDataStack: CoreDataStack

    init(coreDataStack: CoreDataStack) {
        self.coreDataStack = coreDataStack
    }

    func fetchAllDocuments() async throws -> [LiteratureDocument] {
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<LiteratureDocumentEntity> = LiteratureDocumentEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        let entities = try context.fetch(request)
        return entities.map { $0.toModel() }
    }

    func fetchDocument(byID id: UUID) async throws -> LiteratureDocument? {
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<LiteratureDocumentEntity> = LiteratureDocumentEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        let entities = try context.fetch(request)
        return entities.first?.toModel()
    }

    func saveDocument(_ document: LiteratureDocument) async throws {
        let context = coreDataStack.viewContext
        let entity = LiteratureDocumentEntity(context: context)
        entity.update(from: document)
        coreDataStack.save()
    }

    func updateDocument(_ document: LiteratureDocument) async throws {
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<LiteratureDocumentEntity> = LiteratureDocumentEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", document.id as CVarArg)

        let entities = try context.fetch(request)
        if let entity = entities.first {
            entity.update(from: document)
            coreDataStack.save()
        }
    }

    func deleteDocument(id: UUID) async throws {
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<LiteratureDocumentEntity> = LiteratureDocumentEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        let entities = try context.fetch(request)
        entities.forEach { context.delete($0) }
        coreDataStack.save()
    }

    func searchDocuments(query: String) async throws -> [LiteratureDocument] {
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<LiteratureDocumentEntity> = LiteratureDocumentEntity.fetchRequest()
        request.predicate = NSPredicate(format: "title CONTAINS[c] %@ OR abstract CONTAINS[c] %@", query, query)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        let entities = try context.fetch(request)
        return entities.map { $0.toModel() }
    }

    func linkWordToDocument(wordID: UUID, documentID: UUID) async throws {
        let context = coreDataStack.viewContext

        let wordRequest: NSFetchRequest<WordEntity> = WordEntity.fetchRequest()
        wordRequest.predicate = NSPredicate(format: "id == %@", wordID as CVarArg)

        let docRequest: NSFetchRequest<LiteratureDocumentEntity> = LiteratureDocumentEntity.fetchRequest()
        docRequest.predicate = NSPredicate(format: "id == %@", documentID as CVarArg)

        let words = try context.fetch(wordRequest)
        let docs = try context.fetch(docRequest)

        if let word = words.first, let doc = docs.first {
            word.addToDocuments(doc)
            coreDataStack.save()
        }
    }
}
