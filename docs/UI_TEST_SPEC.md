# AcademicHelper UI 测试规范

## 测试概述

本文档定义了 AcademicHelper macOS 应用的 UI 测试和端到端测试规范。由于当前环境限制，使用 Python 脚本模拟测试流程，并生成详细的测试用例供后续在 Xcode 中实现。

## 测试框架

### 推荐框架
- **XCTest** - Apple 官方测试框架
- **XCUITest** - UI 测试专用框架
- **ViewInspector** - SwiftUI 视图测试（可选）

### 测试环境要求
- macOS 14.0+
- Xcode 15.0+
- Swift 6.0+

---

## UI 组件测试矩阵

### 1. 主界面 (ContentView)

| 组件 | 测试项 | 预期结果 | 优先级 |
|------|--------|----------|--------|
| 侧边栏 | 点击单词学习标签 | 显示单词学习模块 | P0 |
| 侧边栏 | 点击文献管理标签 | 显示文献管理模块 | P0 |
| 侧边栏 | 点击写作辅助标签 | 显示写作辅助模块 | P0 |
| 侧边栏 | 点击设置标签 | 显示设置界面 | P0 |
| 窗口 | 调整窗口大小 | 内容自适应布局 | P1 |
| 窗口 | 最小尺寸限制 | 不小于 1200x800 | P1 |

### 2. 单词学习模块 (WordLearningView)

#### 2.1 生词本 (VocabularyView)

| 组件 | 测试项 | 预期结果 | 优先级 |
|------|--------|----------|--------|
| 搜索框 | 输入搜索词 | 实时过滤单词列表 | P0 |
| 搜索框 | 清空搜索 | 显示全部单词 | P0 |
| 筛选器 | 切换筛选条件 | 按条件过滤显示 | P0 |
| 单词列表 | 点击单词行 | 打开单词详情 | P0 |
| 单词列表 | 右键菜单 | 显示删除选项 | P1 |
| 添加按钮 | 点击添加 | 打开添加单词表单 | P0 |
| 统计面板 | 显示统计 | 数字正确更新 | P1 |

#### 2.2 单词详情 (WordDetailView)

| 组件 | 测试项 | 预期结果 | 优先级 |
|------|--------|----------|--------|
| 单词标题 | 显示单词 | 大字体显示 | P0 |
| 音标 | 显示音标 | 正确格式 | P0 |
| 释义 | 显示释义 | 完整内容 | P0 |
| 例句 | 显示例句 | 列表形式 | P0 |
| 复习按钮 | 点击开始复习 | 进入复习界面 | P0 |
| 删除按钮 | 点击删除 | 确认后删除 | P0 |

#### 2.3 复习界面 (ReviewView)

| 组件 | 测试项 | 预期结果 | 优先级 |
|------|--------|----------|--------|
| 进度条 | 显示进度 | 随复习进度更新 | P0 |
| 单词卡片 | 点击翻转 | 显示释义面 | P0 |
| 评分按钮 | 点击评分 | 进入下一单词 | P0 |
| 完成界面 | 显示统计 | 正确数据 | P0 |

#### 2.4 屏幕取词弹窗 (WordCapturePopup)

| 组件 | 测试项 | 预期结果 | 优先级 |
|------|--------|----------|--------|
| 弹窗位置 | 显示位置 | 鼠标位置附近 | P0 |
| 单词显示 | 显示单词 | 大字体 | P0 |
| 释义显示 | 显示释义 | 加载后显示 | P0 |
| 添加按钮 | 点击添加 | 加入生词本 | P0 |
| 详情按钮 | 点击详情 | 打开详情页 | P0 |
| 关闭按钮 | 点击关闭 | 弹窗消失 | P0 |

### 3. 文献管理模块 (LiteratureManagementView)

#### 3.1 文献库 (LiteratureLibraryView)

| 组件 | 测试项 | 预期结果 | 优先级 |
|------|--------|----------|--------|
| 导入按钮 | 点击导入 | 打开文件选择器 | P0 |
| 搜索框 | 输入搜索 | 过滤文献列表 | P0 |
| 文献列表 | 双击文献 | 打开 PDF 阅读器 | P0 |
| 文献列表 | 右键菜单 | 显示操作选项 | P1 |
| 侧边栏 | 切换标签 | 显示对应内容 | P0 |

#### 3.2 PDF 阅读器 (PDFReaderView)

| 组件 | 测试项 | 预期结果 | 优先级 |
|------|--------|----------|--------|
| PDF 显示 | 加载 PDF | 正确渲染 | P0 |
| 页面导航 | 上一页/下一页 | 页面切换 | P0 |
| 缩放控制 | 放大/缩小 | 缩放比例变化 | P0 |
| 侧边栏 | 切换标签 | 显示缩略图/大纲/单词 | P0 |
| 关联单词 | 点击关联 | 打开单词选择器 | P0 |
| 工具栏 | 显示工具 | 功能按钮可用 | P0 |

### 4. 写作辅助模块 (WritingAssistantView)

#### 4.1 写作编辑器 (WritingEditorView)

| 组件 | 测试项 | 预期结果 | 优先级 |
|------|--------|----------|--------|
| 文本输入 | 输入文本 | 正常显示 | P0 |
| 识别按钮 | 点击识别 | 显示识别结果 | P0 |
| 清空按钮 | 点击清空 | 清空输入 | P0 |
| 结果列表 | 显示表达 | 分类显示 | P0 |
| 收藏按钮 | 点击收藏 | 保存到表达库 | P0 |

#### 4.2 表达库 (ExpressionLibraryView)

| 组件 | 测试项 | 预期结果 | 优先级 |
|------|--------|----------|--------|
| 搜索框 | 输入搜索 | 过滤表达 | P0 |
| 分类筛选 | 选择分类 | 按分类过滤 | P0 |
| 表达列表 | 显示表达 | 完整信息 | P0 |
| 收藏夹 | 显示收藏 | 仅显示收藏项 | P0 |

### 5. 设置界面 (SettingsView)

| 组件 | 测试项 | 预期结果 | 优先级 |
|------|--------|----------|--------|
| 标签页 | 切换标签 | 显示对应设置 | P0 |
| 开关 | 切换开关 | 状态改变 | P0 |
| 滑块 | 拖动滑块 | 数值变化 | P0 |
| 选择器 | 选择选项 | 选中项改变 | P0 |
| 快捷键 | 记录快捷键 | 正确记录 | P1 |
| 导出按钮 | 点击导出 | 打开保存对话框 | P0 |
| 导入按钮 | 点击导入 | 打开文件选择器 | P0 |

---

## 端到端测试用例

### 用例 1: 完整的单词学习流程

```gherkin
Feature: 单词学习完整流程

  Scenario: 用户从屏幕取词到完成复习
    Given 应用已启动
    And 屏幕取词功能已启用
    
    When 用户在其他应用中选中单词 "algorithm"
    Then 显示取词弹窗
    And 弹窗中显示单词 "algorithm"
    And 显示词典释义
    
    When 用户点击 "加入生词本" 按钮
    Then 弹窗关闭
    And 单词被添加到生词本
    
    When 用户切换到单词学习模块
    Then 生词本中显示单词 "algorithm"
    
    When 用户点击单词 "algorithm"
    Then 打开单词详情页
    And 显示完整释义和例句
    
    When 用户点击 "开始复习" 按钮
    Then 进入复习界面
    And 显示单词卡片正面
    
    When 用户点击卡片翻转
    Then 显示单词释义
    And 显示评分按钮
    
    When 用户点击 "良好" 评分
    Then 进入下一个单词
    And 复习进度更新
    
    When 用户完成所有单词复习
    Then 显示完成统计界面
    And 显示本次复习数据
```

### 用例 2: 完整的文献管理流程

```gherkin
Feature: 文献管理完整流程

  Scenario: 用户导入文献并关联单词
    Given 应用已启动
    And 用户有 PDF 文件 "paper.pdf"
    
    When 用户点击 "导入 PDF" 按钮
    Then 打开文件选择器
    
    When 用户选择 "paper.pdf"
    Then 文献被导入到文献库
    And 显示文献元数据
    
    When 用户双击文献
    Then 打开 PDF 阅读器
    And 显示 PDF 内容
    
    When 用户点击 "关联单词" 按钮
    Then 打开单词选择器
    And 显示生词本中的单词
    
    When 用户选择单词 "algorithm"
    And 点击确认
    Then 单词与文献建立关联
    And 在阅读器中显示关联单词
    
    When 用户切换到单词详情页
    Then 显示关联的文献 "paper.pdf"
```

### 用例 3: 完整的写作辅助流程

```gherkin
Feature: 写作辅助完整流程

  Scenario: 用户识别并收藏学术表达
    Given 应用已启动
    And 用户切换到写作辅助模块
    
    When 用户在输入框中输入学术文本
    """
    In order to understand the problem, we conducted extensive research.
    As a result, we propose a novel approach to solve this issue.
    """
    Then 文本正常显示在输入框中
    
    When 用户点击 "识别表达" 按钮
    Then 显示识别结果
    And 识别到 "in order to" (过渡连接)
    And 识别到 "As a result" (因果关系)
    And 识别到 "we propose" (研究方法)
    
    When 用户点击表达 "in order to" 的收藏按钮
    Then 表达被保存到表达库
    And 收藏按钮变为选中状态
    
    When 用户切换到表达库
    Then 显示已保存的表达 "in order to"
    And 显示分类 "过渡连接"
    
    When 用户切换到收藏夹
    Then 显示收藏的表达 "in order to"
```

### 用例 4: 数据同步流程

```gherkin
Feature: iCloud 数据同步

  Scenario: 用户启用同步并在多设备间同步数据
    Given 应用已启动
    And 用户已登录 iCloud
    
    When 用户打开设置界面
    And 切换到 "同步" 标签页
    Then 显示同步设置选项
    
    When 用户启用 "iCloud 同步"
    Then 同步状态变为 "已连接"
    And 显示上次同步时间
    
    When 用户在生词本中添加单词 "test"
    Then 单词被添加到本地数据库
    And 触发自动同步
    
    When 同步完成
    Then 更新上次同步时间
    And 数据上传到 iCloud
    
    When 用户在另一台设备上打开应用
    Then 自动从 iCloud 下载数据
    And 显示同步的单词 "test"
```

---

## 性能测试规范

### 启动性能

| 测试项 | 目标值 | 测试方法 |
|--------|--------|----------|
| 冷启动时间 | < 2 秒 | Instruments |
| 热启动时间 | < 1 秒 | Instruments |
| 首屏渲染时间 | < 500ms | XCTMetric |

### 运行时性能

| 测试项 | 目标值 | 测试方法 |
|--------|--------|----------|
| 内存占用 | < 200MB | Activity Monitor |
| CPU 占用 (空闲) | < 5% | Activity Monitor |
| CPU 占用 (取词) | < 20% | Activity Monitor |
| 帧率 | 60 FPS | XCTMetric |

### 大数据量性能

| 测试项 | 数据量 | 目标值 |
|--------|--------|--------|
| 生词本加载 | 10,000 单词 | < 1 秒 |
| 文献库加载 | 1,000 文献 | < 1 秒 |
| 搜索响应 | 10,000 单词 | < 500ms |
| PDF 打开 | 100MB PDF | < 3 秒 |

---

## 无障碍测试规范

### VoiceOver 支持

| 组件 | 要求 |
|------|------|
| 所有按钮 | 有明确的 accessibilityLabel |
| 图片 | 有 accessibilityLabel 或 hidden |
| 动态内容 | 更新时发送通知 |
| 导航 | 支持焦点移动 |

### 键盘导航

| 功能 | 快捷键 |
|------|--------|
| 切换模块 | Cmd + 1/2/3/4 |
| 屏幕取词 | Cmd + Shift + D |
| 快速添加 | Cmd + Shift + A |
| 搜索 | Cmd + F |
| 关闭窗口 | Cmd + W |
| 退出应用 | Cmd + Q |

---

## 测试数据准备

### 测试单词数据

```json
{
  "words": [
    {
      "text": "algorithm",
      "phonetic": "/ˈælɡərɪðəm/",
      "definition": "a process or set of rules to be followed in calculations",
      "partOfSpeech": "noun",
      "examples": ["The algorithm sorts data efficiently."],
      "difficulty": "medium"
    },
    {
      "text": "hypothesis",
      "phonetic": "/haɪˈpɒθəsɪs/",
      "definition": "a supposition or proposed explanation",
      "partOfSpeech": "noun",
      "examples": ["We need to test this hypothesis."],
      "difficulty": "hard"
    }
  ]
}
```

### 测试文献数据

```json
{
  "documents": [
    {
      "title": "Sample Research Paper",
      "authors": ["John Doe", "Jane Smith"],
      "abstract": "This paper presents a novel approach...",
      "pageCount": 10,
      "fileSize": 1024000
    }
  ]
}
```

### 测试表达数据

```json
{
  "expressions": [
    {
      "text": "in order to",
      "category": "transition",
      "meaning": "for the purpose of",
      "examples": ["In order to understand, we must analyze."]
    },
    {
      "text": "as a result",
      "category": "causeEffect",
      "meaning": "therefore",
      "examples": ["As a result, the experiment failed."]
    }
  ]
}
```

---

## 测试自动化脚本

### Python 模拟测试脚本

见 `test_ui_workflows.py` 文件，用于模拟 UI 测试流程并生成测试报告。

### 运行测试

```bash
# 运行 UI 测试
python3 test_ui_workflows.py

# 生成测试报告
python3 test_ui_workflows.py --report
```

---

## 测试覆盖率目标

| 模块 | 目标覆盖率 |
|------|-----------|
| 单词学习模块 | 90% |
| 文献管理模块 | 85% |
| 写作辅助模块 | 85% |
| 设置模块 | 80% |
| 核心服务 | 95% |
| **整体** | **88%** |

---

## 附录

### 测试工具推荐

1. **Xcode Instruments** - 性能分析
2. **Accessibility Inspector** - 无障碍测试
3. **Simulateur** - 模拟不同设备
4. **Charles Proxy** - 网络请求监控

### 参考文档

- [XCUITest Documentation](https://developer.apple.com/documentation/xctest)
- [SwiftUI Testing](https://developer.apple.com/documentation/swiftui/app-essentials)
- [macOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/macos)

---

**文档版本**: 1.0  
**最后更新**: 2024-03-13  
**作者**: AI Assistant
