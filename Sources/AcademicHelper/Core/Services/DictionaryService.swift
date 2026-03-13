import Foundation

protocol DictionaryServiceProtocol {
    func lookup(word: String) async throws -> WordDefinition
    func searchSuggestions(prefix: String) async throws -> [String]
    func translate(text: String, from: Language, to: Language) async throws -> String
}

enum Language: String, CaseIterable {
    case english = "en"
    case chinese = "zh"
    case japanese = "ja"
    case korean = "ko"
    case french = "fr"
    case german = "de"
    case spanish = "es"
}

@MainActor
final class DictionaryService: DictionaryServiceProtocol {
    
    // MARK: - Properties
    
    private let session: URLSession
    private let memoryCache: NSCache<NSString, CacheEntry>
    private let diskCache: DiskCache
    private let youdaoAppKey: String?
    private let youdaoAppSecret: String?
    
    // API 配置
    private let freeDictionaryAPI = "https://api.dictionaryapi.dev/api/v2/entries"
    private let youdaoAPI = "https://openapi.youdao.com/api"
    
    // MARK: - Cache
    
    final class CacheEntry {
        let definition: WordDefinition
        let timestamp: Date
        
        init(definition: WordDefinition, timestamp: Date) {
            self.definition = definition
            self.timestamp = timestamp
        }
    }
    
    // MARK: - Initialization
    
    init(youdaoAppKey: String? = nil, youdaoAppSecret: String? = nil) {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: config)
        
        self.memoryCache = NSCache<NSString, CacheEntry>()
        self.memoryCache.countLimit = 1000
        
        self.diskCache = DiskCache()
        self.youdaoAppKey = youdaoAppKey
        self.youdaoAppSecret = youdaoAppSecret
    }
    
    // MARK: - Public Methods
    
    /// 查询单词定义（优先使用有道 API，回退到 Free Dictionary API）
    func lookup(word: String) async throws -> WordDefinition {
        let cacheKey = word.lowercased() as NSString
        
        // 1. 检查内存缓存
        if let cached = memoryCache.object(forKey: cacheKey),
           Date().timeIntervalSince(cached.timestamp) < 86400 {
            print("[Dictionary] Memory cache hit for: \(word)")
            return cached.definition
        }
        
        // 2. 检查磁盘缓存
        if let diskCached = try? diskCache.load(key: word.lowercased()),
           Date().timeIntervalSince(diskCached.timestamp) < 7 * 86400 {
            print("[Dictionary] Disk cache hit for: \(word)")
            memoryCache.setObject(diskCached, forKey: cacheKey)
            return diskCached.definition
        }
        
        // 3. 从 API 获取
        let definition: WordDefinition
        
        // 优先使用有道 API（如果有配置）
        if youdaoAppKey != nil && youdaoAppSecret != nil {
            do {
                definition = try await fetchFromYoudao(word: word)
                print("[Dictionary] Fetched from Youdao: \(word)")
            } catch {
                print("[Dictionary] Youdao failed, fallback to Free Dictionary: \(error)")
                definition = try await fetchFromFreeDictionary(word: word)
            }
        } else {
            definition = try await fetchFromFreeDictionary(word: word)
            print("[Dictionary] Fetched from Free Dictionary: \(word)")
        }
        
        // 4. 保存到缓存
        let entry = CacheEntry(definition: definition, timestamp: Date())
        memoryCache.setObject(entry, forKey: cacheKey)
        try? diskCache.save(entry: entry, key: word.lowercased())
        
        return definition
    }
    
    /// 搜索建议
    func searchSuggestions(prefix: String) async throws -> [String] {
        guard prefix.count >= 2 else { return [] }
        
        // 从磁盘缓存中搜索匹配的单词
        let cachedWords = try? diskCache.search(prefix: prefix.lowercased(), limit: 10)
        return cachedWords ?? []
    }
    
    /// 翻译文本
    func translate(text: String, from: Language, to: Language) async throws -> String {
        guard !text.isEmpty else { return "" }
        
        // 优先使用有道翻译
        if youdaoAppKey != nil && youdaoAppSecret != nil {
            return try await translateWithYoudao(text: text, from: from, to: to)
        } else {
            throw DictionaryError.translationNotAvailable
        }
    }
    
    /// 预加载常用单词到缓存
    func preloadCommonWords() async {
        let commonWords = [
            "the", "be", "to", "of", "and", "a", "in", "that", "have",
            "I", "it", "for", "not", "on", "with", "he", "as", "you",
            "do", "at", "this", "but", "his", "by", "from", "they",
            "we", "say", "her", "she", "or", "an", "will", "my",
            "one", "all", "would", "there", "their", "what", "so",
            "up", "out", "if", "about", "who", "get", "which", "go",
            "me", "when", "make", "can", "like", "time", "no", "just",
            "him", "know", "take", "people", "into", "year", "your",
            "good", "some", "could", "them", "see", "other", "than",
            "then", "now", "look", "only", "come", "its", "over",
            "think", "also", "back", "after", "use", "two", "how",
            "our", "work", "first", "well", "way", "even", "new",
            "want", "because", "any", "these", "give", "day", "most",
            "us", "is", "was", "are", "were", "been", "has", "had",
            "did", "does", "doing", "done", "being", "having"
        ]
        
        for word in commonWords.prefix(20) {
            _ = try? await lookup(word: word)
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms 延迟，避免请求过快
        }
    }
    
    /// 清空缓存
    func clearCache() {
        memoryCache.removeAllObjects()
        try? diskCache.clear()
    }
    
    /// 获取缓存统计
    func getCacheStats() -> (memoryCount: Int, diskCount: Int) {
        let diskCount = (try? diskCache.count()) ?? 0
        return (memoryCache.totalCostLimit, diskCount)
    }
    
    // MARK: - Private Methods
    
    private func fetchFromFreeDictionary(word: String) async throws -> WordDefinition {
        let encodedWord = word.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? word
        let urlString = "\(freeDictionaryAPI)/en/\(encodedWord)"
        
        guard let url = URL(string: urlString) else {
            throw DictionaryError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw DictionaryError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            let entries = try JSONDecoder().decode([FreeDictionaryEntry].self, from: data)
            return convertToWordDefinition(entries, word: word)
        case 404:
            throw DictionaryError.wordNotFound
        default:
            throw DictionaryError.apiError(statusCode: httpResponse.statusCode)
        }
    }
    
    private func fetchFromYoudao(word: String) async throws -> WordDefinition {
        guard let appKey = youdaoAppKey,
              let appSecret = youdaoAppSecret else {
            throw DictionaryError.missingAPIKey
        }
        
        let salt = String(Int.random(in: 1000...9999))
        let curtime = String(Int(Date().timeIntervalSince1970))
        let signStr = appKey + truncate(word) + salt + curtime + appSecret
        let sign = signStr.sha256()
        
        var components = URLComponents(string: youdaoAPI)!
        components.queryItems = [
            URLQueryItem(name: "q", value: word),
            URLQueryItem(name: "from", value: "en"),
            URLQueryItem(name: "to", value: "zh-CHS"),
            URLQueryItem(name: "appKey", value: appKey),
            URLQueryItem(name: "salt", value: salt),
            URLQueryItem(name: "sign", value: sign),
            URLQueryItem(name: "signType", value: "v3"),
            URLQueryItem(name: "curtime", value: curtime)
        ]
        
        guard let url = components.url else {
            throw DictionaryError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw DictionaryError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw DictionaryError.apiError(statusCode: httpResponse.statusCode)
        }
        
        let youdaoResponse = try JSONDecoder().decode(YoudaoResponse.self, from: data)
        
        guard youdaoResponse.errorCode == "0" else {
            throw DictionaryError.youdaoError(code: youdaoResponse.errorCode)
        }
        
        return convertYoudaoToWordDefinition(youdaoResponse, word: word)
    }
    
    private func translateWithYoudao(text: String, from: Language, to: Language) async throws -> String {
        guard let appKey = youdaoAppKey,
              let appSecret = youdaoAppSecret else {
            throw DictionaryError.missingAPIKey
        }
        
        let salt = String(Int.random(in: 1000...9999))
        let curtime = String(Int(Date().timeIntervalSince1970))
        let signStr = appKey + truncate(text) + salt + curtime + appSecret
        let sign = signStr.sha256()
        
        var components = URLComponents(string: youdaoAPI)!
        components.queryItems = [
            URLQueryItem(name: "q", value: text),
            URLQueryItem(name: "from", value: from.rawValue),
            URLQueryItem(name: "to", value: to.rawValue),
            URLQueryItem(name: "appKey", value: appKey),
            URLQueryItem(name: "salt", value: salt),
            URLQueryItem(name: "sign", value: sign),
            URLQueryItem(name: "signType", value: "v3"),
            URLQueryItem(name: "curtime", value: curtime)
        ]
        
        guard let url = components.url else {
            throw DictionaryError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw DictionaryError.invalidResponse
        }
        
        let youdaoResponse = try JSONDecoder().decode(YoudaoResponse.self, from: data)
        return youdaoResponse.translation?.first ?? ""
    }
    
    private func truncate(_ q: String) -> String {
        if q.count <= 20 {
            return q
        }
        let start = q.prefix(10)
        let end = q.suffix(10)
        return String(start) + String(q.count) + String(end)
    }
    
    private func convertToWordDefinition(_ entries: [FreeDictionaryEntry], word: String) -> WordDefinition {
        let meanings = entries.flatMap { entry in
            entry.meanings.map { meaning in
                WordDefinition.Meaning(
                    partOfSpeech: meaning.partOfSpeech,
                    definitions: meaning.definitions.map { def in
                        WordDefinition.Definition(
                            definition: def.definition,
                            example: def.example,
                            synonyms: def.synonyms ?? []
                        )
                    }
                )
            }
        }
        
        return WordDefinition(
            word: word,
            phonetic: entries.first?.phonetic ?? entries.first?.phonetics.first?.text,
            audioURL: entries.first?.phonetics.first?.audio,
            meanings: meanings
        )
    }
    
    private func convertYoudaoToWordDefinition(_ response: YoudaoResponse, word: String) -> WordDefinition {
        var meanings: [WordDefinition.Meaning] = []
        
        // 基础释义
        if let translations = response.translation {
            let definitions = translations.map {
                WordDefinition.Definition(definition: $0, example: nil, synonyms: [])
            }
            meanings.append(WordDefinition.Meaning(partOfSpeech: "翻译", definitions: definitions))
        }
        
        // 详细释义
        if let basic = response.basic {
            if let explains = basic.explains {
                let definitions = explains.map {
                    WordDefinition.Definition(definition: $0, example: nil, synonyms: [])
                }
                meanings.append(WordDefinition.Meaning(partOfSpeech: "详细", definitions: definitions))
            }
        }
        
        // 网络释义
        if let web = response.web {
            let webDefinitions = web.flatMap { $0.value }.map {
                WordDefinition.Definition(definition: $0, example: nil, synonyms: [])
            }
            if !webDefinitions.isEmpty {
                meanings.append(WordDefinition.Meaning(partOfSpeech: "网络", definitions: webDefinitions))
            }
        }
        
        return WordDefinition(
            word: word,
            phonetic: response.basic?.phonetic,
            audioURL: response.basic?.speech,
            meanings: meanings
        )
    }
}

// MARK: - Disk Cache

@MainActor
final class DiskCache {
    private let cacheDirectory: URL
    private let fileManager = FileManager.default
    
    init() {
        let urls = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = urls[0].appendingPathComponent("DictionaryCache", isDirectory: true)
        
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    func save(entry: DictionaryService.CacheEntry, key: String) throws {
        let fileURL = cacheDirectory.appendingPathComponent("\(key).json")
        let data = try JSONEncoder().encode(entry.definition)
        try data.write(to: fileURL)
    }
    
    func load(key: String) throws -> DictionaryService.CacheEntry? {
        let fileURL = cacheDirectory.appendingPathComponent("\(key).json")
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        
        let data = try Data(contentsOf: fileURL)
        let definition = try JSONDecoder().decode(WordDefinition.self, from: data)
        let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
        let modificationDate = attributes[.modificationDate] as? Date ?? Date()
        
        return DictionaryService.CacheEntry(definition: definition, timestamp: modificationDate)
    }
    
    func search(prefix: String, limit: Int) throws -> [String] {
        let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
        let matchingFiles = files
            .map { $0.deletingPathExtension().lastPathComponent }
            .filter { $0.hasPrefix(prefix) }
            .prefix(limit)
        return Array(matchingFiles)
    }
    
    func count() throws -> Int {
        let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
        return files.count
    }
    
    func clear() throws {
        let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
        for file in files {
            try fileManager.removeItem(at: file)
        }
    }
}

// MARK: - Models

struct WordDefinition: Codable {
    let word: String
    let phonetic: String?
    let audioURL: String?
    let meanings: [Meaning]
    
    struct Meaning: Codable {
        let partOfSpeech: String
        let definitions: [Definition]
    }
    
    struct Definition: Codable {
        let definition: String
        let example: String?
        let synonyms: [String]
    }
}

// MARK: - API Response Models

struct FreeDictionaryEntry: Codable {
    let word: String
    let phonetic: String?
    let phonetics: [Phonetic]
    let meanings: [Meaning]
    
    struct Phonetic: Codable {
        let text: String?
        let audio: String?
    }
    
    struct Meaning: Codable {
        let partOfSpeech: String
        let definitions: [Definition]
    }
    
    struct Definition: Codable {
        let definition: String
        let example: String?
        let synonyms: [String]?
        let antonyms: [String]?
    }
}

struct YoudaoResponse: Codable {
    let errorCode: String
    let query: String?
    let translation: [String]?
    let basic: Basic?
    let web: [WebTranslation]?
    
    struct Basic: Codable {
        let phonetic: String?
        let speech: String?
        let explains: [String]?
    }
    
    struct WebTranslation: Codable {
        let key: String
        let value: [String]
    }
}

// MARK: - Errors

enum DictionaryError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case wordNotFound
    case apiError(statusCode: Int)
    case networkError(Error)
    case missingAPIKey
    case youdaoError(code: String)
    case translationNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的 URL"
        case .invalidResponse:
            return "服务器响应无效"
        case .wordNotFound:
            return "未找到该单词"
        case .apiError(let code):
            return "API 错误 (状态码: \(code))"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .missingAPIKey:
            return "缺少 API 密钥"
        case .youdaoError(let code):
            return "有道 API 错误 (代码: \(code))"
        case .translationNotAvailable:
            return "翻译功能不可用（需要配置有道 API）"
        }
    }
}

// MARK: - String Extension

extension String {
    func sha256() -> String {
        let data = Data(self.utf8)
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

import CommonCrypto
