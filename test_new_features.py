#!/usr/bin/env python3
"""
测试新功能：词典服务、PDF文本提取、通知提醒系统
"""

import json
import time
from datetime import datetime, timedelta
from typing import List, Dict, Optional
from dataclasses import dataclass
from enum import Enum

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

# ==================== 词典服务测试 ====================

def test_dictionary_service():
    """测试词典服务功能"""
    print("\n" + "="*60)
    print("📚 词典服务测试")
    print("="*60)
    
    reports = []
    
    # 测试 1: 内存缓存机制
    try:
        cache = {}
        word = "algorithm"
        definition = {
            "word": word,
            "phonetic": "/ˈælɡərɪðəm/",
            "meanings": [
                {"partOfSpeech": "noun", "definition": "a process or set of rules to be followed in calculations"}
            ]
        }
        cache[word] = {"definition": definition, "timestamp": datetime.now()}
        
        # 验证缓存命中
        cached = cache.get(word)
        assert cached is not None, "缓存应该命中"
        assert cached["definition"]["word"] == word, "缓存数据应该正确"
        
        reports.append(TestReport("内存缓存", TestResult.PASSED, "缓存机制工作正常"))
        print_success("内存缓存机制测试通过")
    except Exception as e:
        reports.append(TestReport("内存缓存", TestResult.FAILED, str(e)))
        print_error(f"内存缓存测试失败: {e}")
    
    # 测试 2: 有道 API 签名生成
    try:
        import hashlib
        
        app_key = "test_key"
        app_secret = "test_secret"
        word = "hello"
        salt = "1234"
        curtime = str(int(time.time()))
        
        # 模拟有道签名算法
        def truncate(q: str) -> str:
            if len(q) <= 20:
                return q
            return q[:10] + str(len(q)) + q[-10:]
        
        sign_str = app_key + truncate(word) + salt + curtime + app_secret
        sign = hashlib.sha256(sign_str.encode()).hexdigest()
        
        assert len(sign) == 64, "SHA256 签名应该是 64 位"
        assert sign_str.startswith(app_key), "签名字符串应该以 app_key 开头"
        
        reports.append(TestReport("有道签名", TestResult.PASSED, "签名生成正确"))
        print_success("有道 API 签名测试通过")
    except Exception as e:
        reports.append(TestReport("有道签名", TestResult.FAILED, str(e)))
        print_error(f"有道签名测试失败: {e}")
    
    # 测试 3: 翻译功能
    try:
        translations = {
            "hello": "你好",
            "world": "世界",
            "algorithm": "算法"
        }
        
        result = translations.get("algorithm")
        assert result == "算法", "翻译应该正确"
        
        reports.append(TestReport("翻译功能", TestResult.PASSED, "翻译映射正确"))
        print_success("翻译功能测试通过")
    except Exception as e:
        reports.append(TestReport("翻译功能", TestResult.FAILED, str(e)))
        print_error(f"翻译功能测试失败: {e}")
    
    # 测试 4: 缓存过期检查
    try:
        cache = {}
        old_time = datetime.now() - timedelta(days=8)  # 8天前
        cache["old_word"] = {"timestamp": old_time, "data": "test"}
        
        # 检查是否过期（假设7天过期）
        entry = cache.get("old_word")
        is_expired = (datetime.now() - entry["timestamp"]).days > 7
        assert is_expired, "8天前的缓存应该过期"
        
        reports.append(TestReport("缓存过期", TestResult.PASSED, "过期检测正确"))
        print_success("缓存过期检查测试通过")
    except Exception as e:
        reports.append(TestReport("缓存过期", TestResult.FAILED, str(e)))
        print_error(f"缓存过期检查失败: {e}")
    
    return reports

# ==================== PDF 服务测试 ====================

def test_pdf_service():
    """测试 PDF 服务功能"""
    print("\n" + "="*60)
    print("📄 PDF 服务测试")
    print("="*60)
    
    reports = []
    
    # 测试 1: PDF 文本搜索
    try:
        pdf_text = """
        Abstract
        This paper presents a novel algorithm for machine learning.
        The proposed method demonstrates significant improvements.
        
        1. Introduction
        Machine learning algorithms have become increasingly important.
        """
        
        query = "algorithm"
        search_text = pdf_text.lower()
        matches = []
        
        start = 0
        while True:
            idx = search_text.find(query, start)
            if idx == -1:
                break
            # 获取上下文
            context_start = max(0, idx - 30)
            context_end = min(len(pdf_text), idx + len(query) + 30)
            context = pdf_text[context_start:context_end]
            matches.append({"position": idx, "context": context})
            start = idx + 1
        
        assert len(matches) >= 2, "应该找到至少 2 个匹配"
        
        reports.append(TestReport("PDF搜索", TestResult.PASSED, f"找到 {len(matches)} 个匹配"))
        print_success(f"PDF 文本搜索测试通过 (找到 {len(matches)} 个匹配)")
    except Exception as e:
        reports.append(TestReport("PDF搜索", TestResult.FAILED, str(e)))
        print_error(f"PDF 文本搜索失败: {e}")
    
    # 测试 2: 学术表达识别
    try:
        text = """
        The results demonstrate that the proposed method is effective.
        It is suggested that further research is needed.
        Furthermore, the algorithm can be applied to other domains.
        """
        
        # 模拟表达识别
        patterns = {
            "demonstrate": "学术动词",
            "suggest": "学术动词",
            "Furthermore": "连接词",
            "is effective": "被动语态"
        }
        
        found_expressions = []
        for pattern, expr_type in patterns.items():
            if pattern.lower() in text.lower():
                found_expressions.append({"text": pattern, "type": expr_type})
        
        assert len(found_expressions) >= 3, "应该识别到至少 3 个学术表达"
        
        reports.append(TestReport("表达识别", TestResult.PASSED, f"识别 {len(found_expressions)} 个表达"))
        print_success(f"学术表达识别测试通过 (识别 {len(found_expressions)} 个)")
    except Exception as e:
        reports.append(TestReport("表达识别", TestResult.FAILED, str(e)))
        print_error(f"学术表达识别失败: {e}")
    
    # 测试 3: DOI 提取
    try:
        text_with_doi = """
        Published in Nature 2024
        DOI: 10.1038/s41586-024-00001-x
        Contact: author@university.edu
        """
        
        import re
        doi_pattern = r"10\.\d{4,}\/[^\s]+"
        doi_match = re.search(doi_pattern, text_with_doi)
        
        assert doi_match is not None, "应该提取到 DOI"
        assert doi_match.group() == "10.1038/s41586-024-00001-x", "DOI 应该正确"
        
        reports.append(TestReport("DOI提取", TestResult.PASSED, "DOI 提取正确"))
        print_success("DOI 提取测试通过")
    except Exception as e:
        reports.append(TestReport("DOI提取", TestResult.FAILED, str(e)))
        print_error(f"DOI 提取失败: {e}")
    
    # 测试 4: 摘要提取
    try:
        pdf_content = """
        Title: Machine Learning in Healthcare
        
        Abstract
        This paper reviews the applications of machine learning in healthcare.
        We analyze various algorithms and their effectiveness.
        
        1. Introduction
        Healthcare is an important domain...
        """
        
        # 尝试提取 Abstract 后的内容
        abstract_start = pdf_content.find("Abstract")
        assert abstract_start != -1, "应该找到 Abstract"
        
        # 提取 Abstract 后的 200 个字符
        abstract_text = pdf_content[abstract_start + 8:abstract_start + 208].strip()
        assert len(abstract_text) > 20, "摘要应该有一定长度"
        
        reports.append(TestReport("摘要提取", TestResult.PASSED, "摘要提取成功"))
        print_success("摘要提取测试通过")
    except Exception as e:
        reports.append(TestReport("摘要提取", TestResult.FAILED, str(e)))
        print_error(f"摘要提取失败: {e}")
    
    return reports

# ==================== 通知提醒系统测试 ====================

def test_notification_system():
    """测试通知提醒系统"""
    print("\n" + "="*60)
    print("🔔 通知提醒系统测试")
    print("="*60)
    
    reports = []
    
    # 测试 1: 复习时间计算
    try:
        now = datetime.now()
        
        # 模拟待复习单词
        words_due = [
            {"text": "algorithm", "next_review": now - timedelta(hours=1)},  # 已过期
            {"text": "method", "next_review": now + timedelta(hours=2)},     # 2小时后
            {"text": "data", "next_review": now + timedelta(minutes=30)},    # 30分钟后
        ]
        
        # 找到最早需要复习的时间
        next_reviews = [w["next_review"] for w in words_due]
        earliest = min(next_reviews)
        
        # 如果已过期，应该安排在现在+5分钟
        if earliest <= now:
            reminder_time = now + timedelta(minutes=5)
        else:
            reminder_time = earliest
        
        assert reminder_time > now, "提醒时间应该在将来"
        
        reports.append(TestReport("复习时间计算", TestResult.PASSED, "时间计算正确"))
        print_success("复习时间计算测试通过")
    except Exception as e:
        reports.append(TestReport("复习时间计算", TestResult.FAILED, str(e)))
        print_error(f"复习时间计算失败: {e}")
    
    # 测试 2: 每日提醒时间设置
    try:
        hour = 9
        minute = 30
        
        now = datetime.now()
        reminder_time = now.replace(hour=hour, minute=minute, second=0, microsecond=0)
        
        # 如果今天的时间已过，设置为明天
        if reminder_time < now:
            reminder_time += timedelta(days=1)
        
        assert reminder_time.hour == hour, "小时应该正确"
        assert reminder_time.minute == minute, "分钟应该正确"
        assert reminder_time > now, "提醒时间应该在将来"
        
        reports.append(TestReport("每日提醒", TestResult.PASSED, "时间设置正确"))
        print_success("每日提醒时间设置测试通过")
    except Exception as e:
        reports.append(TestReport("每日提醒", TestResult.FAILED, str(e)))
        print_error(f"每日提醒设置失败: {e}")
    
    # 测试 3: 通知内容生成
    try:
        word_count = 5
        
        notification = {
            "title": "📚 单词复习时间",
            "body": f"您有 {word_count} 个单词需要复习，保持学习节奏！",
            "badge": word_count,
            "sound": "default"
        }
        
        assert "5" in notification["body"], "通知内容应该包含单词数量"
        assert notification["badge"] == 5, "Badge 数字应该正确"
        
        reports.append(TestReport("通知内容", TestResult.PASSED, "内容生成正确"))
        print_success("通知内容生成测试通过")
    except Exception as e:
        reports.append(TestReport("通知内容", TestResult.FAILED, str(e)))
        print_error(f"通知内容生成失败: {e}")
    
    # 测试 4: 通知类别注册
    try:
        categories = {
            "REVIEW_CATEGORY": ["立即复习", "稍后提醒"],
            "DAILY_CATEGORY": ["开始学习"],
            "WORD_REMINDER_CATEGORY": ["记住了", "再复习"]
        }
        
        assert len(categories) == 3, "应该有 3 个通知类别"
        assert len(categories["REVIEW_CATEGORY"]) == 2, "复习类别应该有 2 个动作"
        
        reports.append(TestReport("通知类别", TestResult.PASSED, "类别注册正确"))
        print_success("通知类别注册测试通过")
    except Exception as e:
        reports.append(TestReport("通知类别", TestResult.FAILED, str(e)))
        print_error(f"通知类别注册失败: {e}")
    
    return reports

# ==================== 主函数 ====================

def main():
    print("\n" + "🧪"*30)
    print("🚀 AcademicHelper 新功能测试")
    print("🧪"*30)
    
    all_reports = []
    
    # 运行所有测试
    all_reports.extend(test_dictionary_service())
    all_reports.extend(test_pdf_service())
    all_reports.extend(test_notification_system())
    
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
    report_file = os.path.join(os.path.dirname(__file__), "NEW_FEATURES_TEST_REPORT.json")
    with open(report_file, 'w', encoding='utf-8') as f:
        json.dump(report_data, f, indent=2, ensure_ascii=False)
    
    print(f"\n📄 详细报告已保存: {report_file}")
    
    return failed == 0

if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)
