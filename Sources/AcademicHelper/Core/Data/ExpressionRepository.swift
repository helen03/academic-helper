import Foundation
import CoreData

protocol ExpressionRepositoryProtocol {
    func fetchAllExpressions() async throws -> [AcademicExpression]
    func fetchExpressions(byCategory category: ExpressionCategory) async throws -> [AcademicExpression]
    func fetchFavoriteExpressions() async throws -> [AcademicExpression]
    func saveExpression(_ expression: AcademicExpression) async throws
    func updateExpression(_ expression: AcademicExpression) async throws
    func deleteExpression(id: UUID) async throws
    func searchExpressions(query: String) async throws -> [AcademicExpression]
}

@MainActor
final class ExpressionRepository: ExpressionRepositoryProtocol {
    private let coreDataStack: CoreDataStack

    init(coreDataStack: CoreDataStack) {
        self.coreDataStack = coreDataStack
    }

    func fetchAllExpressions() async throws -> [AcademicExpression] {
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<AcademicExpressionEntity> = AcademicExpressionEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        let entities = try context.fetch(request)
        return entities.map { $0.toModel() }
    }

    func fetchExpressions(byCategory category: ExpressionCategory) async throws -> [AcademicExpression] {
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<AcademicExpressionEntity> = AcademicExpressionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "category == %@", category.rawValue)
        request.sortDescriptors = [NSSortDescriptor(key: "usageCount", ascending: false)]

        let entities = try context.fetch(request)
        return entities.map { $0.toModel() }
    }

    func fetchFavoriteExpressions() async throws -> [AcademicExpression] {
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<AcademicExpressionEntity> = AcademicExpressionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isFavorite == %@", NSNumber(value: true))
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        let entities = try context.fetch(request)
        return entities.map { $0.toModel() }
    }

    func saveExpression(_ expression: AcademicExpression) async throws {
        let context = coreDataStack.viewContext
        let entity = AcademicExpressionEntity(context: context)
        entity.update(from: expression)
        coreDataStack.save()
    }

    func updateExpression(_ expression: AcademicExpression) async throws {
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<AcademicExpressionEntity> = AcademicExpressionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", expression.id as CVarArg)

        let entities = try context.fetch(request)
        if let entity = entities.first {
            entity.update(from: expression)
            coreDataStack.save()
        }
    }

    func deleteExpression(id: UUID) async throws {
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<AcademicExpressionEntity> = AcademicExpressionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)

        let entities = try context.fetch(request)
        entities.forEach { context.delete($0) }
        coreDataStack.save()
    }

    func searchExpressions(query: String) async throws -> [AcademicExpression] {
        let context = coreDataStack.viewContext
        let request: NSFetchRequest<AcademicExpressionEntity> = AcademicExpressionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "text CONTAINS[c] %@ OR meaning CONTAINS[c] %@", query, query)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        let entities = try context.fetch(request)
        return entities.map { $0.toModel() }
    }
}
