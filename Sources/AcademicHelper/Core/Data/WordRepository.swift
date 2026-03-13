import Foundation
import CoreData

protocol WordRepositoryProtocol {
    func fetchAllWords() async throws -> [Word]
    func fetchWordsDueForReview() async throws -> [Word]
    func fetchWord(byID id: UUID) async throws -> Word?
    func fetchWord(byText text: String) async throws -> Word?
    func saveWord(_ word: Word) async throws
    func updateWord(_ word: Word) async throws
    func deleteWord(id: UUID) async throws
    func searchWords(query: String) async throws -> [Word]
    func linkWordToDocument(wordID: UUID, documentID: UUID) async throws
}

@MainActor
final class WordRepository: WordRepositoryProtocol {
    private let coreDataStack: CoreDataStack

    init(coreDataStack: CoreDataStack) {
        self.coreDataStack = coreDataStack
    }

    func fetchAllWords() async throws -> [Word] {
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<WordEntity> = WordEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        let entities = try context.fetch(request)
        return entities.map { $0.toModel() }
    }

    func fetchWordsDueForReview() async throws -> [Word] {
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<WordEntity> = WordEntity.fetchRequest()
        request.predicate = NSPredicate(format: "nextReviewAt <= %@ OR nextReviewAt == nil", Date() as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "nextReviewAt", ascending: true)]

        let entities = try context.fetch(request)
        return entities.map { $0.toModel() }
    }

    func fetchWord(byID id: UUID) async throws -> Word? {
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<WordEntity> = WordEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        let entities = try context.fetch(request)
        return entities.first?.toModel()
    }

    func fetchWord(byText text: String) async throws -> Word? {
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<WordEntity> = WordEntity.fetchRequest()
        request.predicate = NSPredicate(format: "text ==[c] %@", text)
        request.fetchLimit = 1

        let entities = try context.fetch(request)
        return entities.first?.toModel()
    }

    func saveWord(_ word: Word) async throws {
        let context = coreDataStack.viewContext
        let entity = WordEntity(context: context)
        entity.update(from: word)
        coreDataStack.save()
    }

    func updateWord(_ word: Word) async throws {
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<WordEntity> = WordEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", word.id as CVarArg)

        let entities = try context.fetch(request)
        if let entity = entities.first {
            entity.update(from: word)
            coreDataStack.save()
        }
    }

    func deleteWord(id: UUID) async throws {
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<WordEntity> = WordEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        let entities = try context.fetch(request)
        entities.forEach { context.delete($0) }
        coreDataStack.save()
    }

    func searchWords(query: String) async throws -> [Word] {
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<WordEntity> = WordEntity.fetchRequest()
        request.predicate = NSPredicate(format: "text CONTAINS[c] %@ OR definition CONTAINS[c] %@", query, query)
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
