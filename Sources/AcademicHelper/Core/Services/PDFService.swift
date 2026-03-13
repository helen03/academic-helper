import Foundation
import PDFKit
import NaturalLanguage

@MainActor
protocol PDFServiceProtocol {
    func importDocument(from url: URL) async throws -> LiteratureDocument
    func extractText(from document: LiteratureDocument) async throws -> [ExtractedText]
    func extractMetadata(from url: URL) async throws -> DocumentMetadata
    func getPDFDocument(from document: LiteratureDocument) -> PDFDocument?
    func searchInPDF(document: LiteratureDocument, query: String) async throws -> [PDFSearchResult]
    func extractTextWithExpressionRecognition(from document: LiteratureDocument) async throws -> PDFAnalysisResult
}

@MainActor
final class PDFService: PDFServiceProtocol {
    
    private let expressionService: ExpressionRecognitionServiceProtocol
    
    init(expressionService: ExpressionRecognitionServiceProtocol = ExpressionRecognitionService()) {
        self.expressionService = expressionService
    }
    
    // MARK: - Document Import
    
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
    
    // MARK: - Text Extraction
    
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
    
    // MARK: - PDF Search
    
    func searchInPDF(document: LiteratureDocument, query: String) async throws -> [PDFSearchResult] {
        guard let pdfDocument = getPDFDocument(from: document) else {
            throw PDFError.invalidPDF
        }
        
        var results: [PDFSearchResult] = []
        let searchText = query.lowercased()
        
        for pageIndex in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: pageIndex),
                  let pageText = page.string else { continue }
            
            let lowerPageText = pageText.lowercased()
            
            // 查找所有匹配位置
            var searchRange = lowerPageText.startIndex..<lowerPageText.endIndex
            while let range = lowerPageText.range(of: searchText, range: searchRange) {
                let startIndex = lowerPageText.distance(from: lowerPageText.startIndex, to: range.lowerBound)
                
                // 获取上下文
                let contextStart = max(0, startIndex - 50)
                let contextEnd = min(pageText.count, startIndex + searchText.count + 50)
                let contextStartIndex = pageText.index(pageText.startIndex, offsetBy: contextStart)
                let contextEndIndex = pageText.index(pageText.startIndex, offsetBy: contextEnd)
                let context = String(pageText[contextStartIndex..<contextEndIndex])
                
                let result = PDFSearchResult(
                    id: UUID(),
                    documentID: document.id,
                    pageNumber: pageIndex + 1,
                    matchText: query,
                    context: context,
                    characterRange: NSRange(location: startIndex, length: searchText.count)
                )
                results.append(result)
                
                searchRange = range.upperBound..<lowerPageText.endIndex
            }
        }
        
        return results
    }
    
    // MARK: - Expression Recognition in PDF
    
    func extractTextWithExpressionRecognition(from document: LiteratureDocument) async throws -> PDFAnalysisResult {
        let extractedTexts = try await extractText(from: document)
        
        var allExpressions: [RecognizedExpression] = []
        var pageAnalyses: [PageAnalysis] = []
        
        for extractedText in extractedTexts {
            let expressions = expressionService.recognizeExpressions(in: extractedText.text)
            
            let pageExpressions = expressions.map { expression -> RecognizedExpression in
                RecognizedExpression(
                    id: UUID(),
                    documentID: document.id,
                    pageNumber: extractedText.pageNumber,
                    expression: expression,
                    context: extractContext(for: expression, in: extractedText.text)
                )
            }
            
            allExpressions.append(contentsOf: pageExpressions)
            
            let pageAnalysis = PageAnalysis(
                pageNumber: extractedText.pageNumber,
                textLength: extractedText.text.count,
                expressionCount: pageExpressions.count,
                expressions: pageExpressions
            )
            pageAnalyses.append(pageAnalysis)
        }
        
        // 统计表达类型
        let expressionTypeCounts = Dictionary(grouping: allExpressions) { $0.expression.type }
            .mapValues { $0.count }
        
        return PDFAnalysisResult(
            documentID: document.id,
            totalPages: extractedTexts.count,
            totalExpressions: allExpressions.count,
            expressionTypeCounts: expressionTypeCounts,
            pageAnalyses: pageAnalyses,
            allExpressions: allExpressions
        )
    }
    
    // MARK: - Metadata Extraction
    
    func extractMetadata(from url: URL) async throws -> DocumentMetadata {
        guard let pdfDocument = PDFDocument(url: url) else {
            throw PDFError.invalidPDF
        }
        
        let documentAttributes = pdfDocument.documentAttributes
        
        let title = documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String
        let author = documentAttributes?[PDFDocumentAttribute.authorAttribute] as? String
        let keywords = documentAttributes?[PDFDocumentAttribute.keywordsAttribute] as? String
        let creationDate = documentAttributes?[PDFDocumentAttribute.creationDateAttribute] as? Date
        
        // 尝试从第一页提取更多元数据
        var abstract: String?
        if let firstPage = pdfDocument.page(at: 0),
           let text = firstPage.string {
            abstract = extractAbstract(from: text)
        }
        
        return DocumentMetadata(
            title: title,
            authors: author?.components(separatedBy: ", ").map { $0.trimmingCharacters(in: .whitespaces) },
            abstract: abstract,
            keywords: keywords?.components(separatedBy: ", "),
            publicationDate: creationDate,
            doi: extractDOI(from: pdfDocument),
            journal: nil
        )
    }
    
    func getPDFDocument(from document: LiteratureDocument) -> PDFDocument? {
        let fileURL = URL(fileURLWithPath: document.filePath)
        return PDFDocument(url: fileURL)
    }
    
    // MARK: - Private Helpers
    
    private func extractContext(for expression: AcademicExpression, in text: String, contextLength: Int = 100) -> String {
        guard let range = text.range(of: expression.text) else {
            return text.prefix(contextLength).description
        }
        
        let start = text.index(range.lowerBound, offsetBy: -contextLength, limitedBy: text.startIndex) ?? text.startIndex
        let end = text.index(range.upperBound, offsetBy: contextLength, limitedBy: text.endIndex) ?? text.endIndex
        
        return String(text[start..<end])
    }
    
    private func extractAbstract(from text: String) -> String? {
        // 尝试找到 Abstract 部分
        let patterns = [
            "Abstract",
            "ABSTRACT",
            "摘要"
        ]
        
        for pattern in patterns {
            if let range = text.range(of: pattern) {
                let start = range.upperBound
                let end = text.index(start, offsetBy: min(500, text.distance(from: start, to: text.endIndex)))
                return String(text[start..<end]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        // 如果没有找到 Abstract，返回前 200 个字符
        return String(text.prefix(200))
    }
    
    private func extractDOI(from document: PDFDocument) -> String? {
        // 尝试从文档中提取 DOI
        let doiPattern = "10\\.\\d{4,}\\/[^\\s]+"
        
        for pageIndex in 0..<min(document.pageCount, 3) { // 只检查前 3 页
            guard let page = document.page(at: pageIndex),
                  let text = page.string else { continue }
            
            if let match = text.range(of: doiPattern, options: .regularExpression) {
                return String(text[match])
            }
        }
        
        return nil
    }
}

// MARK: - Models

struct PDFSearchResult: Identifiable {
    let id: UUID
    let documentID: UUID
    let pageNumber: Int
    let matchText: String
    let context: String
    let characterRange: NSRange
}

struct RecognizedExpression: Identifiable {
    let id: UUID
    let documentID: UUID
    let pageNumber: Int
    let expression: AcademicExpression
    let context: String
}

struct PageAnalysis {
    let pageNumber: Int
    let textLength: Int
    let expressionCount: Int
    let expressions: [RecognizedExpression]
}

struct PDFAnalysisResult {
    let documentID: UUID
    let totalPages: Int
    let totalExpressions: Int
    let expressionTypeCounts: [AcademicExpression.ExpressionType: Int]
    let pageAnalyses: [PageAnalysis]
    let allExpressions: [RecognizedExpression]
}

enum PDFError: Error, LocalizedError {
    case fileNotFound
    case invalidPDF
    case extractionFailed
    case permissionDenied
    case searchFailed
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "文件未找到"
        case .invalidPDF:
            return "无效的 PDF 文件"
        case .extractionFailed:
            return "文本提取失败"
        case .permissionDenied:
            return "没有权限访问文件"
        case .searchFailed:
            return "搜索失败"
        }
    }
}
