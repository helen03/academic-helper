import Foundation
import PDFKit

@MainActor
protocol PDFServiceProtocol {
    func importDocument(from url: URL) async throws -> LiteratureDocument
    func extractText(from document: LiteratureDocument) async throws -> [ExtractedText]
    func extractMetadata(from url: URL) async throws -> DocumentMetadata
    func getPDFDocument(from document: LiteratureDocument) -> PDFDocument?
}

@MainActor
final class PDFService: PDFServiceProtocol {
    
    func importDocument(from url: URL) async throws -> LiteratureDocument {
        let fileManager = FileManager.default
        
        guard fileManager.fileExists(atPath: url.path) else {
            throw PDFError.fileNotFound
        }
        
        let attributes = try fileManager.attributesOfItem(atPath: url.path)
        let fileSize = attributes[.size] as? Int64 ?? 0
        
        guard let pdfDocument = PDFDocument(url: url) else {
            throw PDFError.invalidPDF
        }
        
        let pageCount = pdfDocument.pageCount
        let metadata = try await extractMetadata(from: url)
        
        return LiteratureDocument(
            title: metadata.title ?? url.deletingPathExtension().lastPathComponent,
            authors: metadata.authors ?? [],
            abstract: metadata.abstract,
            filePath: url.path,
            fileSize: fileSize,
            pageCount: pageCount,
            tags: metadata.keywords ?? []
        )
    }
    
    func extractText(from document: LiteratureDocument) async throws -> [ExtractedText] {
        guard let pdfDocument = getPDFDocument(from: document) else {
            throw PDFError.invalidPDF
        }
        
        var extractedTexts: [ExtractedText] = []
        
        for pageIndex in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: pageIndex) else { continue }
            
            if let pageText = page.string, !pageText.isEmpty {
                let extractedText = ExtractedText(
                    id: UUID(),
                    documentID: document.id,
                    pageNumber: pageIndex + 1,
                    text: pageText,
                    boundingBox: nil,
                    confidence: 1.0
                )
                extractedTexts.append(extractedText)
            }
        }
        
        return extractedTexts
    }
    
    func extractMetadata(from url: URL) async throws -> DocumentMetadata {
        guard let pdfDocument = PDFDocument(url: url) else {
            throw PDFError.invalidPDF
        }
        
        let documentAttributes = pdfDocument.documentAttributes
        
        let title = documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String
        let author = documentAttributes?[PDFDocumentAttribute.authorAttribute] as? String
        let keywords = documentAttributes?[PDFDocumentAttribute.keywordsAttribute] as? String
        
        return DocumentMetadata(
            title: title,
            authors: author?.components(separatedBy: ", ").map { $0.trimmingCharacters(in: .whitespaces) },
            abstract: nil,
            keywords: keywords?.components(separatedBy: ", "),
            publicationDate: nil,
            doi: nil,
            journal: nil
        )
    }
    
    func getPDFDocument(from document: LiteratureDocument) -> PDFDocument? {
        let fileURL = URL(fileURLWithPath: document.filePath)
        return PDFDocument(url: fileURL)
    }
}

enum PDFError: Error {
    case fileNotFound
    case invalidPDF
    case extractionFailed
    case permissionDenied
}
