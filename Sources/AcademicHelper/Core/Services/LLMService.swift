import Foundation
import Combine

// MARK: - LLM Provider Enum

enum LLMProvider: String, CaseIterable, Identifiable {
    case openAI = "OpenAI"
    case anthropic = "Anthropic"
    case deepSeek = "DeepSeek"
    case moonshot = "Moonshot"
    case custom = "Custom"
    
    var id: String { rawValue }
    
    var defaultBaseURL: String {
        switch self {
        case .openAI:
            return "https://api.openai.com/v1"
        case .anthropic:
            return "https://api.anthropic.com/v1"
        case .deepSeek:
            return "https://api.deepseek.com/v1"
        case .moonshot:
            return "https://api.moonshot.cn/v1"
        case .custom:
            return ""
        }
    }
    
    var defaultModel: String {
        switch self {
        case .openAI:
            return "gpt-4o-mini"
        case .anthropic:
            return "claude-3-haiku-20240307"
        case .deepSeek:
            return "deepseek-chat"
        case .moonshot:
            return "moonshot-v1-8k"
        case .custom:
            return ""
        }
    }
    
    var availableModels: [String] {
        switch self {
        case .openAI:
            return ["gpt-4o", "gpt-4o-mini", "gpt-4-turbo", "gpt-3.5-turbo"]
        case .anthropic:
            return ["claude-3-opus-20240229", "claude-3-sonnet-20240229", "claude-3-haiku-20240307"]
        case .deepSeek:
            return ["deepseek-chat", "deepseek-coder"]
        case .moonshot:
            return ["moonshot-v1-8k", "moonshot-v1-32k", "moonshot-v1-128k"]
        case .custom:
            return []
        }
    }
}

// MARK: - LLM Configuration

struct LLMConfiguration: Codable, Equatable {
    var provider: LLMProvider
    var apiKey: String
    var baseURL: String
    var model: String
    var temperature: Double
    var maxTokens: Int
    var topP: Double
    var frequencyPenalty: Double
    var presencePenalty: Double
    var timeout: TimeInterval
    var maxRetries: Int
    var retryDelay: TimeInterval
    var enableCache: Bool
    var cacheExpiration: TimeInterval
    var rateLimitPerMinute: Int
    var enableLogging: Bool
    
    init(
        provider: LLMProvider = .deepSeek,
        apiKey: String = "",
        baseURL: String? = nil,
        model: String? = nil,
        temperature: Double = 0.7,
        maxTokens: Int = 2048,
        topP: Double = 1.0,
        frequencyPenalty: Double = 0.0,
        presencePenalty: Double = 0.0,
        timeout: TimeInterval = 60.0,
        maxRetries: Int = 3,
        retryDelay: TimeInterval = 1.0,
        enableCache: Bool = true,
        cacheExpiration: TimeInterval = 3600,
        rateLimitPerMinute: Int = 60,
        enableLogging: Bool = true
    ) {
        self.provider = provider
        self.apiKey = apiKey
        self.baseURL = baseURL ?? provider.defaultBaseURL
        self.model = model ?? provider.defaultModel
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.topP = topP
        self.frequencyPenalty = frequencyPenalty
        self.presencePenalty = presencePenalty
        self.timeout = timeout
        self.maxRetries = maxRetries
        self.retryDelay = retryDelay
        self.enableCache = enableCache
        self.cacheExpiration = cacheExpiration
        self.rateLimitPerMinute = rateLimitPerMinute
        self.enableLogging = enableLogging
    }
}

// MARK: - LLM Message

struct LLMMessage: Codable, Equatable {
    let role: MessageRole
    let content: String
    
    enum MessageRole: String, Codable {
        case system
        case user
        case assistant
        case function
    }
    
    static func system(_ content: String) -> LLMMessage {
        LLMMessage(role: .system, content: content)
    }
    
    static func user(_ content: String) -> LLMMessage {
        LLMMessage(role: .user, content: content)
    }
    
    static func assistant(_ content: String) -> LLMMessage {
        LLMMessage(role: .assistant, content: content)
    }
}

// MARK: - LLM Request

struct LLMRequest {
    let messages: [LLMMessage]
    let config: LLMConfiguration
    let stream: Bool
    let requestId: String
    let timestamp: Date
    
    init(
        messages: [LLMMessage],
        config: LLMConfiguration,
        stream: Bool = false,
        requestId: String = UUID().uuidString
    ) {
        self.messages = messages
        self.config = config
        self.stream = stream
        self.requestId = requestId
        self.timestamp = Date()
    }
    
    var cacheKey: String {
        let content = messages.map { "\($0.role):\($0.content)" }.joined(separator: "|")
        return "\(config.provider)_\(config.model)_\(content.hashValue)"
    }
}

// MARK: - LLM Response

struct LLMResponse {
    let requestId: String
    let content: String
    let model: String
    let usage: TokenUsage
    let finishReason: String?
    let timestamp: Date
    let cached: Bool
    let latency: TimeInterval
    
    struct TokenUsage {
        let promptTokens: Int
        let completionTokens: Int
        let totalTokens: Int
        
        var estimatedCost: Double {
            // 粗略估算成本（基于 OpenAI 定价）
            let promptCost = Double(promptTokens) * 0.0015 / 1000
            let completionCost = Double(completionTokens) * 0.002 / 1000
            return promptCost + completionCost
        }
    }
}

// MARK: - LLM Stream Response

struct LLMStreamResponse {
    let requestId: String
    let delta: String
    let finishReason: String?
    let timestamp: Date
}

// MARK: - LLM Error

enum LLMError: Error, LocalizedError {
    case invalidConfiguration
    case invalidAPIKey
    case invalidRequest
    case networkError(Error)
    case timeout
    case rateLimited
    case serverError(Int, String)
    case parsingError(Error)
    case cacheError(Error)
    case noProviderAvailable
    case streamingNotSupported
    case cancelled
    
    var errorDescription: String? {
        switch self {
        case .invalidConfiguration:
            return "LLM 配置无效"
        case .invalidAPIKey:
            return "API 密钥无效"
        case .invalidRequest:
            return "请求参数无效"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .timeout:
            return "请求超时"
        case .rateLimited:
            return "请求频率超限，请稍后重试"
        case .serverError(let code, let message):
            return "服务器错误 (\(code)): \(message)"
        case .parsingError(let error):
            return "响应解析错误: \(error.localizedDescription)"
        case .cacheError(let error):
            return "缓存错误: \(error.localizedDescription)"
        case .noProviderAvailable:
            return "没有可用的 LLM 提供商"
        case .streamingNotSupported:
            return "当前提供商不支持流式响应"
        case .cancelled:
            return "请求已取消"
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .networkError, .timeout, .serverError, .rateLimited:
            return true
        default:
            return false
        }
    }
}

// MARK: - LLM Logger

@MainActor
final class LLMLogger {
    static let shared = LLMLogger()
    
    private var logs: [LLMLogEntry] = []
    private let maxLogCount = 1000
    private let fileManager = FileManager.default
    private let logFileURL: URL
    
    private init() {
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        logFileURL = urls[0].appendingPathComponent("llm_logs.json")
        loadLogs()
    }
    
    struct LLMLogEntry: Codable, Identifiable {
        let id: UUID
        let timestamp: Date
        let provider: String
        let model: String
        let requestId: String
        let promptTokens: Int
        let completionTokens: Int
        let latency: TimeInterval
        let cached: Bool
        let success: Bool
        let errorMessage: String?
        
        init(
            provider: String,
            model: String,
            requestId: String,
            promptTokens: Int,
            completionTokens: Int,
            latency: TimeInterval,
            cached: Bool,
            success: Bool,
            errorMessage: String? = nil
        ) {
            self.id = UUID()
            self.timestamp = Date()
            self.provider = provider
            self.model = model
            self.requestId = requestId
            self.promptTokens = promptTokens
            self.completionTokens = completionTokens
            self.latency = latency
            self.cached = cached
            self.success = success
            self.errorMessage = errorMessage
        }
    }
    
    func log(_ entry: LLMLogEntry) {
        logs.append(entry)
        
        // 限制日志数量
        if logs.count > maxLogCount {
            logs.removeFirst(logs.count - maxLogCount)
        }
        
        // 异步保存
        Task {
            await saveLogs()
        }
    }
    
    func getLogs(limit: Int = 100) -> [LLMLogEntry] {
        return Array(logs.suffix(limit).reversed())
    }
    
    func getStats(for period: TimeInterval = 86400) -> LLMStats {
        let cutoffDate = Date().addingTimeInterval(-period)
        let recentLogs = logs.filter { $0.timestamp >= cutoffDate }
        
        let totalRequests = recentLogs.count
        let successfulRequests = recentLogs.filter { $0.success }.count
        let cachedRequests = recentLogs.filter { $0.cached }.count
        let totalTokens = recentLogs.reduce(0) { $0 + $1.promptTokens + $1.completionTokens }
        let avgLatency = recentLogs.isEmpty ? 0 : recentLogs.map { $0.latency }.reduce(0, +) / Double(recentLogs.count)
        
        return LLMStats(
            totalRequests: totalRequests,
            successfulRequests: successfulRequests,
            failedRequests: totalRequests - successfulRequests,
            cachedRequests: cachedRequests,
            totalTokens: totalTokens,
            averageLatency: avgLatency
        )
    }
    
    func clearLogs() {
        logs.removeAll()
        Task {
            await saveLogs()
        }
    }
    
    private func saveLogs() async {
        do {
            let data = try JSONEncoder().encode(logs)
            try data.write(to: logFileURL)
        } catch {
            print("[LLMLogger] Failed to save logs: \(error)")
        }
    }
    
    private func loadLogs() {
        do {
            let data = try Data(contentsOf: logFileURL)
            logs = try JSONDecoder().decode([LLMLogEntry].self, from: data)
        } catch {
            // 文件不存在或解析失败，使用空日志
            logs = []
        }
    }
}

struct LLMStats {
    let totalRequests: Int
    let successfulRequests: Int
    let failedRequests: Int
    let cachedRequests: Int
    let totalTokens: Int
    let averageLatency: TimeInterval
    
    var successRate: Double {
        guard totalRequests > 0 else { return 0 }
        return Double(successfulRequests) / Double(totalRequests) * 100
    }
    
    var cacheHitRate: Double {
        guard totalRequests > 0 else { return 0 }
        return Double(cachedRequests) / Double(totalRequests) * 100
    }
}

// MARK: - Rate Limiter

@MainActor
final class RateLimiter {
    private var requestTimestamps: [Date] = []
    private let limit: Int
    private let window: TimeInterval
    
    init(limit: Int, window: TimeInterval = 60.0) {
        self.limit = limit
        self.window = window
    }
    
    func canMakeRequest() -> Bool {
        cleanupOldRequests()
        return requestTimestamps.count < limit
    }
    
    func waitTime() -> TimeInterval? {
        cleanupOldRequests()
        guard requestTimestamps.count >= limit else { return nil }
        
        if let oldestRequest = requestTimestamps.first {
            let timeSinceOldest = Date().timeIntervalSince(oldestRequest)
            return max(0, window - timeSinceOldest)
        }
        return nil
    }
    
    func recordRequest() {
        requestTimestamps.append(Date())
    }
    
    private func cleanupOldRequests() {
        let cutoff = Date().addingTimeInterval(-window)
        requestTimestamps.removeAll { $0 < cutoff }
    }
}

// MARK: - LLM Cache

@MainActor
final class LLMCache {
    private var memoryCache: [String: CacheEntry] = [:]
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let defaultExpiration: TimeInterval
    
    init(expiration: TimeInterval = 3600) {
        self.defaultExpiration = expiration
        let urls = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = urls[0].appendingPathComponent("LLMCache", isDirectory: true)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    struct CacheEntry: Codable {
        let response: LLMResponse
        let expirationDate: Date
        
        var isExpired: Bool {
            Date() > expirationDate
        }
    }
    
    func get(forKey key: String) -> LLMResponse? {
        // 检查内存缓存
        if let entry = memoryCache[key], !entry.isExpired {
            return entry.response
        }
        
        // 检查磁盘缓存
        do {
            let fileURL = cacheDirectory.appendingPathComponent("\(key.md5).json")
            let data = try Data(contentsOf: fileURL)
            let entry = try JSONDecoder().decode(CacheEntry.self, from: data)
            
            if !entry.isExpired {
                // 恢复到内存缓存
                memoryCache[key] = entry
                return entry.response
            } else {
                // 删除过期缓存
                try? fileManager.removeItem(at: fileURL)
            }
        } catch {
            // 缓存未命中
        }
        
        return nil
    }
    
    func set(_ response: LLMResponse, forKey key: String, expiration: TimeInterval? = nil) {
        let expirationDate = Date().addingTimeInterval(expiration ?? defaultExpiration)
        let entry = CacheEntry(response: response, expirationDate: expirationDate)
        
        // 保存到内存
        memoryCache[key] = entry
        
        // 保存到磁盘
        do {
            let fileURL = cacheDirectory.appendingPathComponent("\(key.md5).json")
            let data = try JSONEncoder().encode(entry)
            try data.write(to: fileURL)
        } catch {
            print("[LLMCache] Failed to save cache: \(error)")
        }
    }
    
    func clear() {
        memoryCache.removeAll()
        
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for file in files {
                try? fileManager.removeItem(at: file)
            }
        } catch {
            print("[LLMCache] Failed to clear cache: \(error)")
        }
    }
    
    func cleanupExpired() {
        // 清理内存中的过期缓存
        memoryCache = memoryCache.filter { !$0.value.isExpired }
        
        // 清理磁盘中的过期缓存
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for file in files {
                if let data = try? Data(contentsOf: file),
                   let entry = try? JSONDecoder().decode(CacheEntry.self, from: data),
                   entry.isExpired {
                    try? fileManager.removeItem(at: file)
                }
            }
        } catch {
            print("[LLMCache] Failed to cleanup cache: \(error)")
        }
    }
}

// MARK: - String Extension for MD5

extension String {
    var md5: String {
        let data = Data(self.utf8)
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_MD5($0.baseAddress, CC_LONG(data.count), &digest)
        }
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
}

import CommonCrypto
