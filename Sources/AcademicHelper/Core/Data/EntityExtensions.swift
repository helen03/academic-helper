import Foundation
import CoreData

extension WordEntity {
    func toModel() -> Word {
        Word(
            id: id ?? UUID(),
            text: text ?? "",
            phonetic: phonetic,
            definition: definition,
            partOfSpeech: partOfSpeech,
            examples: examples as? [String] ?? [],
            difficulty: WordDifficulty(rawValue: difficulty) ?? .medium,
            source: source,
            createdAt: createdAt ?? Date(),
            lastReviewedAt: lastReviewedAt,
            nextReviewAt: nextReviewAt,
            reviewCount: Int(reviewCount),
            interval: Int(interval),
            easeFactor: easeFactor,
            linkedDocumentIDs: (documents?.allObjects as? [LiteratureDocumentEntity])?.compactMap { $0.id } ?? []
        )
    }

    func update(from word: Word) {
        id = word.id
        text = word.text
        phonetic = word.phonetic
        definition = word.definition
        partOfSpeech = word.partOfSpeech
        examples = word.examples as NSArray
        difficulty = word.difficulty.rawValue
        source = word.source
        createdAt = word.createdAt
        lastReviewedAt = word.lastReviewedAt
        nextReviewAt = word.nextReviewAt
        reviewCount = Int32(word.reviewCount)
        interval = Int32(word.interval)
        easeFactor = word.easeFactor
    }
}

extension LiteratureDocumentEntity {
    func toModel() -> LiteratureDocument {
        LiteratureDocument(
            id: id ?? UUID(),
            title: title ?? "",
            authors: authors as? [String] ?? [],
            abstract: abstract,
            filePath: filePath ?? "",
            fileSize: fileSize,
            pageCount: Int(pageCount),
            createdAt: createdAt ?? Date(),
            lastOpenedAt: lastOpenedAt,
            tags: tags as? [String] ?? [],
            linkedWordIDs: (words?.allObjects as? [WordEntity])?.compactMap { $0.id } ?? []
        )
    }

    func update(from document: LiteratureDocument) {
        id = document.id
        title = document.title
        authors = document.authors as NSArray
        abstract = document.abstract
        filePath = document.filePath
        fileSize = document.fileSize
        pageCount = Int32(document.pageCount)
        createdAt = document.createdAt
        lastOpenedAt = document.lastOpenedAt
        tags = document.tags as NSArray
    }
}

extension AcademicExpressionEntity {
    func toModel() -> AcademicExpression {
        AcademicExpression(
            id: id ?? UUID(),
            text: text ?? "",
            category: ExpressionCategory(rawValue: category ?? "") ?? .other,
            meaning: meaning,
            usage: usage,
            examples: examples as? [String] ?? [],
            alternatives: alternatives as? [String] ?? [],
            sourceDocument: sourceDocument,
            createdAt: createdAt ?? Date(),
            usageCount: Int(usageCount),
            isFavorite: isFavorite
        )
    }

    func update(from expression: AcademicExpression) {
        id = expression.id
        text = expression.text
        category = expression.category.rawValue
        meaning = expression.meaning
        usage = expression.usage
        examples = expression.examples as NSArray
        alternatives = expression.alternatives as NSArray
        sourceDocument = expression.sourceDocument
        createdAt = expression.createdAt
        usageCount = Int32(expression.usageCount)
        isFavorite = expression.isFavorite
    }
}
