import SwiftUI
import UniformTypeIdentifiers

// MARK: - Data Import/Export View

struct DataImportExportView: View {
    @StateObject private var viewModel = DataImportExportViewModel()
    @State private var showingExportSheet = false
    @State private var showingImportSheet = false
    @State private var showingBackupSheet = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 导出部分
                ExportSection(viewModel: viewModel, showingSheet: $showingExportSheet)
                
                Divider()
                
                // 导入部分
                ImportSection(viewModel: viewModel, showingSheet: $showingImportSheet)
                
                Divider()
                
                // 备份部分
                BackupSection(viewModel: viewModel, showingSheet: $showingBackupSheet)
                
                Divider()
                
                // 最近操作记录
                RecentOperationsSection(viewModel: viewModel)
            }
            .padding()
        }
        .navigationTitle("数据导入导出")
        .sheet(isPresented: $showingExportSheet) {
            ExportConfigurationSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showingImportSheet) {
            ImportConfigurationSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showingBackupSheet) {
            BackupRestoreSheet(viewModel: viewModel)
        }
    }
}

// MARK: - Export Section

struct ExportSection: View {
    @ObservedObject var viewModel: DataImportExportViewModel
    @Binding var showingSheet: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "square.and.arrow.up")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("数据导出")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            Text("将您的学习数据导出为多种格式，方便备份或与其他应用共享。")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // 支持的格式
            VStack(alignment: .leading, spacing: 8) {
                Text("支持的格式")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                FlowLayout(spacing: 8) {
                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        FormatBadge(format: format)
                    }
                }
            }
            
            // 导出按钮
            Button {
                showingSheet = true
            } label: {
                HStack {
                    Image(systemName: "arrow.up.doc")
                    Text("配置导出")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Import Section

struct ImportSection: View {
    @ObservedObject var viewModel: DataImportExportViewModel
    @Binding var showingSheet: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "square.and.arrow.down")
                    .font(.title2)
                    .foregroundColor(.green)
                
                Text("数据导入")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            Text("从其他来源导入学习数据，支持多种文件格式。")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // 支持的来源
            VStack(alignment: .leading, spacing: 8) {
                Text("支持的来源")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                FlowLayout(spacing: 8) {
                    ForEach(ImportSource.allCases, id: \.self) { source in
                        SourceBadge(source: source)
                    }
                }
            }
            
            // 导入按钮
            Button {
                showingSheet = true
            } label: {
                HStack {
                    Image(systemName: "arrow.down.doc")
                    Text("导入数据")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.green)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Backup Section

struct BackupSection: View {
    @ObservedObject var viewModel: DataImportExportViewModel
    @Binding var showingSheet: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "archivebox")
                    .font(.title2)
                    .foregroundColor(.orange)
                
                Text("备份与恢复")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            Text("创建完整的数据备份，或在需要时从备份恢复。")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // 备份状态
            HStack(spacing: 16) {
                BackupStatusCard(
                    title: "上次备份",
                    value: viewModel.lastBackupDate ?? "从未备份",
                    icon: "clock",
                    color: .blue
                )
                
                BackupStatusCard(
                    title: "备份大小",
                    value: viewModel.lastBackupSize ?? "--",
                    icon: "externaldrive",
                    color: .green
                )
            }
            
            // 备份按钮
            Button {
                showingSheet = true
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("备份与恢复")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.orange)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Recent Operations Section

struct RecentOperationsSection: View {
    @ObservedObject var viewModel: DataImportExportViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.title2)
                    .foregroundColor(.purple)
                
                Text("最近操作")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("清除记录") {
                    viewModel.clearHistory()
                }
                .buttonStyle(.link)
            }
            
            if viewModel.recentOperations.isEmpty {
                EmptyOperationsView()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.recentOperations) { operation in
                        OperationRow(operation: operation)
                    }
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Supporting Views

struct FormatBadge: View {
    let format: ExportFormat
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: formatIcon)
            Text(format.rawValue)
        }
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blue.opacity(0.1))
        .foregroundColor(.blue)
        .cornerRadius(4)
    }
    
    private var formatIcon: String {
        switch format {
        case .json: return "curlybraces"
        case .csv: return "tablecells"
        case .xml: return "chevron.left.forwardslash.chevron.right"
        case .anki: return "rectangle.stack"
        case .pdf: return "doc.text"
        }
    }
}

struct SourceBadge: View {
    let source: ImportSource
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: sourceIcon)
            Text(source.rawValue)
        }
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.green.opacity(0.1))
        .foregroundColor(.green)
        .cornerRadius(4)
    }
    
    private var sourceIcon: String {
        switch source {
        case .json: return "curlybraces"
        case .csv: return "tablecells"
        case .anki: return "rectangle.stack"
        case .excel: return "tablecells.fill"
        case .txt: return "text.alignleft"
        }
    }
}

struct BackupStatusCard: View {
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
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.headline)
                .lineLimit(1)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.textBackgroundColor))
        .cornerRadius(8)
    }
}

struct EmptyOperationsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("暂无操作记录")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("导入、导出和备份操作将显示在这里")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

struct OperationRow: View {
    let operation: ImportExportOperation
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: operationIcon)
                .foregroundColor(operationColor)
                .frame(width: 32, height: 32)
                .background(operationColor.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(operation.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(operation.formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            StatusBadge(status: operation.status)
        }
        .padding()
        .background(Color(.textBackgroundColor))
        .cornerRadius(8)
    }
    
    private var operationIcon: String {
        switch operation.type {
        case .export: return "square.and.arrow.up"
        case .import: return "square.and.arrow.down"
        case .backup: return "archivebox"
        case .restore: return "arrow.counterclockwise"
        }
    }
    
    private var operationColor: Color {
        switch operation.type {
        case .export: return .blue
        case .import: return .green
        case .backup: return .orange
        case .restore: return .purple
        }
    }
}

struct StatusBadge: View {
    let status: OperationStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
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
        case .success: return .green
        case .failed: return .red
        case .inProgress: return .blue
        case .cancelled: return .gray
        }
    }
    
    private var statusText: String {
        switch status {
        case .success: return "成功"
        case .failed: return "失败"
        case .inProgress: return "进行中"
        case .cancelled: return "已取消"
        }
    }
}

// MARK: - Export Configuration Sheet

struct ExportConfigurationSheet: View {
    @ObservedObject var viewModel: DataImportExportViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("导出格式") {
                    Picker("格式", selection: $viewModel.selectedExportFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("导出内容") {
                    Toggle("单词数据", isOn: $viewModel.exportWords)
                    Toggle("文献数据", isOn: $viewModel.exportLiterature)
                    Toggle("学术表达", isOn: $viewModel.exportExpressions)
                    Toggle("设置", isOn: $viewModel.exportSettings)
                    Toggle("统计数据", isOn: $viewModel.exportStatistics)
                }
                
                Section("高级选项") {
                    Toggle("压缩文件", isOn: $viewModel.compressionEnabled)
                    Toggle("加密文件", isOn: $viewModel.encryptionEnabled)
                    
                    if viewModel.encryptionEnabled {
                        SecureField("密码", text: $viewModel.encryptionPassword)
                    }
                }
                
                Section("预览") {
                    ExportPreviewView(preview: viewModel.exportPreview)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("导出配置")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("导出") {
                        viewModel.performExport()
                        dismiss()
                    }
                    .disabled(!viewModel.canExport)
                }
            }
        }
        .frame(minWidth: 400, minHeight: 500)
    }
}

struct ExportPreviewView: View {
    let preview: ExportPreview?
    
    var body: some View {
        if let preview = preview {
            VStack(alignment: .leading, spacing: 8) {
                PreviewRow(label: "单词数量", value: "\(preview.totalWords)")
                PreviewRow(label: "文献数量", value: "\(preview.totalLiterature)")
                PreviewRow(label: "表达数量", value: "\(preview.totalExpressions)")
                PreviewRow(label: "预估大小", value: formatFileSize(preview.fileSize))
                PreviewRow(label: "预估时间", value: String(format: "%.1f 秒", preview.estimatedExportTime))
            }
        } else {
            Text("正在计算...")
                .foregroundColor(.secondary)
        }
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

struct PreviewRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
}

// MARK: - Import Configuration Sheet

struct ImportConfigurationSheet: View {
    @ObservedObject var viewModel: DataImportExportViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("选择文件") {
                    Button("选择文件...") {
                        viewModel.selectImportFile()
                    }
                    
                    if let selectedFile = viewModel.selectedImportFile {
                        HStack {
                            Text("已选择")
                            Spacer()
                            Text(selectedFile.lastPathComponent)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("文件来源") {
                    Picker("来源格式", selection: $viewModel.selectedImportSource) {
                        ForEach(ImportSource.allCases, id: \.self) { source in
                            Text(source.rawValue).tag(source)
                        }
                    }
                }
                
                if let validation = viewModel.importValidation {
                    Section("验证结果") {
                        ImportValidationView(validation: validation)
                    }
                }
                
                Section("导入选项") {
                    Toggle("跳过重复项", isOn: $viewModel.skipDuplicates)
                    Toggle("覆盖现有数据", isOn: $viewModel.overwriteExisting)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("导入数据")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("导入") {
                        viewModel.performImport()
                        dismiss()
                    }
                    .disabled(!viewModel.canImport)
                }
            }
        }
        .frame(minWidth: 400, minHeight: 450)
    }
}

struct ImportValidationView: View {
    let validation: ImportValidation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: validation.isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(validation.isValid ? .green : .red)
                Text(validation.isValid ? "文件有效" : "文件无效")
                    .fontWeight(.medium)
            }
            
            if validation.estimatedRecords > 0 {
                Text("预估记录数: \(validation.estimatedRecords)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if !validation.errors.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("错误:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                    ForEach(validation.errors, id: \.self) { error in
                        Text("• \(error)")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            
            if !validation.warnings.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("警告:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                    ForEach(validation.warnings, id: \.self) { warning in
                        Text("• \(warning)")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
    }
}

// MARK: - Backup Restore Sheet

struct BackupRestoreSheet: View {
    @ObservedObject var viewModel: DataImportExportViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("创建备份") {
                    Button {
                        viewModel.createBackup()
                    } label: {
                        HStack {
                            Image(systemName: "archivebox.fill")
                            Text("立即备份")
                        }
                    }
                    .disabled(viewModel.isBackupInProgress)
                    
                    if viewModel.isBackupInProgress {
                        ProgressView()
                            .progressViewStyle(.linear)
                    }
                }
                
                Section("自动备份") {
                    Toggle("启用自动备份", isOn: $viewModel.autoBackupEnabled)
                    
                    if viewModel.autoBackupEnabled {
                        Picker("备份频率", selection: $viewModel.backupFrequency) {
                            Text("每天").tag(BackupFrequency.daily)
                            Text("每周").tag(BackupFrequency.weekly)
                            Text("每月").tag(BackupFrequency.monthly)
                        }
                    }
                }
                
                Section("恢复数据") {
                    Button("从备份恢复...") {
                        viewModel.selectBackupFile()
                    }
                    
                    if viewModel.showingRestoreConfirmation {
                        Text("⚠️ 恢复将覆盖当前所有数据。确定要继续吗？")
                            .font(.caption)
                            .foregroundColor(.red)
                        
                        Button("确认恢复") {
                            viewModel.performRestore()
                            dismiss()
                        }
                        .foregroundColor(.red)
                    }
                }
                
                Section("备份历史") {
                    if viewModel.backupHistory.isEmpty {
                        Text("暂无备份记录")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(viewModel.backupHistory) { backup in
                            BackupHistoryRow(backup: backup)
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("备份与恢复")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .frame(minWidth: 400, minHeight: 500)
    }
}

struct BackupHistoryRow: View {
    let backup: BackupRecord
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(backup.formattedDate)
                    .font(.subheadline)
                Text(formatFileSize(backup.size))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button {
                // 恢复此备份
            } label: {
                Image(systemName: "arrow.counterclockwise")
            }
            .buttonStyle(.borderless)
        }
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - View Model

@MainActor
class DataImportExportViewModel: ObservableObject {
    @Published var selectedExportFormat: ExportFormat = .json
    @Published var exportWords = true
    @Published var exportLiterature = true
    @Published var exportExpressions = true
    @Published var exportSettings = false
    @Published var exportStatistics = false
    @Published var compressionEnabled = false
    @Published var encryptionEnabled = false
    @Published var encryptionPassword = ""
    @Published var exportPreview: ExportPreview?
    
    @Published var selectedImportSource: ImportSource = .json
    @Published var selectedImportFile: URL?
    @Published var importValidation: ImportValidation?
    @Published var skipDuplicates = true
    @Published var overwriteExisting = false
    
    @Published var autoBackupEnabled = false
    @Published var backupFrequency: BackupFrequency = .weekly
    @Published var isBackupInProgress = false
    @Published var showingRestoreConfirmation = false
    @Published var backupHistory: [BackupRecord] = []
    
    @Published var lastBackupDate: String? = nil
    @Published var lastBackupSize: String? = nil
    @Published var recentOperations: [ImportExportOperation] = []
    
    var canExport: Bool {
        exportWords || exportLiterature || exportExpressions || exportSettings || exportStatistics
    }
    
    var canImport: Bool {
        selectedImportFile != nil && (importValidation?.isValid ?? false)
    }
    
    func performExport() {
        // 实现导出逻辑
        let operation = ImportExportOperation(
            type: .export,
            title: "导出 \(selectedExportFormat.rawValue) 文件",
            date: Date(),
            status: .success
        )
        recentOperations.insert(operation, at: 0)
    }
    
    func selectImportFile() {
        // 打开文件选择器
    }
    
    func performImport() {
        let operation = ImportExportOperation(
            type: .import,
            title: "导入 \(selectedImportSource.rawValue) 文件",
            date: Date(),
            status: .success
        )
        recentOperations.insert(operation, at: 0)
    }
    
    func createBackup() {
        isBackupInProgress = true
        // 实现备份逻辑
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.isBackupInProgress = false
            let operation = ImportExportOperation(
                type: .backup,
                title: "数据备份",
                date: Date(),
                status: .success
            )
            self.recentOperations.insert(operation, at: 0)
        }
    }
    
    func selectBackupFile() {
        showingRestoreConfirmation = true
    }
    
    func performRestore() {
        let operation = ImportExportOperation(
            type: .restore,
            title: "数据恢复",
            date: Date(),
            status: .success
        )
        recentOperations.insert(operation, at: 0)
    }
    
    func clearHistory() {
        recentOperations.removeAll()
    }
}

// MARK: - Supporting Types

enum BackupFrequency {
    case daily, weekly, monthly
}

enum OperationType {
    case export, import, backup, restore
}

enum OperationStatus {
    case success, failed, inProgress, cancelled
}

struct ImportExportOperation: Identifiable {
    let id = UUID()
    let type: OperationType
    let title: String
    let date: Date
    let status: OperationStatus
    
    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct BackupRecord: Identifiable {
    let id = UUID()
    let date: Date
    let size: Int64
    let url: URL
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Preview

struct DataImportExportView_Previews: PreviewProvider {
    static var previews: some View {
        DataImportExportView()
    }
}
