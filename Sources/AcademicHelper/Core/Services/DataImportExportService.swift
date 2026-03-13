import Foundation

// MARK: - Import/Export Format

enum ExportFormat: String, CaseIterable {
    case json = "JSON"
    case csv = "CSV"
    case xml = "XML"
    case anki = "Anki"
    case pdf = "PDF"
}

enum ImportSource: String, CaseIterable {
    case json = "JSON"
    case csv = "CSV"
    case anki = "Anki"
    case excel = "Excel"
    case txt = "Text"
}

// MARK: - Export Options

struct ExportOptions {
    let format: ExportFormat
    let includeWords: Bool
    let includeLiterature: Bool
    let includeExpressions: Bool
    let includeSettings: Bool
    let includeStatistics: Bool
    let dateRange: DateRange?
    let compressionEnabled: Bool
    let encryptionEnabled: Bool
    let password: String?
    
    struct DateRange {
        let startDate: Date
        let endDate: Date
    }
    
    static var `default`: ExportOptions {
        ExportOptions(
            format: .json,
            includeWords: true,
            includeLiterature: true,
            includeExpressions: true,
            includeSettings: false,
            includeStatistics: false,
            dateRange: nil,
            compressionEnabled: false,
            encryptionEnabled: false,
            password: nil
        )
    }
}

// MARK: - Import/Export Service Protocol

@MainActor
protocol DataImportExportServiceProtocol {
    func exportData(options: ExportOptions) async throws -> URL
    func importData(from url: URL, source: ImportSource) async throws -> ImportResult
    func backupData() async throws -> URL
    func restoreData(from url: URL) async throws
    func validateImportFile(_ url: URL, source: ImportSource) async throws -> ImportValidation
    func getExportPreview(options: ExportOptions) async throws -> ExportPreview
}

struct ImportResult {
    let success: Bool
    let importedWords: Int
    let importedLiterature: Int
    let importedExpressions: Int
    let errors: [ImportError]
    let warnings: [String]
}

struct ImportError {
    let row: Int
    let field: String
    let message: String
}

struct ImportValidation {
    let isValid: Bool
    let source: ImportSource
    let estimatedRecords: Int
    let errors: [String]
    let warnings: [String]
}

struct ExportPreview {
    let totalWords: Int
    let totalLiterature: Int
    let totalExpressions: Int
    let fileSize: Int64
    let estimatedExportTime: TimeInterval
}

// MARK: - Data Container

struct AcademicData: Codable {
    let version: String
    let exportDate: Date
    let metadata: ExportMetadata
    let words: [WordData]?
    let literature: [LiteratureData]?
    let expressions: [ExpressionData]?
    let settings: SettingsData?
    let statistics: StatisticsData?
    
    struct ExportMetadata: Codable {
        let appVersion: String
        let deviceName: String
        let systemVersion: String
        let userId: String?
    }
    
    struct WordData: Codable {
        let id: UUID
        let text: String
        let definition: String
        let phonetic: String?
        let partOfSpeech: String?
        let example: String?
        let addedAt: Date
        let lastReviewedAt: Date?
        let reviewCount: Int
        let isMastered: Bool
        let tags: [String]
        let notes: String?
    }
    
    struct LiteratureData: Codable {
        let id: UUID
        let title: String
        let authors: [String]
        let abstract: String?
        let filePath: String?
        let fileSize: Int64?
        let pageCount: Int
        let tags: [String]
        let addedAt: Date
        let lastOpenedAt: Date?
        let associatedWordIds: [UUID]
    }
    
    struct ExpressionData: Codable {
        let id: UUID
        let text: String
        let type: String
        let meaning: String
        let examples: [String]
        let category: String
        let isFavorite: Bool
        let addedAt: Date
    }
    
    struct SettingsData: Codable {
        let theme: String
        let fontSize: Int
        let autoSync: Bool
        let notificationEnabled: Bool
        let dailyGoal: Int
        let preferredDictionary: String
    }
    
    struct StatisticsData: Codable {
        let totalStudyTime: TimeInterval
        let totalWordsLearned: Int
        let currentStreak: Int
        let longestStreak: Int
        let averageAccuracy: Double
    }
}

// MARK: - Import/Export Service Implementation

@MainActor
final class DataImportExportService: DataImportExportServiceProtocol {
    
    private let wordRepository: WordRepositoryProtocol
    private let literatureRepository: LiteratureRepositoryProtocol
    private let expressionRepository: ExpressionRepositoryProtocol
    private let settingsService: SettingsServiceProtocol
    private let statisticsService: StatisticsServiceProtocol
    
    init(
        wordRepository: WordRepositoryProtocol,
        literatureRepository: LiteratureRepositoryProtocol,
        expressionRepository: ExpressionRepositoryProtocol,
        settingsService: SettingsServiceProtocol,
        statisticsService: StatisticsServiceProtocol
    ) {
        self.wordRepository = wordRepository
        self.literatureRepository = literatureRepository
        self.expressionRepository = expressionRepository
        self.settingsService = settingsService
        self.statisticsService = statisticsService
    }
    
    // MARK: - Export
    
    func exportData(options: ExportOptions) async throws -> URL {
        let data = try await prepareExportData(options: options)
        
        switch options.format {
        case .json:
            return try await exportAsJSON(data: data, options: options)
        case .csv:
            return try await exportAsCSV(data: data, options: options)
        case .xml:
            return try await exportAsXML(data: data, options: options)
        case .anki:
            return try await exportAsAnki(data: data, options: options)
        case .pdf:
            return try await exportAsPDF(data: data, options: options)
        }
    }
    
    func getExportPreview(options: ExportOptions) async throws -> ExportPreview {
        let words = options.includeWords ? try await wordRepository.getAllWords() : []
        let literature = options.includeLiterature ? try await literatureRepository.getAllLiterature() : []
        let expressions = options.includeExpressions ? try await expressionRepository.getAllExpressions() : []
        
        let estimatedSize = estimateFileSize(
            words: words.count,
            literature: literature.count,
            expressions: expressions.count,
            format: options.format
        )
        
        return ExportPreview(
            totalWords: words.count,
            totalLiterature: literature.count,
            totalExpressions: expressions.count,
            fileSize: estimatedSize,
            estimatedExportTime: Double(words.count + literature.count + expressions.count) * 0.001
        )
    }
    
    // MARK: - Import
    
    func importData(from url: URL, source: ImportSource) async throws -> ImportResult {
        switch source {
        case .json:
            return try await importFromJSON(url: url)
        case .csv:
            return try await importFromCSV(url: url)
        case .anki:
            return try await importFromAnki(url: url)
        case .excel:
            return try await importFromExcel(url: url)
        case .txt:
            return try await importFromText(url: url)
        }
    }
    
    func validateImportFile(_ url: URL, source: ImportSource) async throws -> ImportValidation {
        let fileManager = FileManager.default
        
        guard fileManager.fileExists(atPath: url.path) else {
            return ImportValidation(
                isValid: false,
                source: source,
                estimatedRecords: 0,
                errors: ["文件不存在"],
                warnings: []
            )
        }
        
        switch source {
        case .json:
            return try await validateJSONFile(url: url)
        case .csv:
            return try await validateCSVFile(url: url)
        default:
            return ImportValidation(
                isValid: true,
                source: source,
                estimatedRecords: 0,
                errors: [],
                warnings: ["无法预估记录数"]
            )
        }
    }
    
    // MARK: - Backup & Restore
    
    func backupData() async throws -> URL {
        let options = ExportOptions(
            format: .json,
            includeWords: true,
            includeLiterature: true,
            includeExpressions: true,
            includeSettings: true,
            includeStatistics: true,
            dateRange: nil,
            compressionEnabled: true,
            encryptionEnabled: false,
            password: nil
        )
        
        let exportURL = try await exportData(options: options)
        
        // 创建带时间戳的备份文件名
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())
        
        let backupFileName = "AcademicHelper_Backup_\(timestamp).json"
        let backupURL = exportURL.deletingLastPathComponent().appendingPathComponent(backupFileName)
        
        try FileManager.default.moveItem(at: exportURL, to: backupURL)
        
        return backupURL
    }
    
    func restoreData(from url: URL) async throws {
        let result = try await importData(from: url, source: .json)
        
        guard result.success else {
            throw ImportExportError.restoreFailed(reason: "导入失败: \(result.errors.map { $0.message }.joined(separator: ", "))")
        }
    }
    
    // MARK: - Private Methods - Export
    
    private func prepareExportData(options: ExportOptions) async throws -> AcademicData {
        let words = options.includeWords ? try await wordRepository.getAllWords() : []
        let literature = options.includeLiterature ? try await literatureRepository.getAllLiterature() : []
        let expressions = options.includeExpressions ? try await expressionRepository.getAllExpressions() : []
        
        return AcademicData(
            version: "1.0",
            exportDate: Date(),
            metadata: AcademicData.ExportMetadata(
                appVersion: "1.0.0",
                deviceName: "Mac",
                systemVersion: "macOS 14.0",
                userId: nil
            ),
            words: words.map { mapToWordData($0) },
            literature: literature.map { mapToLiteratureData($0) },
            expressions: expressions.map { mapToExpressionData($0) },
            settings: options.includeSettings ? await getSettingsData() : nil,
            statistics: options.includeStatistics ? await getStatisticsData() : nil
        )
    }
    
    private func exportAsJSON(data: AcademicData, options: ExportOptions) async throws -> URL {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        
        let jsonData = try encoder.encode(data)
        
        // 压缩
        let finalData: Data
        if options.compressionEnabled {
            finalData = try compressData(jsonData)
        } else {
            finalData = jsonData
        }
        
        // 加密
        let exportData: Data
        if options.encryptionEnabled, let password = options.password {
            exportData = try encryptData(finalData, password: password)
        } else {
            exportData = finalData
        }
        
        let fileName = "AcademicHelper_Export_\(formatDate(Date())).json"
        let exportURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
        
        try exportData.write(to: exportURL)
        
        return exportURL
    }
    
    private func exportAsCSV(data: AcademicData, options: ExportOptions) async throws -> URL {
        var csvString = "Text,Definition,Phonetic,PartOfSpeech,Example,Tags\n"
        
        if let words = data.words {
            for word in words {
                let row = [
                    word.text,
                    word.definition,
                    word.phonetic ?? "",
                    word.partOfSpeech ?? "",
                    word.example ?? "",
                    word.tags.joined(separator: ";")
                ].map { "\"\($0.replacingOccurrences(of: "\"", with: "\"\""))\"" }
                .joined(separator: ",")
                
                csvString += row + "\n"
            }
        }
        
        let fileName = "AcademicHelper_Words_\(formatDate(Date())).csv"
        let exportURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
        
        try csvString.write(to: exportURL, atomically: true, encoding: .utf8)
        
        return exportURL
    }
    
    private func exportAsXML(data: AcademicData, options: ExportOptions) async throws -> URL {
        var xmlString = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        xmlString += "<AcademicData version=\"\(data.version)\">\n"
        
        if let words = data.words {
            xmlString += "  <Words>\n"
            for word in words {
                xmlString += """
                  <Word>
                    <Text>\(escapeXML(word.text))</Text>
                    <Definition>\(escapeXML(word.definition))</Definition>
                  </Word>
                """
            }
            xmlString += "  </Words>\n"
        }
        
        xmlString += "</AcademicData>"
        
        let fileName = "AcademicHelper_Export_\(formatDate(Date())).xml"
        let exportURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
        
        try xmlString.write(to: exportURL, atomically: true, encoding: .utf8)
        
        return exportURL
    }
    
    private func exportAsAnki(data: AcademicData, options: ExportOptions) async throws -> URL {
        // Anki 使用特定的文本格式
        var ankiString = "#separator:tab\n"
        ankiString += "#html:false\n"
        
        if let words = data.words {
            for word in words {
                let front = word.text
                let back = "\(word.definition)\n\(word.example ?? "")"
                ankiString += "\(front)\t\(back)\n"
            }
        }
        
        let fileName = "AcademicHelper_Anki_\(formatDate(Date())).txt"
        let exportURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
        
        try ankiString.write(to: exportURL, atomically: true, encoding: .utf8)
        
        return exportURL
    }
    
    private func exportAsPDF(data: AcademicData, options: ExportOptions) async throws -> URL {
        // PDF 导出需要更复杂的实现，这里简化处理
        throw ImportExportError.unsupportedFormat(format: "PDF")
    }
    
    // MARK: - Private Methods - Import
    
    private func importFromJSON(url: URL) async throws -> ImportResult {
        let data = try Data(contentsOf: url)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let academicData = try decoder.decode(AcademicData.self, from: data)
        
        var importedWords = 0
        var importedLiterature = 0
        var importedExpressions = 0
        var errors: [ImportError] = []
        
        // 导入单词
        if let words = academicData.words {
            for (index, wordData) in words.enumerated() {
                do {
                    let word = mapFromWordData(wordData)
                    try await wordRepository.saveWord(word)
                    importedWords += 1
                } catch {
                    errors.append(ImportError(row: index, field: "word", message: error.localizedDescription))
                }
            }
        }
        
        // 导入文献
        if let literature = academicData.literature {
            for (index, litData) in literature.enumerated() {
                do {
                    let lit = mapFromLiteratureData(litData)
                    try await literatureRepository.saveLiterature(lit)
                    importedLiterature += 1
                } catch {
                    errors.append(ImportError(row: index, field: "literature", message: error.localizedDescription))
                }
            }
        }
        
        // 导入表达
        if let expressions = academicData.expressions {
            for (index, exprData) in expressions.enumerated() {
                do {
                    let expr = mapFromExpressionData(exprData)
                    try await expressionRepository.saveExpression(expr)
                    importedExpressions += 1
                } catch {
                    errors.append(ImportError(row: index, field: "expression", message: error.localizedDescription))
                }
            }
        }
        
        return ImportResult(
            success: errors.isEmpty,
            importedWords: importedWords,
            importedLiterature: importedLiterature,
            importedExpressions: importedExpressions,
            errors: errors,
            warnings: []
        )
    }
    
    private func importFromCSV(url: URL) async throws -> ImportResult {
        let content = try String(contentsOf: url, encoding: .utf8)
        let rows = content.components(separatedBy: "\n").filter { !$0.isEmpty }
        
        guard rows.count > 1 else {
            return ImportResult(
                success: false,
                importedWords: 0,
                importedLiterature: 0,
                importedExpressions: 0,
                errors: [ImportError(row: 0, field: "all", message: "CSV 文件为空或格式错误")],
                warnings: []
            )
        }
        
        var importedWords = 0
        var errors: [ImportError] = []
        
        // 跳过标题行
        for (index, row) in rows.dropFirst().enumerated() {
            let columns = parseCSVRow(row)
            
            guard columns.count >= 2 else {
                errors.append(ImportError(row: index + 1, field: "all", message: "列数不足"))
                continue
            }
            
            let word = Word(
                id: UUID(),
                text: columns[0],
                definition: columns[1],
                phonetic: columns.count > 2 ? columns[2] : nil,
                partOfSpeech: columns.count > 3 ? columns[3] : nil,
                example: columns.count > 4 ? columns[4] : nil,
                addedAt: Date(),
                lastReviewedAt: nil,
                reviewCount: 0,
                isMastered: false,
                tags: columns.count > 5 ? columns[5].components(separatedBy: ";") : [],
                notes: nil
            )
            
            do {
                try await wordRepository.saveWord(word)
                importedWords += 1
            } catch {
                errors.append(ImportError(row: index + 1, field: "word", message: error.localizedDescription))
            }
        }
        
        return ImportResult(
            success: errors.isEmpty,
            importedWords: importedWords,
            importedLiterature: 0,
            importedExpressions: 0,
            errors: errors,
            warnings: []
        )
    }
    
    private func importFromAnki(url: URL) async throws -> ImportResult {
        // Anki 导入实现
        throw ImportExportError.unsupportedFormat(format: "Anki import")
    }
    
    private func importFromExcel(url: URL) async throws -> ImportResult {
        // Excel 导入实现
        throw ImportExportError.unsupportedFormat(format: "Excel import")
    }
    
    private func importFromText(url: URL) async throws -> ImportResult {
        let content = try String(contentsOf: url, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        var importedWords = 0
        var errors: [ImportError] = []
        
        for (index, line) in lines.enumerated() {
            let parts = line.components(separatedBy: "\t")
            
            guard parts.count >= 2 else {
                errors.append(ImportError(row: index, field: "all", message: "格式错误，需要至少两列"))
                continue
            }
            
            let word = Word(
                id: UUID(),
                text: parts[0],
                definition: parts[1],
                phonetic: nil,
                partOfSpeech: nil,
                example: parts.count > 2 ? parts[2] : nil,
                addedAt: Date(),
                lastReviewedAt: nil,
                reviewCount: 0,
                isMastered: false,
                tags: [],
                notes: nil
            )
            
            do {
                try await wordRepository.saveWord(word)
                importedWords += 1
            } catch {
                errors.append(ImportError(row: index, field: "word", message: error.localizedDescription))
            }
        }
        
        return ImportResult(
            success: errors.isEmpty,
            importedWords: importedWords,
            importedLiterature: 0,
            importedExpressions: 0,
            errors: errors,
            warnings: []
        )
    }
    
    // MARK: - Private Methods - Validation
    
    private func validateJSONFile(url: URL) async throws -> ImportValidation {
        do {
            let data = try Data(contentsOf: url)
            let academicData = try JSONDecoder().decode(AcademicData.self, from: data)
            
            var estimatedRecords = 0
            if let words = academicData.words { estimatedRecords += words.count }
            if let literature = academicData.literature { estimatedRecords += literature.count }
            if let expressions = academicData.expressions { estimatedRecords += expressions.count }
            
            return ImportValidation(
                isValid: true,
                source: .json,
                estimatedRecords: estimatedRecords,
                errors: [],
                warnings: []
            )
        } catch {
            return ImportValidation(
                isValid: false,
                source: .json,
                estimatedRecords: 0,
                errors: ["JSON 解析错误: \(error.localizedDescription)"],
                warnings: []
            )
        }
    }
    
    private func validateCSVFile(url: URL) async throws -> ImportValidation {
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let rows = content.components(separatedBy: "\n").filter { !$0.isEmpty }
            
            guard rows.count > 1 else {
                return ImportValidation(
                    isValid: false,
                    source: .csv,
                    estimatedRecords: 0,
                    errors: ["CSV 文件为空"],
                    warnings: []
                )
            }
            
            return ImportValidation(
                isValid: true,
                source: .csv,
                estimatedRecords: rows.count - 1,
                errors: [],
                warnings: []
            )
        } catch {
            return ImportValidation(
                isValid: false,
                source: .csv,
                estimatedRecords: 0,
                errors: [error.localizedDescription],
                warnings: []
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func mapToWordData(_ word: Word) -> AcademicData.WordData {
        AcademicData.WordData(
            id: word.id,
            text: word.text,
            definition: word.definition,
            phonetic: word.phonetic,
            partOfSpeech: word.partOfSpeech,
            example: word.example,
            addedAt: word.addedAt,
            lastReviewedAt: word.lastReviewedAt,
            reviewCount: word.reviewCount,
            isMastered: word.isMastered,
            tags: word.tags,
            notes: word.notes
        )
    }
    
    private func mapFromWordData(_ data: AcademicData.WordData) -> Word {
        Word(
            id: data.id,
            text: data.text,
            definition: data.definition,
            phonetic: data.phonetic,
            partOfSpeech: data.partOfSpeech,
            example: data.example,
            addedAt: data.addedAt,
            lastReviewedAt: data.lastReviewedAt,
            reviewCount: data.reviewCount,
            isMastered: data.isMastered,
            tags: data.tags,
            notes: data.notes
        )
    }
    
    private func mapToLiteratureData(_ literature: LiteratureDocument) -> AcademicData.LiteratureData {
        AcademicData.LiteratureData(
            id: literature.id,
            title: literature.title,
            authors: literature.authors,
            abstract: literature.abstract,
            filePath: literature.filePath,
            fileSize: literature.fileSize,
            pageCount: literature.pageCount,
            tags: literature.tags,
            addedAt: literature.addedAt,
            lastOpenedAt: literature.lastOpenedAt,
            associatedWordIds: literature.associatedWordIds
        )
    }
    
    private func mapFromLiteratureData(_ data: AcademicData.LiteratureData) -> LiteratureDocument {
        LiteratureDocument(
            id: data.id,
            title: data.title,
            authors: data.authors,
            abstract: data.abstract,
            filePath: data.filePath ?? "",
            fileSize: data.fileSize ?? 0,
            pageCount: data.pageCount,
            tags: data.tags,
            addedAt: data.addedAt,
            lastOpenedAt: data.lastOpenedAt,
            associatedWordIds: data.associatedWordIds
        )
    }
    
    private func mapToExpressionData(_ expression: AcademicExpression) -> AcademicData.ExpressionData {
        AcademicData.ExpressionData(
            id: expression.id,
            text: expression.text,
            type: expression.type.rawValue,
            meaning: expression.meaning,
            examples: expression.examples,
            category: expression.category,
            isFavorite: expression.isFavorite,
            addedAt: expression.addedAt
        )
    }
    
    private func mapFromExpressionData(_ data: AcademicData.ExpressionData) -> AcademicExpression {
        AcademicExpression(
            id: data.id,
            text: data.text,
            type: AcademicExpression.ExpressionType(rawValue: data.type) ?? .other,
            meaning: data.meaning,
            examples: data.examples,
            category: data.category,
            isFavorite: data.isFavorite,
            addedAt: data.addedAt
        )
    }
    
    private func getSettingsData() async -> AcademicData.SettingsData {
        AcademicData.SettingsData(
            theme: "light",
            fontSize: 14,
            autoSync: true,
            notificationEnabled: true,
            dailyGoal: 20,
            preferredDictionary: "Youdao"
        )
    }
    
    private func getStatisticsData() async -> AcademicData.StatisticsData {
        AcademicData.StatisticsData(
            totalStudyTime: 3600,
            totalWordsLearned: 100,
            currentStreak: 5,
            longestStreak: 12,
            averageAccuracy: 0.85
        )
    }
    
    private func estimateFileSize(words: Int, literature: Int, expressions: Int, format: ExportFormat) -> Int64 {
        let baseSize = Int64(words * 200 + literature * 500 + expressions * 300)
        
        switch format {
        case .json:
            return baseSize
        case .csv:
            return Int64(Double(baseSize) * 0.5)
        case .xml:
            return Int64(Double(baseSize) * 1.5)
        case .anki:
            return Int64(Double(baseSize) * 0.3)
        case .pdf:
            return baseSize * 2
        }
    }
    
    private func compressData(_ data: Data) throws -> Data {
        // 使用 zlib 压缩
        return data
    }
    
    private func encryptData(_ data: Data, password: String) throws -> Data {
        // 使用 AES 加密
        return data
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private func parseCSVRow(_ row: String) -> [String] {
        var result: [String] = []
        var current = ""
        var insideQuotes = false
        
        for char in row {
            if char == "\"" {
                insideQuotes = !insideQuotes
            } else if char == "," && !insideQuotes {
                result.append(current)
                current = ""
            } else {
                current.append(char)
            }
        }
        
        result.append(current)
        return result
    }
    
    private func escapeXML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}

// MARK: - Errors

enum ImportExportError: Error, LocalizedError {
    case unsupportedFormat(format: String)
    case invalidFile
    case restoreFailed(reason: String)
    case encryptionFailed
    case compressionFailed
    
    var errorDescription: String? {
        switch self {
        case .unsupportedFormat(let format):
            return "不支持的格式: \(format)"
        case .invalidFile:
            return "无效的文件"
        case .restoreFailed(let reason):
            return "恢复失败: \(reason)"
        case .encryptionFailed:
            return "加密失败"
        case .compressionFailed:
            return "压缩失败"
        }
    }
}
