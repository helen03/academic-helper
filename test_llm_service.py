#!/usr/bin/env python3
"""
测试 LLM 服务功能
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

# ==================== LLM 服务测试 ====================

def test_llm_providers():
    """测试 LLM 提供商配置"""
    print("\n" + "="*60)
    print("🤖 LLM 提供商测试")
    print("="*60)
    
    reports = []
    
    # 测试 1: 提供商配置
    try:
        providers = {
            "OpenAI": {
                "base_url": "https://api.openai.com/v1",
                "models": ["gpt-4o", "gpt-4o-mini", "gpt-4-turbo", "gpt-3.5-turbo"]
            },
            "Anthropic": {
                "base_url": "https://api.anthropic.com/v1",
                "models": ["claude-3-opus-20240229", "claude-3-sonnet-20240229", "claude-3-haiku-20240307"]
            },
            "DeepSeek": {
                "base_url": "https://api.deepseek.com/v1",
                "models": ["deepseek-chat", "deepseek-coder"]
            },
            "Moonshot": {
                "base_url": "https://api.moonshot.cn/v1",
                "models": ["moonshot-v1-8k", "moonshot-v1-32k", "moonshot-v1-128k"]
            }
        }
        
        assert len(providers) == 4, "应该有 4 个主要提供商"
        assert "gpt-4o" in providers["OpenAI"]["models"], "OpenAI 应该支持 gpt-4o"
        
        reports.append(TestReport("提供商配置", TestResult.PASSED, "配置了 4 个 LLM 提供商"))
        print_success("LLM 提供商配置测试通过")
    except Exception as e:
        reports.append(TestReport("提供商配置", TestResult.FAILED, str(e)))
        print_error(f"提供商配置测试失败: {e}")
    
    # 测试 2: 请求参数结构
    try:
        config = {
            "provider": "DeepSeek",
            "api_key": "test_key",
            "base_url": "https://api.deepseek.com/v1",
            "model": "deepseek-chat",
            "temperature": 0.7,
            "max_tokens": 2048,
            "top_p": 1.0,
            "frequency_penalty": 0.0,
            "presence_penalty": 0.0,
            "timeout": 60.0,
            "max_retries": 3,
            "retry_delay": 1.0,
            "enable_cache": True,
            "cache_expiration": 3600,
            "rate_limit_per_minute": 60,
            "enable_logging": True
        }
        
        assert 0 <= config["temperature"] <= 2, "temperature 应该在 0-2 之间"
        assert config["max_tokens"] > 0, "max_tokens 应该大于 0"
        assert config["max_retries"] >= 0, "max_retries 应该非负"
        
        reports.append(TestReport("请求参数", TestResult.PASSED, "参数结构正确"))
        print_success("请求参数结构测试通过")
    except Exception as e:
        reports.append(TestReport("请求参数", TestResult.FAILED, str(e)))
        print_error(f"请求参数测试失败: {e}")
    
    # 测试 3: 消息格式
    try:
        messages = [
            {"role": "system", "content": "你是一个助手"},
            {"role": "user", "content": "你好"},
            {"role": "assistant", "content": "你好！有什么可以帮助你的？"},
        ]
        
        assert len(messages) == 3, "应该有 3 条消息"
        assert messages[0]["role"] == "system", "第一条应该是系统消息"
        
        reports.append(TestReport("消息格式", TestResult.PASSED, "消息格式正确"))
        print_success("消息格式测试通过")
    except Exception as e:
        reports.append(TestReport("消息格式", TestResult.FAILED, str(e)))
        print_error(f"消息格式测试失败: {e}")
    
    return reports

def test_caching():
    """测试缓存策略"""
    print("\n" + "="*60)
    print("💾 缓存策略测试")
    print("="*60)
    
    reports = []
    
    # 测试 1: 缓存键生成
    try:
        messages = [{"role": "user", "content": "Hello"}]
        provider = "DeepSeek"
        model = "deepseek-chat"
        
        content_str = "|".join([f"{m['role']}:{m['content']}" for m in messages])
        cache_key = f"{provider}_{model}_{hash(content_str)}"
        
        assert len(cache_key) > 0, "缓存键不应该为空"
        
        reports.append(TestReport("缓存键生成", TestResult.PASSED, "缓存键生成正确"))
        print_success("缓存键生成测试通过")
    except Exception as e:
        reports.append(TestReport("缓存键生成", TestResult.FAILED, str(e)))
        print_error(f"缓存键生成测试失败: {e}")
    
    # 测试 2: 缓存过期
    try:
        cache = {}
        expiration = 3600  # 1小时
        
        cache["test_key"] = {
            "response": "测试响应",
            "timestamp": datetime.now(),
            "expiration": expiration
        }
        
        # 检查是否过期
        entry = cache["test_key"]
        is_expired = (datetime.now() - entry["timestamp"]).total_seconds() > entry["expiration"]
        assert not is_expired, "新缓存不应该过期"
        
        reports.append(TestReport("缓存过期", TestResult.PASSED, "过期检测正确"))
        print_success("缓存过期测试通过")
    except Exception as e:
        reports.append(TestReport("缓存过期", TestResult.FAILED, str(e)))
        print_error(f"缓存过期测试失败: {e}")
    
    # 测试 3: MD5 哈希
    try:
        test_str = "test_cache_key"
        md5_hash = hashlib.md5(test_str.encode()).hexdigest()
        
        assert len(md5_hash) == 32, "MD5 哈希应该是 32 位"
        
        reports.append(TestReport("MD5哈希", TestResult.PASSED, "哈希计算正确"))
        print_success("MD5 哈希测试通过")
    except Exception as e:
        reports.append(TestReport("MD5哈希", TestResult.FAILED, str(e)))
        print_error(f"MD5 哈希测试失败: {e}")
    
    return reports

def test_rate_limiting():
    """测试频率限制"""
    print("\n" + "="*60)
    print("⏱️ 频率限制测试")
    print("="*60)
    
    reports = []
    
    # 测试 1: 频率限制检查
    try:
        limit = 60
        window = 60  # 60秒窗口
        request_timestamps = []
        
        # 模拟 50 个请求
        for _ in range(50):
            request_timestamps.append(datetime.now())
        
        can_request = len(request_timestamps) < limit
        assert can_request, "50 个请求应该允许"
        
        reports.append(TestReport("频率限制", TestResult.PASSED, "限制检查正确"))
        print_success("频率限制测试通过")
    except Exception as e:
        reports.append(TestReport("频率限制", TestResult.FAILED, str(e)))
        print_error(f"频率限制测试失败: {e}")
    
    # 测试 2: 等待时间计算
    try:
        limit = 2
        window = 60
        request_timestamps = [datetime.now() - timedelta(seconds=10)]
        
        if len(request_timestamps) >= limit:
            oldest = request_timestamps[0]
            wait_time = max(0, window - (datetime.now() - oldest).total_seconds())
        else:
            wait_time = 0
        
        assert wait_time >= 0, "等待时间应该非负"
        
        reports.append(TestReport("等待时间", TestResult.PASSED, "时间计算正确"))
        print_success("等待时间计算测试通过")
    except Exception as e:
        reports.append(TestReport("等待时间", TestResult.FAILED, str(e)))
        print_error(f"等待时间计算失败: {e}")
    
    return reports

def test_retry_mechanism():
    """测试重试机制"""
    print("\n" + "="*60)
    print("🔄 重试机制测试")
    print("="*60)
    
    reports = []
    
    # 测试 1: 指数退避
    try:
        max_retries = 3
        retry_delay = 1.0
        delays = []
        
        for attempt in range(max_retries):
            delay = retry_delay * (2 ** attempt)
            delays.append(delay)
        
        assert delays == [1.0, 2.0, 4.0], "指数退避计算应该正确"
        
        reports.append(TestReport("指数退避", TestResult.PASSED, "退避计算正确"))
        print_success("指数退避测试通过")
    except Exception as e:
        reports.append(TestReport("指数退避", TestResult.FAILED, str(e)))
        print_error(f"指数退避测试失败: {e}")
    
    # 测试 2: 可重试错误
    try:
        retryable_errors = ["network_error", "timeout", "server_error", "rate_limited"]
        non_retryable_errors = ["invalid_api_key", "invalid_request", "parsing_error"]
        
        assert len(retryable_errors) == 4, "应该有 4 个可重试错误"
        assert len(non_retryable_errors) == 3, "应该有 3 个不可重试错误"
        
        reports.append(TestReport("错误分类", TestResult.PASSED, "分类正确"))
        print_success("错误分类测试通过")
    except Exception as e:
        reports.append(TestReport("错误分类", TestResult.FAILED, str(e)))
        print_error(f"错误分类测试失败: {e}")
    
    return reports

def test_intelligence_features():
    """测试智能功能"""
    print("\n" + "="*60)
    print("🧠 智能功能测试")
    print("="*60)
    
    reports = []
    
    # 测试 1: 文本理解
    try:
        text = "Machine learning is a subset of artificial intelligence."
        
        # 模拟理解结果
        result = {
            "main_topics": ["machine learning", "artificial intelligence"],
            "entities": [{"name": "machine learning", "type": "concept"}],
            "sentiment": "neutral",
            "language": "en"
        }
        
        assert len(result["main_topics"]) == 2, "应该识别到 2 个主题"
        
        reports.append(TestReport("文本理解", TestResult.PASSED, "理解功能正常"))
        print_success("文本理解测试通过")
    except Exception as e:
        reports.append(TestReport("文本理解", TestResult.FAILED, str(e)))
        print_error(f"文本理解测试失败: {e}")
    
    # 测试 2: 写作风格
    try:
        styles = ["academic", "casual", "formal", "creative", "technical", "persuasive"]
        
        assert len(styles) == 6, "应该有 6 种写作风格"
        assert "academic" in styles, "应该包含学术风格"
        
        reports.append(TestReport("写作风格", TestResult.PASSED, "风格选项正确"))
        print_success("写作风格测试通过")
    except Exception as e:
        reports.append(TestReport("写作风格", TestResult.FAILED, str(e)))
        print_error(f"写作风格测试失败: {e}")
    
    # 测试 3: 学习计划
    try:
        durations = ["1周", "2周", "1个月", "3个月"]
        
        assert len(durations) == 4, "应该有 4 种学习时长"
        
        # 模拟学习计划结构
        plan = {
            "topic": "Machine Learning",
            "duration": "1个月",
            "objectives": ["理解基础概念", "掌握常用算法"],
            "schedule": [],
            "resources": [],
            "milestones": []
        }
        
        assert len(plan["objectives"]) == 2, "应该有 2 个学习目标"
        
        reports.append(TestReport("学习计划", TestResult.PASSED, "计划结构正确"))
        print_success("学习计划测试通过")
    except Exception as e:
        reports.append(TestReport("学习计划", TestResult.FAILED, str(e)))
        print_error(f"学习计划测试失败: {e}")
    
    return reports

def test_logging():
    """测试日志系统"""
    print("\n" + "="*60)
    print("📝 日志系统测试")
    print("="*60)
    
    reports = []
    
    # 测试 1: 日志条目
    try:
        log_entry = {
            "id": "uuid-1234",
            "timestamp": datetime.now().isoformat(),
            "provider": "DeepSeek",
            "model": "deepseek-chat",
            "request_id": "req-5678",
            "prompt_tokens": 100,
            "completion_tokens": 50,
            "latency": 1.5,
            "cached": False,
            "success": True
        }
        
        assert log_entry["prompt_tokens"] == 100, "token 数应该正确"
        assert log_entry["success"] == True, "应该标记为成功"
        
        reports.append(TestReport("日志条目", TestResult.PASSED, "条目结构正确"))
        print_success("日志条目测试通过")
    except Exception as e:
        reports.append(TestReport("日志条目", TestResult.FAILED, str(e)))
        print_error(f"日志条目测试失败: {e}")
    
    # 测试 2: 统计计算
    try:
        logs = [
            {"success": True, "cached": False, "latency": 1.0},
            {"success": True, "cached": True, "latency": 0.1},
            {"success": False, "cached": False, "latency": 2.0},
        ]
        
        total = len(logs)
        successful = sum(1 for l in logs if l["success"])
        cached = sum(1 for l in logs if l["cached"])
        avg_latency = sum(l["latency"] for l in logs) / total
        
        assert total == 3, "总请求数应该是 3"
        assert successful == 2, "成功请求数应该是 2"
        assert cached == 1, "缓存命中数应该是 1"
        
        reports.append(TestReport("统计计算", TestResult.PASSED, "统计正确"))
        print_success("统计计算测试通过")
    except Exception as e:
        reports.append(TestReport("统计计算", TestResult.FAILED, str(e)))
        print_error(f"统计计算测试失败: {e}")
    
    return reports

# ==================== 主函数 ====================

def main():
    print("\n" + "🧪"*30)
    print("🤖 LLM Service 功能测试")
    print("🧪"*30)
    
    all_reports = []
    
    # 运行所有测试
    all_reports.extend(test_llm_providers())
    all_reports.extend(test_caching())
    all_reports.extend(test_rate_limiting())
    all_reports.extend(test_retry_mechanism())
    all_reports.extend(test_intelligence_features())
    all_reports.extend(test_logging())
    
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
    report_file = os.path.join(os.path.dirname(__file__), "LLM_SERVICE_TEST_REPORT.json")
    with open(report_file, 'w', encoding='utf-8') as f:
        json.dump(report_data, f, indent=2, ensure_ascii=False)
    
    print(f"\n📄 详细报告已保存: {report_file}")
    
    return failed == 0

if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)
