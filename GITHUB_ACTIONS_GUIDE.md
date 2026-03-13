# GitHub Actions 配置指南

## 📊 免费额度说明

### GitHub Actions 免费额度

| 账户类型 | 存储空间 | 每月运行分钟数 | macOS 计费倍数 |
|---------|---------|--------------|---------------|
| **个人免费版** | 500 MB | **2,000 分钟** | **10x** |
| **Pro 版** | 1 GB | 3,000 分钟 | 10x |

**实际可用时间**：
- Linux (ubuntu): 2,000 分钟/月
- macOS: **200 分钟/月** (2,000 ÷ 10)
- Windows: 1,000 分钟/月 (2,000 ÷ 2)

### 本项目使用情况估算

| 任务 | 运行器 | 预估时间 | 计费分钟 |
|------|--------|---------|---------|
| Python 测试 | ubuntu | ~1 分钟 | 1 分钟 |
| Swift 构建 | macos-14 | ~5 分钟 | 50 分钟 |
| 代码质量检查 | ubuntu | ~1 分钟 | 1 分钟 |
| **单次构建总计** | - | **~7 分钟** | **~52 分钟** |

**每月可构建次数**：约 38 次 (2000 ÷ 52)

---

## 🚀 快速开始

### 1. 创建 GitHub 仓库

```bash
# 在 GitHub 上创建新仓库
# 访问: https://github.com/new

# 仓库名称建议: academic-helper
# 选择 Public（免费无限制）或 Private
```

### 2. 推送代码到 GitHub

```bash
# 进入项目目录
cd /Users/liuyanjun/Documents/trae_projects/academic-assistant-app

# 初始化 git 仓库（如果还没有）
git init

# 添加远程仓库（替换为你的仓库地址）
git remote add origin https://github.com/YOUR_USERNAME/academic-helper.git

# 添加所有文件
git add .

# 提交
git commit -m "Initial commit: AcademicHelper with tests"

# 推送到 GitHub
git push -u origin main
```

### 3. 查看 Actions 运行状态

```bash
# 推送后，GitHub 会自动触发 Actions
# 查看方式:
# 1. 打开 GitHub 仓库页面
# 2. 点击顶部 "Actions" 标签
# 3. 查看工作流运行状态
```

---

## 📁 工作流配置说明

### 工作流文件位置

```
.github/workflows/macos-build.yml
```

### 触发条件

```yaml
on:
  push:
    branches: [ main, develop ]    # 推送到 main 或 develop 分支时触发
  pull_request:
    branches: [ main ]              # 对 main 分支的 PR 触发
  workflow_dispatch:               # 允许手动触发（在 GitHub 页面点击按钮）
```

### 任务流程

```
┌─────────────────┐
│   Python 测试    │  ← ubuntu (免费，快速验证算法)
│  (算法正确性)    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Swift 构建     │  ← macos-14 (消耗 10x 分钟)
│  (验证代码编译)   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   代码质量检查   │  ← ubuntu (统计代码信息)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   生成构建报告   │  ← 汇总所有结果
└─────────────────┘
```

---

## 🎯 使用场景

### 场景 1: 日常开发

每次推送代码时自动运行：

```bash
git add .
git commit -m "Fix: SM-2 algorithm edge case"
git push origin main

# GitHub Actions 会自动:
# 1. 运行 Python 测试验证算法
# 2. 在 macOS 上尝试构建 Swift 代码
# 3. 生成构建报告
```

### 场景 2: 手动触发

在 GitHub 页面手动运行：

1. 打开仓库页面
2. 点击 "Actions" 标签
3. 选择 "macOS Build & Test" 工作流
4. 点击 "Run workflow" 按钮
5. 选择分支，点击 "Run"

### 场景 3: PR 验证

提交 Pull Request 时自动验证：

```bash
git checkout -b feature/new-algorithm
git add .
git commit -m "Add new algorithm"
git push origin feature/new-algorithm

# 在 GitHub 创建 PR
# Actions 会自动运行测试，显示在 PR 页面
```

---

## 📦 构建产物

每次构建后会生成以下产物：

| 产物名称 | 内容 | 保留时间 |
|---------|------|---------|
| python-test-reports | Python 测试报告和覆盖率 | 90 天 |
| build-logs | Swift 构建日志 | 90 天 |
| swift-test-results | Swift 测试结果 | 90 天 |
| build-report | 综合构建报告 | 90 天 |

下载方式：
1. 打开 Actions 运行页面
2. 滚动到底部 "Artifacts" 区域
3. 点击下载

---

## 💡 优化建议

### 1. 节省 macOS 分钟数

```yaml
# 只在特定条件下运行 macOS 构建
swift-build:
  if: github.ref == 'refs/heads/main'  # 只在 main 分支运行
  # 或者
  if: contains(github.event.head_commit.message, '[build]')  # 提交消息包含 [build]
```

### 2. 使用缓存加速

```yaml
- name: Cache Swift packages
  uses: actions/cache@v3
  with:
    path: .build
    key: ${{ runner.os }}-spm-${{ hashFiles('**/Package.resolved') }}
    restore-keys: |
      ${{ runner.os }}-spm-
```

### 3. 并行任务

当前配置已优化：
- Python 测试和代码质量检查 **并行运行**
- Swift 构建 **依赖** Python 测试通过（避免浪费 macOS 分钟）

---

## 🔧 故障排除

### 问题 1: Python 测试失败

```bash
# 本地先验证
cd /Users/liuyanjun/Documents/trae_projects/academic-assistant-app
python3 test_core_logic.py
python3 test_ui_workflows.py
```

### 问题 2: Swift 构建失败

可能原因：
- Package.swift 配置不完整
- 使用了 macOS 专属 API 但环境不支持
- Swift 版本不兼容

解决方案：
```bash
# 本地验证 Swift 包（如果有 Mac）
swift build

# 或者暂时禁用 Swift 构建，只保留 Python 测试
```

### 问题 3: 超出免费额度

错误信息：
```
The job was not started because the account has exceeded the spending limit
```

解决方案：
1. 等待下个月额度重置
2. 购买 GitHub Pro ($4/月，3,000 分钟)
3. 优化工作流减少 macOS 使用

---

## 📚 相关链接

- [GitHub Actions 文档](https://docs.github.com/en/actions)
- [GitHub Actions 定价](https://github.com/pricing)
- [macOS 运行器说明](https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners/about-github-hosted-runners)

---

## ✅ 检查清单

部署前确认：

- [ ] 创建了 GitHub 仓库
- [ ] 推送了代码到仓库
- [ ] 在仓库设置中启用了 Actions
- [ ] 第一次构建成功运行
- [ ] 能够下载构建产物

---

**配置完成后，每次推送代码都会自动在云端验证你的 AcademicHelper 项目！** 🎉
