import Foundation
import Combine

// MARK: - LLM Service Protocol

@MainActor
protocol LLMServiceProtocol {
    func sendRequest(_ request: LLMRequest) async throws -> LLMResponse
    func sendStreamRequest(_ request: LLMRequest) -> AsyncThrowingStream<LLMStreamResponse, Error>
    func validateConfiguration(_ config: LLMConfiguration) async -> Bool
    func getAvailableModels(for provider: LLMProvider) -> [String]
}

// MARK: - LLM Service Implementation

@MainActor
final class LLMService: LLMServiceProtocol {
    
    // MARK: - Properties
    
    private let session: URLSession
    private let cache: LLMCache
    private let rateLimiter: RateLimiter
    private let logger = LLMLogger.shared
    
    // MARK: - Initialization
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: config)
        self.cache = LLMCache()
        self.rateLimiter = RateLimiter(limit: 60, window: 60)
    }
    
    // MARK: - Public Methods
    
    func sendRequest(_ request: LLMRequest) async throws -> LLMResponse {
        let startTime = Date()
        
        // 1. 检查缓存
        if request.config.enableCache, !request.stream {
            if let cachedResponse = cache.get(forKey: request.cacheKey) {
                logger.log(LLMLogger.LLMLogEntry(
                    provider: request.config.provider.rawValue,
                    model: request.config.model,
                    requestId: request.requestId,
                    promptTokens: cachedResponse.usage.promptTokens,
                    completionTokens: cachedResponse.usage.completionTokens,
                    latency: Date().timeIntervalSince(startTime),
                    cached: true,
                    success: true
                ))
                return cachedResponse
            }
        }
        
        // 2. 频率限制检查
        guard rateLimiter.canMakeRequest() else {
            if let waitTime = rateLimiter.waitTime() {
                try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
            }
        }
        
        // 3. 发送请求（带重试）
        let response = try await sendRequestWithRetry(request, startTime: startTime)
        
        // 4. 保存到缓存
        if request.config.enableCache && !request.stream {
            cache.set(response, forKey: request.cacheKey)
        }
        
        // 5. 记录日志
        if request.config.enableLogging {
            logger.log(LLMLogger.LLMLogEntry(
                provider: request.config.provider.rawValue,
                model: request.config.model,
                requestId: request.requestId,
                promptTokens: response.usage.promptTokens,
                completionTokens: response.usage.completionTokens,
                latency: response.latency,
                cached: false,
                success: true
            ))
        }
        
        rateLimiter.recordRequest()
        return response
    }
    
    func sendStreamRequest(_ request: LLMRequest) -> AsyncThrowingStream<LLMStreamResponse, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    guard rateLimiter.canMakeRequest() else {
                        throw LLMError.rateLimited
                    }
                    
                    let urlRequest = try buildURLRequest(for: request)
                    
                    let (asyncBytes, response) = try await session.bytes(for: urlRequest)
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw LLMError.invalidResponse
                    }
                    
                    guard httpResponse.statusCode == 200 else {
                        let errorData = try await asyncBytes.reduce(into: Data()) { $0.append($1) }
                        let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                        throw LLMError.serverError(httpResponse.statusCode, errorMessage)
                    }
                    
                    rateLimiter.recordRequest()
                    
                    var buffer = ""
                    for try await byte in asyncBytes {
                        buffer.append(Character(UnicodeScalar(byte)))
                        
                        if buffer.contains("\n\n") {
                            let lines = buffer.components(separatedBy: "\n\n")
                            buffer = lines.last ?? ""
                            
                            for line in lines.dropLast() {
                                if let streamResponse = parseStreamLine(line, requestId: request.requestId) {
                                    continuation.yield(streamResponse)
                                    
                                    if streamResponse.finishReason != nil {
                                        continuation.finish()
                                        return
                                    }
                                }
                            }
                        }
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    func validateConfiguration(_ config: LLMConfiguration) async -> Bool {
        guard !config.apiKey.isEmpty else { return false }
        guard !config.baseURL.isEmpty else { return false }
        guard !config.model.isEmpty else { return false }
        
        // 尝试发送一个简单的验证请求
        let testRequest = LLMRequest(
            messages: [.user("Hello")],
            config: config,
            stream: false
        )
        
        do {
            _ = try await sendRequest(testRequest)
            return true
        } catch {
            return false
        }
    }
    
    func getAvailableModels(for provider: LLMProvider) -> [String] {
        return provider.availableModels
    }
    
    // MARK: - Private Methods
    
    private func sendRequestWithRetry(_ request: LLMRequest, startTime: Date) async throws -> LLMResponse {
        var lastError: Error?
        
        for attempt in 0..<request.config.maxRetries {
            do {
                return try await performRequest(request, startTime: startTime)
            } catch let error as LLMError where error.isRetryable {
                lastError = error
                let delay = request.config.retryDelay * pow(2.0, Double(attempt))
                print("[LLMService] Request failed, retrying in \(delay)s... (attempt \(attempt + 1)/\(request.config.maxRetries))")
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            } catch {
                throw error
            }
        }
        
        throw lastError ?? LLMError.unknown
    }
    
    private func performRequest(_ request: LLMRequest, startTime: Date) async throws -> LLMResponse {
        let urlRequest = try buildURLRequest(for: request)
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            return try parseResponse(data, request: request, startTime: startTime)
        case 401:
            throw LLMError.invalidAPIKey
        case 429:
            throw LLMError.rateLimited
        case 400...499:
            let errorMessage = String(data: data, encoding: .utf8) ?? "Client error"
            throw LLMError.serverError(httpResponse.statusCode, errorMessage)
        case 500...599:
            let errorMessage = String(data: data, encoding: .utf8) ?? "Server error"
            throw LLMError.serverError(httpResponse.statusCode, errorMessage)
        default:
            throw LLMError.serverError(httpResponse.statusCode, "Unexpected status code")
        }
    }
    
    private func buildURLRequest(for request: LLMRequest) throws -> URLRequest {
        let config = request.config
        
        guard let url = URL(string: "\(config.baseURL)/chat/completions") else {
            throw LLMError.invalidConfiguration
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        
        // 提供商特定的头部
        switch config.provider {
        case .anthropic:
            urlRequest.setValue(config.apiKey, forHTTPHeaderField: "x-api-key")
            urlRequest.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        default:
            break
        }
        
        let body = buildRequestBody(for: request)
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        return urlRequest
    }
    
    private func buildRequestBody(for request: LLMRequest) -> [String: Any] {
        let config = request.config
        
        var body: [String: Any] = [
            "model": config.model,
            "messages": request.messages.map { [
                "role": $0.role.rawValue,
                "content": $0.content
            ]},
            "temperature": config.temperature,
            "max_tokens": config.maxTokens,
            "top_p": config.topP,
            "frequency_penalty": config.frequencyPenalty,
            "presence_penalty": config.presencePenalty,
            "stream": request.stream
        ]
        
        // 提供商特定的参数
        switch config.provider {
        case .anthropic:
            // Anthropic 使用不同的参数结构
            body["max_tokens"] = config.maxTokens
        default:
            break
        }
        
        return body
    }
    
    private func parseResponse(_ data: Data, request: LLMRequest, startTime: Date) throws -> LLMResponse {
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            guard let choices = json?["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let message = firstChoice["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                throw LLMError.parsingError(NSError(domain: "LLMService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"]))
            }
            
            let model = json?["model"] as? String ?? request.config.model
            let finishReason = firstChoice["finish_reason"] as? String
            
            // 解析 usage
            var usage = LLMResponse.TokenUsage(promptTokens: 0, completionTokens: 0, totalTokens: 0)
            if let usageData = json?["usage"] as? [String: Int] {
                usage = LLMResponse.TokenUsage(
                    promptTokens: usageData["prompt_tokens"] ?? 0,
                    completionTokens: usageData["completion_tokens"] ?? 0,
                    totalTokens: usageData["total_tokens"] ?? 0
                )
            }
            
            return LLMResponse(
                requestId: request.requestId,
                content: content,
                model: model,
                usage: usage,
                finishReason: finishReason,
                timestamp: Date(),
                cached: false,
                latency: Date().timeIntervalSince(startTime)
            )
        } catch {
            throw LLMError.parsingError(error)
        }
    }
    
    private func parseStreamLine(_ line: String, requestId: String) -> LLMStreamResponse? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("data: ") else { return nil }
        
        let data = String(trimmed.dropFirst(6))
        
        guard data != "[DONE]" else {
            return LLMStreamResponse(requestId: requestId, delta: "", finishReason: "stop", timestamp: Date())
        }
        
        do {
            if let jsonData = data.data(using: .utf8),
               let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let firstChoice = choices.first,
               let delta = firstChoice["delta"] as? [String: Any] {
                
                let content = delta["content"] as? String ?? ""
                let finishReason = firstChoice["finish_reason"] as? String
                
                return LLMStreamResponse(
                    requestId: requestId,
                    delta: content,
                    finishReason: finishReason,
                    timestamp: Date()
                )
            }
        } catch {
            print("[LLMService] Failed to parse stream line: \(error)")
        }
        
        return nil
    }
}

// MARK: - LLM Error Extension

extension LLMError {
    static let unknown = LLMError.serverError(-1, "Unknown error")
}
