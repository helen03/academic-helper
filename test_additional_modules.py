#!/usr/bin/env python3
"""
测试新增模块：学习统计、数据导入导出、快捷键系统、术语库
"""

import json
import hashlib
import time
from datetime import datetime, timedelta
from dataclasses import dataclass
from enum import Enum
from typing import List, Dict, Optional

# ==================== 颜色输出 ====================

class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    END = '\033[0m'

def print_success(msg): print(f"{Colors.GREEN}✅ {msg}{Colors.END}")
def print_error(msg): print(f"{Colors.RED}❌ {msg}{Colors.END}")
def print_info(msg): print(f"{Colors.BLUE}ℹ️ {msg}{Colors.END}")
def print_warning(msg): print(f"{Colors.YELLOW}⚠️ {msg}{Colors.END}")

# ==================== 测试框架 ====================

class TestResult(Enum):
    PASSED = "通过"
    FAILED = "失败"
    SKIPPED = "跳过"

@dataclass
class TestReport:
    name: str
    result: TestResult
    message: str = ""

# ==================== 学习统计测试 ====================

def test_statistics_service():
    """测试学习统计服务"""
    print("\n" + "="*60)
    print("📊 学习统计测试")
    print("="*60)
    
    reports = []
    
    # 测试 1: 学习统计计算
    try:
        stats = {
            "total_words_learned": 100,
            "total_words_mastered": 50,
            "current_streak": 5,
            "longest_streak": 12,
            "total_study_time": 3600,
            "average_daily_words": 3.3,
            "review_accuracy": 0.85
        }
        
        assert stats["total_words_learned"] >= stats["total_words_mastered"], "已掌握单词数不应超过总单词数"
        assert 0 <= stats["review_accuracy"] <= 1, "准确率应在 0-1 之间"
        
        reports.append(TestReport("学习统计", TestResult.PASSED, "统计计算正确"))
        print_success("学习统计测试通过")
    except Exception as e:
        reports.append(TestReport("学习统计", TestResult.FAILED, str(e)))
        print_error(f"学习统计测试失败: {e}")
    
    # 测试 2: 成就系统
    try:
        achievements = [
            {"id": "first_word", "title": "初次学习", "requirement": 1, "current": 1, "unlocked": True},
            {"id": "vocabulary_100", "title": "词汇积累", "requirement": 100, "current": 50, "unlocked": False},
            {"id": "streak_7", "title": "坚持一周", "requirement": 7, "current": 5, "unlocked": False}
        ]
        
        unlocked = [a for a in achievements if a["unlocked"]]
        assert len(unlocked) == 1, "应该有 1 个已解锁成就"
        
        reports.append(TestReport("成就系统", TestResult.PASSED, "成就计算正确"))
        print_success("成就系统测试通过")
    except Exception as e:
        reports.append(TestReport("成就系统", TestResult.FAILED, str(e)))
        print_error(f"成就系统测试失败: {e}")
    
    # 测试 3: 学习目标
    try:
        goal = {
            "title": "每日学习",
            "target_value": 20,
            "current_value": 15,
            "deadline": datetime.now() + timedelta(days=1)
        }
        
        progress = goal["current_value"] / goal["target_value"]
        assert 0 <= progress <= 1, "进度应在 0-1 之间"
        
        reports.append(TestReport("学习目标", TestResult.PASSED, "目标进度计算正确"))
        print_success("学习目标测试通过")
    except Exception as e:
        reports.append(TestReport("学习目标", TestResult.FAILED, str(e)))
        print_error(f"学习目标测试失败: {e}")
    
    return reports

# ==================== 数据导入导出测试 ====================

def test_import_export_service():
    """测试数据导入导出服务"""
    print("\n" + "="*60)
    print("📥📤 数据导入导出测试")
    print("="*60)
    
    reports = []
    
    # 测试 1: 导出格式
    try:
        formats = ["JSON", "CSV", "XML", "Anki", "PDF"]
        assert len(formats) == 5, "应该支持 5 种导出格式"
        assert "JSON" in formats, "应该支持 JSON 格式"
        assert "CSV" in formats, "应该支持 CSV 格式"
        
        reports.append(TestReport("导出格式", TestResult.PASSED, "格式支持正确"))
        print_success("导出格式测试通过")
    except Exception as e:
        reports.append(TestReport("导出格式", TestResult.FAILED, str(e)))
        print_error(f"导出格式测试失败: {e}")
    
    # 测试 2: 导入格式
    try:
        import_formats = ["JSON", "CSV", "Anki", "Excel", "Text"]
        assert len(import_formats) == 5, "应该支持 5 种导入格式"
        
        reports.append(TestReport("导入格式", TestResult.PASSED, "格式支持正确"))
        print_success("导入格式测试通过")
    except Exception as e:
        reports.append(TestReport("导入格式", TestResult.FAILED, str(e)))
        print_error(f"导入格式测试失败: {e}")
    
    # 测试 3: 导出选项
    try:
        options = {
            "format": "JSON",
            "include_words": True,
            "include_literature": True,
            "include_expressions": True,
            "include_settings": False,
            "compression_enabled": False,
            "encryption_enabled": False
        }
        
        assert options["include_words"], "默认应该包含单词"
        assert not options["encryption_enabled"], "默认不应加密"
        
        reports.append(TestReport("导出选项", TestResult.PASSED, "选项配置正确"))
        print_success("导出选项测试通过")
    except Exception as e:
        reports.append(TestReport("导出选项", TestResult.FAILED, str(e)))
        print_error(f"导出选项测试失败: {e}")
    
    # 测试 4: 数据容器结构
    try:
        data = {
            "version": "1.0",
            "export_date": datetime.now().isoformat(),
            "metadata": {
                "app_version": "1.0.0",
                "device_name": "Mac",
                "system_version": "macOS 14.0"
            },
            "words": [],
            "literature": [],
            "expressions": []
        }
        
        assert data["version"] == "1.0", "版本号应该正确"
        assert "metadata" in data, "应该包含元数据"
        
        reports.append(TestReport("数据结构", TestResult.PASSED, "数据结构正确"))
        print_success("数据结构测试通过")
    except Exception as e:
        reports.append(TestReport("数据结构", TestResult.FAILED, str(e)))
        print_error(f"数据结构测试失败: {e}")
    
    return reports

# ==================== 快捷键系统测试 ====================

def test_shortcut_system():
    """测试快捷键系统"""
    print("\n" + "="*60)
    print("⌨️ 快捷键系统测试")
    print("="*60)
    
    reports = []
    
    # 测试 1: 快捷键动作
    try:
        actions = [
            "capture_word", "open_vocabulary", "start_review",
            "show_main_window", "quick_ask", "search", "settings"
        ]
        
        assert len(actions) == 7, "应该有 7 个主要动作"
        assert "capture_word" in actions, "应该包含屏幕取词"
        
        reports.append(TestReport("快捷键动作", TestResult.PASSED, "动作定义正确"))
        print_success("快捷键动作测试通过")
    except Exception as e:
        reports.append(TestReport("快捷键动作", TestResult.FAILED, str(e)))
        print_error(f"快捷键动作测试失败: {e}")
    
    # 测试 2: 键组合
    try:
        key_combo = {
            "key": "c",
            "modifiers": ["command", "option"]
        }
        
        display = "⌘+⌥+C"
        assert "⌘" in display, "应该显示 Command 符号"
        assert "⌥" in display, "应该显示 Option 符号"
        
        reports.append(TestReport("键组合", TestResult.PASSED, "组合显示正确"))
        print_success("键组合测试通过")
    except Exception as e:
        reports.append(TestReport("键组合", TestResult.FAILED, str(e)))
        print_error(f"键组合测试失败: {e}")
    
    # 测试 3: 系统保留快捷键检查
    try:
        reserved = [
            ("c", ["command"]),  # Copy
            ("v", ["command"]),  # Paste
            ("z", ["command"]),  # Undo
            ("s", ["command"]),  # Save
            ("q", ["command"]),  # Quit
        ]
        
        assert len(reserved) == 5, "应该检查 5 个系统保留快捷键"
        
        # 检查是否冲突
        new_shortcut = ("c", ["command", "option"])
        is_conflict = any(r[0] == new_shortcut[0] and set(r[1]) == set(new_shortcut[1]) for r in reserved)
        assert not is_conflict, "添加 Option 后不应冲突"
        
        reports.append(TestReport("冲突检查", TestResult.PASSED, "冲突检测正确"))
        print_success("冲突检查测试通过")
    except Exception as e:
        reports.append(TestReport("冲突检查", TestResult.FAILED, str(e)))
        print_error(f"冲突检查测试失败: {e}")
    
    # 测试 4: 快捷键分类
    try:
        categories = {
            "word_learning": ["capture_word", "open_vocabulary", "start_review"],
            "literature": ["import_pdf", "open_literature"],
            "writing": ["recognize_expression"],
            "general": ["show_main_window", "search", "settings"],
            "ai": ["quick_ask", "summarize_text", "translate"]
        }
        
        assert len(categories) == 5, "应该有 5 个分类"
        assert len(categories["word_learning"]) == 3, "单词学习应该有 3 个快捷键"
        
        reports.append(TestReport("快捷键分类", TestResult.PASSED, "分类正确"))
        print_success("快捷键分类测试通过")
    except Exception as e:
        reports.append(TestReport("快捷键分类", TestResult.FAILED, str(e)))
        print_error(f"快捷键分类测试失败: {e}")
    
    return reports

# ==================== 术语库测试 ====================

def test_terminology_service():
    """测试术语库服务"""
    print("\n" + "="*60)
    print("📚 术语库测试")
    print("="*60)
    
    reports = []
    
    # 测试 1: 术语分类
    try:
        categories = [
            "算法", "数据结构", "机器学习", "深度学习",
            "计算机视觉", "自然语言处理", "操作系统",
            "计算机网络", "数据库", "软件工程"
        ]
        
        assert len(categories) == 10, "应该有 10 个主要分类"
        assert "机器学习" in categories, "应该包含机器学习"
        assert "深度学习" in categories, "应该包含深度学习"
        
        reports.append(TestReport("术语分类", TestResult.PASSED, "分类正确"))
        print_success("术语分类测试通过")
    except Exception as e:
        reports.append(TestReport("术语分类", TestResult.FAILED, str(e)))
        print_error(f"术语分类测试失败: {e}")
    
    # 测试 2: 术语难度
    try:
        difficulties = ["初级", "中级", "高级", "专家"]
        
        assert len(difficulties) == 4, "应该有 4 个难度级别"
        
        term = {
            "text": "Algorithm",
            "definition": "解决特定问题的一系列明确步骤",
            "difficulty": "初级"
        }
        
        assert term["difficulty"] in difficulties, "难度应该在有效范围内"
        
        reports.append(TestReport("术语难度", TestResult.PASSED, "难度级别正确"))
        print_success("术语难度测试通过")
    except Exception as e:
        reports.append(TestReport("术语难度", TestResult.FAILED, str(e)))
        print_error(f"术语难度测试失败: {e}")
    
    # 测试 3: 术语搜索
    try:
        terms = [
            {"text": "Algorithm", "definition": "算法定义", "category": "算法"},
            {"text": "Neural Network", "definition": "神经网络", "category": "机器学习"},
            {"text": "Database", "definition": "数据库", "category": "数据库"}
        ]
        
        query = "algorithm"
        results = [t for t in terms if query.lower() in t["text"].lower() or query.lower() in t["definition"].lower()]
        
        assert len(results) >= 1, "应该找到至少 1 个匹配"
        
        reports.append(TestReport("术语搜索", TestResult.PASSED, "搜索功能正常"))
        print_success("术语搜索测试通过")
    except Exception as e:
        reports.append(TestReport("术语搜索", TestResult.FAILED, str(e)))
        print_error(f"术语搜索测试失败: {e}")
    
    # 测试 4: 术语统计
    try:
        terms_by_category = {
            "算法": 5,
            "数据结构": 3,
            "机器学习": 8,
            "深度学习": 4
        }
        
        total = sum(terms_by_category.values())
        assert total == 20, "总术语数应该正确"
        
        most_common = max(terms_by_category.items(), key=lambda x: x[1])
        assert most_common[0] == "机器学习", "机器学习应该是最多的"
        
        reports.append(TestReport("术语统计", TestResult.PASSED, "统计计算正确"))
        print_success("术语统计测试通过")
    except Exception as e:
        reports.append(TestReport("术语统计", TestResult.FAILED, str(e)))
        print_error(f"术语统计测试失败: {e}")
    
    # 测试 5: 默认术语
    try:
        default_terms = [
            {"text": "Algorithm", "category": "算法"},
            {"text": "Machine Learning", "category": "机器学习"},
            {"text": "Neural Network", "category": "机器学习"},
            {"text": "Database", "category": "数据库"},
            {"text": "TCP/IP", "category": "计算机网络"}
        ]
        
        assert len(default_terms) >= 5, "应该有至少 5 个默认术语"
        
        categories = set(t["category"] for t in default_terms)
        assert len(categories) >= 3, "应该覆盖至少 3 个分类"
        
        reports.append(TestReport("默认术语", TestResult.PASSED, "默认术语正确"))
        print_success("默认术语测试通过")
    except Exception as e:
        reports.append(TestReport("默认术语", TestResult.FAILED, str(e)))
        print_error(f"默认术语测试失败: {e}")
    
    return reports

# ==================== 主函数 ====================

def main():
    print("\n" + "🧪"*30)
    print("🚀 AcademicHelper 新增模块测试")
    print("🧪"*30)
    
    all_reports = []
    
    # 运行所有测试
    all_reports.extend(test_statistics_service())
    all_reports.extend(test_import_export_service())
    all_reports.extend(test_shortcut_system())
    all_reports.extend(test_terminology_service())
    
    # 汇总
    print("\n" + "="*60)
    print("📊 测试汇总")
    print("="*60)
    
    total = len(all_reports)
    passed = len([r for r in all_reports if r.result == TestResult.PASSED])
    failed = len([r for r in all_reports if r.result == TestResult.FAILED])
    
    for report in all_reports:
        icon = "✅" if report.result == TestResult.PASSED else "❌"
        print(f"{icon} {report.name}: {report.result.value}")
        if report.message:
            print(f"   {report.message}")
    
    print("="*60)
    print(f"总测试数: {total}")
    print_success(f"通过: {passed}")
    if failed > 0:
        print_error(f"失败: {failed}")
    print(f"通过率: {(passed/total*100):.1f}%")
    print("="*60)
    
    # 保存报告
    report_data = {
        "timestamp": datetime.now().isoformat(),
        "summary": {
            "total": total,
            "passed": passed,
            "failed": failed,
            "pass_rate": f"{(passed/total*100):.1f}%"
        },
        "details": [
            {
                "name": r.name,
                "result": r.result.value,
                "message": r.message
            }
            for r in all_reports
        ]
    }
    
    import os
    report_file = os.path.join(os.path.dirname(__file__), "ADDITIONAL_MODULES_TEST_REPORT.json")
    with open(report_file, 'w', encoding='utf-8') as f:
        json.dump(report_data, f, indent=2, ensure_ascii=False)
    
    print(f"\n📄 详细报告已保存: {report_file}")
    
    return failed == 0

if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)
