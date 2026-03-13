import Foundation

protocol DictionaryServiceProtocol {
    func lookup(word: String) async throws -> WordDefinition
    func searchSuggestions(prefix: String) async throws -> [String]
}

@MainActor
final class DictionaryService: DictionaryServiceProtocol {
    private let session: URLSession
    private let cache: NSCache<NSString, CacheEntry>
    
    final class CacheEntry {
        let definition: WordDefinition
        let timestamp: Date
        
        init(definition: WordDefinition, timestamp: Date) {
            self.definition = definition
            self.timestamp = timestamp
        }
    }
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: config)
        
        self.cache = NSCache<NSString, CacheEntry>()
        self.cache.countLimit = 1000
    }
    
    func lookup(word: String) async throws -> WordDefinition {
        let cacheKey = word.lowercased() as NSString
        
        if let cached = cache.object(forKey: cacheKey),
           Date().timeIntervalSince(cached.timestamp) < 86400 {
            return cached.definition
        }
        
        let definition = try await fetchFromAPI(word: word)
        
        let entry = CacheEntry(definition: definition, timestamp: Date())
        cache.setObject(entry, forKey: cacheKey)
        
        return definition
    }
    
    func searchSuggestions(prefix: String) async throws -> [String] {
        guard prefix.count >= 2 else { return [] }
        return []
    }
    
    private func fetchFromAPI(word: String) async throws -> WordDefinition {
        let encodedWord = word.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? word
        let urlString = "https://api.dictionaryapi.dev/api/v2/entries/en/\(encodedWord)"
        
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
            meanings: meanings
        )
    }
}

enum DictionaryError: Error {
    case invalidURL
    case invalidResponse
    case wordNotFound
    case apiError(statusCode: Int)
    case networkError(Error)
}

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
