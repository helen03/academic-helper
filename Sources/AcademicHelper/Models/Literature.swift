import Foundation

struct LiteratureDocument: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var authors: [String]
    var abstract: String?
    var filePath: String
    var fileSize: Int64
    var pageCount: Int
    let createdAt: Date
    var lastOpenedAt: Date?
    var tags: [String]
    var linkedWordIDs: [UUID]
    
    init(
        id: UUID = UUID(),
        title: String,
        authors: [String] = [],
        abstract: String? = nil,
        filePath: String,
        fileSize: Int64 = 0,
        pageCount: Int = 0,
        createdAt: Date = Date(),
        lastOpenedAt: Date? = nil,
        tags: [String] = [],
        linkedWordIDs: [UUID] = []
    ) {
        self.id = id
        self.title = title
        self.authors = authors
        self.abstract = abstract
        self.filePath = filePath
        self.fileSize = fileSize
        self.pageCount = pageCount
        self.createdAt = createdAt
        self.lastOpenedAt = lastOpenedAt
        self.tags = tags
        self.linkedWordIDs = linkedWordIDs
    }
}

struct ExtractedText: Identifiable {
    let id: UUID
    let documentID: UUID
    let pageNumber: Int
    let text: String
    let boundingBox: CGRect?
    let confidence: Double?
}

struct DocumentMetadata: Codable {
    let title: String?
    let authors: [String]?
    let abstract: String?
    let keywords: [String]?
    let publicationDate: Date?
    let doi: String?
    let journal: String?
}
