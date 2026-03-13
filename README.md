# AcademicHelper

[![macOS Build & Test](https://github.com/helen03/academic-helper/actions/workflows/macos-build.yml/badge.svg)](https://github.com/helen03/academic-helper/actions/workflows/macos-build.yml)

一款专为 macOS 设计的学术辅助应用，帮助研究人员和学生更高效地进行文献阅读、词汇学习和学术写作。

## 功能特性

### 单词学习模块
- **屏幕取词**：全局监听选中文本，快速查询词典
- **生词本管理**：分类管理，支持搜索和筛选
- **SM-2 复习算法**：科学的间隔重复算法，高效记忆
- **学习统计**：可视化展示学习进度和掌握度

### 文献管理模块
- **PDF 导入**：支持拖拽和文件选择器批量导入
- **PDF 阅读器**：内置阅读器，支持缩放、导航和缩略图
- **词-文献关联**：建立单词与文献的双向关联
- **元数据管理**：自动提取标题、作者、页数等信息

### 写作辅助模块（开发中）
- **学术表达识别**：自动识别并分类学术表达
- **表达库**：收藏和管理常用学术表达
- **智能推荐**：根据上下文推荐替代表达

## 技术栈

- **语言**：Swift 6.0
- **UI框架**：SwiftUI + AppKit
- **架构**：MVVM + 依赖注入
- **数据持久化**：Core Data + CloudKit
- **PDF处理**：PDFKit
- **包管理**：Swift Package Manager

## 项目结构

```
AcademicHelper/
├── Package.swift                    # Swift Package Manager 配置
├── README.md                        # 项目说明
├── docs/                            # 项目文档
│   ├── RESEARCH_REPORT.md          # 调研报告
│   └── PROJECT_PLAN.md             # 项目规划
├── Sources/
│   └── AcademicHelper/
│       ├── AcademicHelper.swift    # 应用入口
│       ├── App/                     # 应用层
│       │   └── ContentView.swift   # 主界面
│       ├── Core/                    # 核心层
│       │   ├── Architecture/       # 架构组件
│       │   │   └── ServiceContainer.swift
│       │   ├── Data/               # 数据层
│       │   │   ├── CoreDataStack.swift
│       │   │   ├── GeneratedEntities.swift
│       │   │   ├── EntityExtensions.swift
│       │   │   ├── WordRepository.swift
│       │   │   ├── LiteratureRepository.swift
│       │   │   └── ExpressionRepository.swift
│       │   ├── Events/             # 事件系统
│       │   │   └── EventBus.swift
│       │   └── Services/           # 服务层
│       │       ├── NotificationManager.swift
│       │       ├── PermissionManager.swift
│       │       ├── WordCaptureService.swift
│       │       ├── DictionaryService.swift
│       │       ├── SRSService.swift
│       │       ├── PDFService.swift
│       │       └── ExpressionRecognitionService.swift
│       ├── Models/                  # 数据模型
│       │   ├── Word.swift
│       │   ├── Literature.swift
│       │   └── AcademicExpression.swift
│       └── Features/                # 功能模块
│           ├── WordLearning/       # 单词学习
│           │   ├── WordLearningView.swift
│           │   ├── WordCapturePopup.swift
│           │   ├── WordDetailView.swift
│           │   ├── VocabularyView.swift
│           │   └── ReviewView.swift
│           ├── LiteratureManagement/ # 文献管理
│           │   ├── LiteratureManagementView.swift
│           │   └── PDFReaderView.swift
│           ├── WritingAssistant/   # 写作辅助（开发中）
│           └── Settings/           # 设置（开发中）
└── Tests/
    └── AcademicHelperTests/        # 单元测试
```

## 开发进度

### Phase 1: 基础设施 ✅ (已完成)
- [x] 项目搭建和架构设计
- [x] Core Data 数据模型
- [x] 依赖注入框架
- [x] 事件总线系统

### Phase 2: 单词学习模块 ✅ (已完成)
- [x] 屏幕取词功能
- [x] 词典查询集成
- [x] 生词本管理
- [x] SM-2 复习算法
- [x] 复习界面
- [x] 学习统计

### Phase 3: 文献管理模块 ✅ (已完成)
- [x] PDF 导入功能
- [x] PDF 阅读器
- [x] 文献列表管理
- [x] 词-文献关联

### Phase 4: 写作辅助模块 🚧 (开发中)
- [ ] 学术表达识别
- [ ] 表达库管理
- [ ] 智能推荐

### Phase 5: 完善和发布 📋 (待开始)
- [ ] iCloud 同步
- [ ] 性能优化
- [ ] 测试和修复
- [ ] App Store 发布

## 快速开始

### 环境要求
- macOS 14.0+
- Xcode 15.0+
- Swift 6.0+

### 构建运行

```bash
# 克隆项目
git clone <repository-url>
cd academic-assistant-app

# 构建项目
swift build

# 运行项目
swift run
```

### 在 Xcode 中打开

```bash
open Package.swift
# 或
xed .
```

## 使用说明

### 屏幕取词
1. 启动应用后，在任意应用中选中文本
2. 自动弹出词典释义窗口
3. 点击"加入生词本"保存单词

### 文献管理
1. 点击"导入 PDF"按钮选择文献
2. 在文献库中双击打开阅读
3. 在阅读器中点击"关联单词"建立联系

### 单词复习
1. 进入"单词学习"模块
2. 点击"开始复习"按钮
3. 根据记忆情况选择评分

## 系统架构

```
┌─────────────────────────────────────────────────────────┐
│                      表现层 (UI)                         │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐    │
│  │  单词学习模块 │ │  文献管理模块 │ │ 写作辅助模块 │    │
│  └──────────────┘ └──────────────┘ └──────────────┘    │
└─────────────────────────────────────────────────────────┘
                           │
┌─────────────────────────────────────────────────────────┐
│                      业务逻辑层                          │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐    │
│  │ 屏幕取词服务 │ │ PDF 处理服务 │ │ 词典查询服务 │    │
│  └──────────────┘ └──────────────┘ └──────────────┘    │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐    │
│  │ 复习算法服务 │ │ 表达识别服务 │ │ 数据同步服务 │    │
│  └──────────────┘ └──────────────┘ └──────────────┘    │
└─────────────────────────────────────────────────────────┘
                           │
┌─────────────────────────────────────────────────────────┐
│                       数据层                             │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐    │
│  │   Core Data  │ │   CloudKit   │ │  文件存储    │    │
│  └──────────────┘ └──────────────┘ └──────────────┘    │
└─────────────────────────────────────────────────────────┘
```

## 核心算法

### SM-2 间隔重复算法

```swift
func calculateNextReview(quality: ReviewQuality, word: Word) -> Word {
    let newEaseFactor = max(1.3, word.easeFactor + 
        (0.1 - (5 - quality.rawValue) * (0.08 + (5 - quality.rawValue) * 0.02)))
    
    var newInterval: Int
    if quality.rawValue < 3 {
        newInterval = 0
    } else if word.reviewCount == 0 {
        newInterval = 1
    } else if word.reviewCount == 1 {
        newInterval = 6
    } else {
        newInterval = Int(Double(word.interval) * newEaseFactor)
    }
    
    // 更新单词并返回
}
```

## 贡献指南

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

## 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情

## 致谢

- [Free Dictionary API](https://dictionaryapi.dev/) - 提供词典数据
- [SuperMemo](https://www.supermemo.com/) - SM-2 算法

## 联系方式

如有问题或建议，欢迎提交 Issue 或联系开发团队。

---

**注意**：本项目正在积极开发中，部分功能可能尚未完全实现。
