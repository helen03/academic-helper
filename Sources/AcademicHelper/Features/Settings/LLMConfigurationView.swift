import SwiftUI

// MARK: - LLM Configuration View

struct LLMConfigurationView: View {
    @StateObject private var viewModel = LLMConfigurationViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 提供商选择
                ProviderSection(viewModel: viewModel)
                
                Divider()
                
                // API配置
                APIConfigurationSection(viewModel: viewModel)
                
                Divider()
                
                // 模型参数
                ModelParametersSection(viewModel: viewModel)
                
                Divider()
                
                // 高级设置
                AdvancedSettingsSection(viewModel: viewModel)
                
                Divider()
                
                // 使用统计
                UsageStatisticsSection(viewModel: viewModel)
                
                Divider()
                
                // 测试连接
                TestConnectionSection(viewModel: viewModel)
            }
            .padding()
        }
        .navigationTitle("AI 模型配置")
    }
}

// MARK: - Provider Section

struct ProviderSection: View {
    @ObservedObject var viewModel: LLMConfigurationViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "network")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("服务提供商")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            Text("选择您想要使用的 AI 服务提供商。每个提供商提供不同的模型和功能。")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 12) {
                ForEach(LLMProvider.allCases) { provider in
                    ProviderCard(
                        provider: provider,
                        isSelected: viewModel.selectedProvider == provider,
                        action: { viewModel.selectProvider(provider) }
                    )
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct ProviderCard: View {
    let provider: LLMProvider
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: providerIcon)
                    .font(.system(size: 32))
                    .foregroundColor(isSelected ? .white : providerColor)
                
                Text(provider.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(provider.models.count, format: .number)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    + Text(" 个模型")
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? providerColor : Color(.textBackgroundColor))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
    
    private var providerIcon: String {
        switch provider {
        case .openAI: return "bubble.left.fill"
        case .anthropic: return "sparkles"
        case .deepseek: return "magnifyingglass.circle.fill"
        case .moonshot: return "moon.stars.fill"
        }
    }
    
    private var providerColor: Color {
        switch provider {
        case .openAI: return .green
        case .anthropic: return .purple
        case .deepseek: return .blue
        case .moonshot: return .orange
        }
    }
}

// MARK: - API Configuration Section

struct APIConfigurationSection: View {
    @ObservedObject var viewModel: LLMConfigurationViewModel
    @State private var showingAPIKey = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "key.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
                
                Text("API 配置")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                ConnectionStatusBadge(status: viewModel.connectionStatus)
            }
            
            // API Key
            VStack(alignment: .leading, spacing: 8) {
                Text("API Key")
                    .font(.caption)
                    .fontWeight(.medium)
                
                HStack {
                    if showingAPIKey {
                        TextField("输入 API Key", text: $viewModel.apiKey)
                    } else {
                        SecureField("输入 API Key", text: $viewModel.apiKey)
                    }
                    
                    Button {
                        showingAPIKey.toggle()
                    } label: {
                        Image(systemName: showingAPIKey ? "eye.slash" : "eye")
                    }
                    .buttonStyle(.borderless)
                }
                .textFieldStyle(.roundedBorder)
            }
            
            // Base URL (可自定义)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Base URL")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Toggle("自定义", isOn: $viewModel.useCustomBaseURL)
                        .toggleStyle(.switch)
                        .controlSize(.small)
                }
                
                if viewModel.useCustomBaseURL {
                    TextField("https://api.example.com/v1", text: $viewModel.customBaseURL)
                        .textFieldStyle(.roundedBorder)
                } else {
                    Text(viewModel.defaultBaseURL)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                }
            }
            
            // 模型选择
            VStack(alignment: .leading, spacing: 8) {
                Text("模型")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Picker("选择模型", selection: $viewModel.selectedModel) {
                    ForEach(viewModel.availableModels, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct ConnectionStatusBadge: View {
    let status: ConnectionStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(statusText)
        }
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.1))
        .foregroundColor(statusColor)
        .cornerRadius(4)
    }
    
    private var statusColor: Color {
        switch status {
        case .connected: return .green
        case .disconnected: return .red
        case .testing: return .blue
        case .unknown: return .gray
        }
    }
    
    private var statusText: String {
        switch status {
        case .connected: return "已连接"
        case .disconnected: return "未连接"
        case .testing: return "测试中"
        case .unknown: return "未测试"
        }
    }
}

// MARK: - Model Parameters Section

struct ModelParametersSection: View {
    @ObservedObject var viewModel: LLMConfigurationViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .font(.title2)
                    .foregroundColor(.purple)
                
                Text("模型参数")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("重置默认") {
                    viewModel.resetToDefaults()
                }
                .buttonStyle(.link)
            }
            
            Text("调整模型生成文本的参数。这些参数会影响输出的创造性和多样性。")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Temperature
            ParameterSlider(
                title: "Temperature",
                value: $viewModel.temperature,
                range: 0...2,
                step: 0.1,
                description: "控制输出的随机性。较低值使输出更确定，较高值使输出更多样。"
            )
            
            // Max Tokens
            ParameterSlider(
                title: "最大 Token 数",
                value: Binding(
                    get: { Double(viewModel.maxTokens) },
                    set: { viewModel.maxTokens = Int($0) }
                ),
                range: 100...8000,
                step: 100,
                description: "限制生成的最大 token 数量。"
            )
            
            // Top P
            ParameterSlider(
                title: "Top P",
                value: $viewModel.topP,
                range: 0...1,
                step: 0.05,
                description: "核采样参数。控制模型考虑的 token 范围。"
            )
            
            // Frequency Penalty
            ParameterSlider(
                title: "频率惩罚",
                value: $viewModel.frequencyPenalty,
                range: -2...2,
                step: 0.1,
                description: "降低重复 token 的概率。正值减少重复。"
            )
            
            // Presence Penalty
            ParameterSlider(
                title: "存在惩罚",
                value: $viewModel.presencePenalty,
                range: -2...2,
                step: 0.1,
                description: "增加新话题的概率。正值鼓励多样性。"
            )
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct ParameterSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(String(format: "%.2f", value))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
            
            Slider(value: $value, in: range, step: step)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Advanced Settings Section

struct AdvancedSettingsSection: View {
    @ObservedObject var viewModel: LLMConfigurationViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "gearshape.2")
                    .font(.title2)
                    .foregroundColor(.gray)
                
                Text("高级设置")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            // 缓存设置
            VStack(alignment: .leading, spacing: 8) {
                Toggle("启用响应缓存", isOn: $viewModel.enableCache)
                
                if viewModel.enableCache {
                    HStack {
                        Text("缓存大小")
                        Spacer()
                        Text(viewModel.cacheSizeDescription)
                            .foregroundColor(.secondary)
                    }
                    .font(.subheadline)
                    
                    Button("清除缓存") {
                        viewModel.clearCache()
                    }
                    .buttonStyle(.link)
                }
            }
            
            Divider()
            
            // 日志设置
            VStack(alignment: .leading, spacing: 8) {
                Toggle("启用请求日志", isOn: $viewModel.enableLogging)
                
                if viewModel.enableLogging {
                    HStack {
                        Text("日志保留天数")
                        Spacer()
                        Picker("", selection: $viewModel.logRetentionDays) {
                            Text("7 天").tag(7)
                            Text("30 天").tag(30)
                            Text("90 天").tag(90)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 200)
                    }
                    
                    Button("查看日志") {
                        viewModel.showLogs()
                    }
                    .buttonStyle(.link)
                }
            }
            
            Divider()
            
            // 超时设置
            VStack(alignment: .leading, spacing: 8) {
                Text("请求超时")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Picker("超时时间", selection: $viewModel.timeoutSeconds) {
                    Text("30 秒").tag(30)
                    Text("60 秒").tag(60)
                    Text("120 秒").tag(120)
                    Text("300 秒").tag(300)
                }
                .pickerStyle(.segmented)
            }
            
            Divider()
            
            // 重试设置
            VStack(alignment: .leading, spacing: 8) {
                Toggle("自动重试失败请求", isOn: $viewModel.enableRetry)
                
                if viewModel.enableRetry {
                    HStack {
                        Text("最大重试次数")
                        Spacer()
                        Stepper("\(viewModel.maxRetries)", value: $viewModel.maxRetries, in: 1...5)
                    }
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Usage Statistics Section

struct UsageStatisticsSection: View {
    @ObservedObject var viewModel: LLMConfigurationViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                
                Text("使用统计")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Picker("时间范围", selection: $viewModel.statisticsTimeRange) {
                    Text("今天").tag(TimeRange.today)
                    Text("本周").tag(TimeRange.thisWeek)
                    Text("本月").tag(TimeRange.thisMonth)
                    Text("全部").tag(TimeRange.allTime)
                }
                .pickerStyle(.segmented)
                .frame(width: 250)
            }
            
            // 统计卡片
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatCard(
                    title: "总请求数",
                    value: "\(viewModel.totalRequests)",
                    icon: "number",
                    color: .blue
                )
                
                StatCard(
                    title: "Token 使用量",
                    value: viewModel.totalTokensFormatted,
                    icon: "textformat",
                    color: .green
                )
                
                StatCard(
                    title: "平均响应时间",
                    value: viewModel.averageLatencyFormatted,
                    icon: "clock",
                    color: .orange
                )
                
                StatCard(
                    title: "缓存命中率",
                    value: viewModel.cacheHitRateFormatted,
                    icon: "arrow.clockwise",
                    color: .purple
                )
            }
            
            // 费用估算
            if viewModel.estimatedCost > 0 {
                HStack {
                    Image(systemName: "dollarsign.circle")
                        .foregroundColor(.green)
                    Text("预估费用: $\(String(format: "%.4f", viewModel.estimatedCost))")
                        .font(.subheadline)
                    Spacer()
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.textBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Test Connection Section

struct TestConnectionSection: View {
    @ObservedObject var viewModel: LLMConfigurationViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "bolt.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)
                
                Text("测试连接")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            Text("发送测试请求以验证 API 配置是否正确。")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // 测试输入
            VStack(alignment: .leading, spacing: 8) {
                Text("测试消息")
                    .font(.caption)
                    .fontWeight(.medium)
                
                TextEditor(text: $viewModel.testMessage)
                    .font(.body)
                    .frame(height: 80)
                    .padding(4)
                    .background(Color(.textBackgroundColor))
                    .cornerRadius(8)
            }
            
            // 测试按钮
            Button {
                viewModel.testConnection()
            } label: {
                HStack {
                    if viewModel.isTesting {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "play.fill")
                    }
                    Text(viewModel.isTesting ? "测试中..." : "发送测试请求")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(viewModel.isTesting || viewModel.apiKey.isEmpty)
            
            // 测试结果
            if let result = viewModel.testResult {
                TestResultView(result: result)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct TestResultView: View {
    let result: TestResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(result.success ? .green : .red)
                
                Text(result.success ? "测试成功" : "测试失败")
                    .font(.headline)
                
                Spacer()
                
                if let latency = result.latency {
                    Text("\(String(format: "%.2f", latency))s")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let response = result.response {
                Text("响应:")
                    .font(.caption)
                    .fontWeight(.medium)
                
                ScrollView {
                    Text(response)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 100)
                .padding(8)
                .background(Color(.textBackgroundColor))
                .cornerRadius(8)
            }
            
            if let error = result.error {
                Text("错误: \(error)")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(result.success ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - View Model

@MainActor
class LLMConfigurationViewModel: ObservableObject {
    // 提供商
    @Published var selectedProvider: LLMProvider = .openAI
    
    // API 配置
    @Published var apiKey: String = ""
    @Published var useCustomBaseURL = false
    @Published var customBaseURL: String = ""
    @Published var selectedModel: String = ""
    @Published var connectionStatus: ConnectionStatus = .unknown
    
    // 模型参数
    @Published var temperature: Double = 0.7
    @Published var maxTokens: Int = 2000
    @Published var topP: Double = 1.0
    @Published var frequencyPenalty: Double = 0.0
    @Published var presencePenalty: Double = 0.0
    
    // 高级设置
    @Published var enableCache = true
    @Published var enableLogging = true
    @Published var logRetentionDays = 30
    @Published var timeoutSeconds = 60
    @Published var enableRetry = true
    @Published var maxRetries = 3
    
    // 统计
    @Published var statisticsTimeRange: TimeRange = .today
    @Published var totalRequests: Int = 0
    @Published var totalTokens: Int = 0
    @Published var averageLatency: Double = 0
    @Published var cacheHitRate: Double = 0
    @Published var estimatedCost: Double = 0
    
    // 测试
    @Published var testMessage: String = "Hello, this is a test message."
    @Published var isTesting = false
    @Published var testResult: TestResult?
    
    var defaultBaseURL: String {
        selectedProvider.baseURL
    }
    
    var availableModels: [String] {
        selectedProvider.availableModels
    }
    
    var cacheSizeDescription: String {
        "12.5 MB" // 示例
    }
    
    var totalTokensFormatted: String {
        if totalTokens >= 1000000 {
            return String(format: "%.1fM", Double(totalTokens) / 1000000)
        } else if totalTokens >= 1000 {
            return String(format: "%.1fK", Double(totalTokens) / 1000)
        }
        return "\(totalTokens)"
    }
    
    var averageLatencyFormatted: String {
        String(format: "%.0f ms", averageLatency * 1000)
    }
    
    var cacheHitRateFormatted: String {
        String(format: "%.1f%%", cacheHitRate * 100)
    }
    
    init() {
        selectedModel = availableModels.first ?? ""
    }
    
    func selectProvider(_ provider: LLMProvider) {
        selectedProvider = provider
        selectedModel = availableModels.first ?? ""
        connectionStatus = .unknown
    }
    
    func resetToDefaults() {
        temperature = 0.7
        maxTokens = 2000
        topP = 1.0
        frequencyPenalty = 0.0
        presencePenalty = 0.0
    }
    
    func clearCache() {
        // 清除缓存逻辑
    }
    
    func showLogs() {
        // 显示日志逻辑
    }
    
    func testConnection() {
        isTesting = true
        connectionStatus = .testing
        
        // 模拟测试
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let success = !self.apiKey.isEmpty
            self.testResult = TestResult(
                success: success,
                response: success ? "API 连接成功！模型 \(self.selectedModel) 可用。" : nil,
                error: success ? nil : "API Key 无效或网络连接失败",
                latency: 1.23
            )
            self.connectionStatus = success ? .connected : .disconnected
            self.isTesting = false
        }
    }
}

// MARK: - Supporting Types

enum ConnectionStatus {
    case connected, disconnected, testing, unknown
}

enum TimeRange {
    case today, thisWeek, thisMonth, allTime
}

struct TestResult {
    let success: Bool
    let response: String?
    let error: String?
    let latency: Double?
}

// MARK: - Preview

struct LLMConfigurationView_Previews: PreviewProvider {
    static var previews: some View {
        LLMConfigurationView()
    }
}
