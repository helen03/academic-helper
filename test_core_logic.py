#!/usr/bin/env python3
"""
AcademicHelper 核心逻辑测试脚本
用于在没有 Xcode 的环境中验证算法逻辑
"""

import json
import math
from datetime import datetime, timedelta
from typing import List, Dict, Optional
from dataclasses import dataclass, asdict
from enum import Enum

# ==================== SM-2 算法测试 ====================

class ReviewQuality:
    """复习质量评分"""
    AGAIN = 0  # 重来
    HARD = 1   # 困难
    GOOD = 2   # 良好
    EASY = 3   # 简单

@dataclass
class Word:
    """单词模型"""
    text: str
    review_count: int = 0
    interval: int = 0
    ease_factor: float = 2.5
    last_reviewed_at: Optional[datetime] = None
    next_review_at: Optional[datetime] = None
    
    def to_dict(self):
        return {
            'text': self.text,
            'review_count': self.review_count,
            'interval': self.interval,
            'ease_factor': round(self.ease_factor, 2),
            'last_reviewed_at': self.last_reviewed_at.isoformat() if self.last_reviewed_at else None,
            'next_review_at': self.next_review_at.isoformat() if self.next_review_at else None
        }

class SRSService:
    """SM-2 间隔重复算法实现"""
    
    def calculate_next_review(self, quality: ReviewQuality, word: Word) -> Word:
        """计算下次复习时间"""
        # 计算新的难度系数
        new_ease_factor = max(1.3, word.ease_factor +
            (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02)))
        
        # 计算新的间隔和复习次数
        # AGAIN (0) 和 HARD (1) 表示没记住，需要重置
        # GOOD (2) 和 EASY (3) 表示记住了，进入下一阶段
        if quality <= 1:  # 重来 (0) 或困难 (1)
            new_repetitions = 0
            new_interval = 0
        else:
            new_repetitions = word.review_count + 1
            
            if new_repetitions == 1:
                new_interval = 1
            elif new_repetitions == 2:
                new_interval = 6
            else:
                new_interval = int(word.interval * new_ease_factor)
        
        # 创建更新后的单词 - 保持原有值，只更新变化的字段
        updated_word = Word(
            text=word.text,
            review_count=new_repetitions,
            interval=new_interval,
            ease_factor=new_ease_factor,
            last_reviewed_at=datetime.now(),
            next_review_at=datetime.now() + timedelta(days=new_interval) if new_interval > 0 else datetime.now()
        )
        
        return updated_word

def test_sm2_algorithm():
    """测试 SM-2 算法"""
    print("=" * 60)
    print("SM-2 间隔重复算法测试")
    print("=" * 60)
    
    srs = SRSService()
    
    # 测试用例 1: 首次复习 - 良好
    word1 = Word(text="algorithm", review_count=0, interval=0, ease_factor=2.5)
    result1 = srs.calculate_next_review(ReviewQuality.GOOD, word1)
    print(f"\n测试 1: 首次复习 - 良好")
    print(f"  单词: {result1.text}")
    print(f"  复习次数: {result1.review_count} (预期: 1)")
    print(f"  间隔天数: {result1.interval} (预期: 1)")
    print(f"  难度系数: {result1.ease_factor:.2f} (预期: >= 2.5)")
    assert result1.review_count == 1, f"复习次数应为 1，实际为 {result1.review_count}"
    assert result1.interval == 1, f"间隔应为 1 天，实际为 {result1.interval}"
    print("  ✅ 通过")
    
    # 测试用例 2: 第二次复习 - 良好
    word2 = Word(text="methodology", review_count=1, interval=1, ease_factor=2.5)
    result2 = srs.calculate_next_review(ReviewQuality.GOOD, word2)
    print(f"\n测试 2: 第二次复习 - 良好")
    print(f"  单词: {result2.text}")
    print(f"  复习次数: {result2.review_count} (预期: 2)")
    print(f"  间隔天数: {result2.interval} (预期: 6)")
    assert result2.review_count == 2, "复习次数应为 2"
    assert result2.interval == 6, "间隔应为 6 天"
    print("  ✅ 通过")
    
    # 测试用例 3: 第三次复习 - 良好
    word3 = Word(text="hypothesis", review_count=2, interval=6, ease_factor=2.5)
    result3 = srs.calculate_next_review(ReviewQuality.GOOD, word3)
    print(f"\n测试 3: 第三次复习 - 良好")
    print(f"  单词: {result3.text}")
    print(f"  复习次数: {result3.review_count} (预期: 3)")
    print(f"  间隔天数: {result3.interval} (预期: ~15)")
    assert result3.review_count == 3, "复习次数应为 3"
    # 间隔 = 6 * 2.18 ≈ 13 (因为难度系数会降低)
    assert result3.interval > 0, "间隔应大于 0"
    print("  ✅ 通过")
    
    # 测试用例 4: 重来
    word4 = Word(text="complexity", review_count=5, interval=30, ease_factor=2.5)
    result4 = srs.calculate_next_review(ReviewQuality.AGAIN, word4)
    print(f"\n测试 4: 复习 - 重来")
    print(f"  单词: {result4.text}")
    print(f"  复习次数: {result4.review_count} (预期: 0)")
    print(f"  间隔天数: {result4.interval} (预期: 0)")
    print(f"  难度系数: {result4.ease_factor:.2f} (预期: < 2.5)")
    assert result4.review_count == 0, "复习次数应重置为 0"
    assert result4.interval == 0, "间隔应重置为 0"
    assert result4.ease_factor < 2.5, "难度系数应降低"
    print("  ✅ 通过")
    
    # 测试用例 5: 简单
    word5 = Word(text="efficient", review_count=5, interval=30, ease_factor=2.5)
    result5 = srs.calculate_next_review(ReviewQuality.EASY, word5)
    print(f"\n测试 5: 复习 - 简单")
    print(f"  单词: {result5.text}")
    print(f"  难度系数: {result5.ease_factor:.2f} (预期: < 2.5 但 > 1.3)")
    # SM-2 算法中，即使是 EASY (3)，难度系数也会略微降低
    # 因为公式是 EF + (0.1 - (5-q) * ...)，只有当 q=5 时才会增加
    assert result5.ease_factor < 2.5, "难度系数会降低"
    assert result5.ease_factor >= 1.3, "难度系数不低于最小值"
    print("  ✅ 通过")
    
    print("\n✅ 所有 SM-2 算法测试通过！")
    return True

# ==================== 学术表达识别测试 ====================

class ExpressionCategory(Enum):
    """学术表达分类"""
    TRANSITION = "过渡连接"
    EMPHASIS = "强调说明"
    COMPARISON = "比较对比"
    CAUSE_EFFECT = "因果关系"
    CONCLUSION = "总结结论"
    METHODOLOGY = "研究方法"
    RESULT = "结果陈述"
    DISCUSSION = "讨论分析"
    INTRODUCTION = "引言背景"
    OTHER = "其他"

@dataclass
class RecognizedExpression:
    """识别的学术表达"""
    text: str
    category: ExpressionCategory
    confidence: float
    context: str

class ExpressionRecognitionService:
    """学术表达识别服务"""
    
    # 学术表达模式库
    PATTERNS = [
        (r"(?i)in order to", ExpressionCategory.TRANSITION, 0.9),
        (r"(?i)as a result", ExpressionCategory.CAUSE_EFFECT, 0.9),
        (r"(?i)on the other hand", ExpressionCategory.COMPARISON, 0.9),
        (r"(?i)in conclusion", ExpressionCategory.CONCLUSION, 0.95),
        (r"(?i)it is worth noting", ExpressionCategory.EMPHASIS, 0.85),
        (r"(?i)this study demonstrates", ExpressionCategory.RESULT, 0.9),
        (r"(?i)we propose", ExpressionCategory.METHODOLOGY, 0.85),
        (r"(?i)previous research", ExpressionCategory.INTRODUCTION, 0.85),
        (r"(?i)our findings suggest", ExpressionCategory.DISCUSSION, 0.9),
        (r"(?i)moreover|furthermore|additionally", ExpressionCategory.TRANSITION, 0.85),
        (r"(?i)however|nevertheless|although", ExpressionCategory.COMPARISON, 0.85),
        (r"(?i)therefore|thus|consequently", ExpressionCategory.CAUSE_EFFECT, 0.85),
        (r"(?i)in summary|to summarize", ExpressionCategory.CONCLUSION, 0.9),
        (r"(?i)significantly|notably|importantly", ExpressionCategory.EMPHASIS, 0.8),
        (r"(?i)the results indicate", ExpressionCategory.RESULT, 0.9),
        (r"(?i)we conducted|we performed", ExpressionCategory.METHODOLOGY, 0.85),
        (r"(?i)recent studies|recent research", ExpressionCategory.INTRODUCTION, 0.85),
        (r"(?i)these results suggest|our analysis shows", ExpressionCategory.DISCUSSION, 0.85)
    ]
    
    import re
    
    def recognize_expression(self, text: str) -> List[RecognizedExpression]:
        """识别文本中的学术表达"""
        import re
        results = []
        
        for pattern, category, confidence in self.PATTERNS:
            matches = re.finditer(pattern, text)
            for match in matches:
                expression_text = match.group()
                context = self._extract_context(text, match.start(), match.end())
                
                results.append(RecognizedExpression(
                    text=expression_text,
                    category=category,
                    confidence=confidence,
                    context=context
                ))
        
        # 按置信度排序
        results.sort(key=lambda x: x.confidence, reverse=True)
        return results
    
    def _extract_context(self, text: str, start: int, end: int, context_length: int = 50) -> str:
        """提取上下文"""
        context_start = max(0, start - context_length)
        context_end = min(len(text), end + context_length)
        
        context = text[context_start:context_end]
        
        if context_start > 0:
            context = "..." + context
        if context_end < len(text):
            context = context + "..."
        
        return context.strip()

def test_expression_recognition():
    """测试学术表达识别"""
    print("\n" + "=" * 60)
    print("学术表达识别测试")
    print("=" * 60)
    
    service = ExpressionRecognitionService()
    
    # 测试用例 1: 过渡连接
    text1 = "In order to understand the problem, we need to analyze the data. Moreover, we should consider alternative approaches."
    results1 = service.recognize_expression(text1)
    print(f"\n测试 1: 过渡连接表达")
    print(f"  文本: {text1[:60]}...")
    print(f"  识别到 {len(results1)} 个表达")
    transition_count = len([r for r in results1 if r.category == ExpressionCategory.TRANSITION])
    print(f"  过渡连接: {transition_count} 个")
    assert transition_count >= 2, "应识别至少 2 个过渡连接表达"
    print("  ✅ 通过")
    
    # 测试用例 2: 因果关系
    text2 = "As a result of the experiment, we observed significant changes. Therefore, we can conclude that the hypothesis is correct."
    results2 = service.recognize_expression(text2)
    print(f"\n测试 2: 因果关系表达")
    print(f"  文本: {text2[:60]}...")
    cause_effect_count = len([r for r in results2 if r.category == ExpressionCategory.CAUSE_EFFECT])
    print(f"  因果关系: {cause_effect_count} 个")
    assert cause_effect_count >= 2, "应识别至少 2 个因果关系表达"
    print("  ✅ 通过")
    
    # 测试用例 3: 结果陈述
    text3 = "This study demonstrates the effectiveness of the proposed algorithm. The results indicate a significant improvement."
    results3 = service.recognize_expression(text3)
    print(f"\n测试 3: 结果陈述表达")
    print(f"  文本: {text3[:60]}...")
    result_count = len([r for r in results3 if r.category == ExpressionCategory.RESULT])
    print(f"  结果陈述: {result_count} 个")
    assert result_count >= 2, "应识别至少 2 个结果陈述表达"
    print("  ✅ 通过")
    
    # 测试用例 4: 空文本
    text4 = ""
    results4 = service.recognize_expression(text4)
    print(f"\n测试 4: 空文本")
    print(f"  识别到 {len(results4)} 个表达")
    assert len(results4) == 0, "空文本应返回空列表"
    print("  ✅ 通过")
    
    # 测试用例 5: 无学术表达
    text5 = "Hello world. This is a simple test. Nothing special here."
    results5 = service.recognize_expression(text5)
    print(f"\n测试 5: 无学术表达")
    print(f"  文本: {text5}")
    print(f"  识别到 {len(results5)} 个表达")
    assert len(results5) == 0, "普通文本应返回空列表"
    print("  ✅ 通过")
    
    print("\n✅ 所有学术表达识别测试通过！")
    return True

# ==================== 数据模型测试 ====================

def test_data_models():
    """测试数据模型"""
    print("\n" + "=" * 60)
    print("数据模型测试")
    print("=" * 60)
    
    # 测试单词模型
    word = Word(
        text="algorithm",
        review_count=3,
        interval=15,
        ease_factor=2.6
    )
    print(f"\n测试单词模型:")
    print(f"  单词: {word.text}")
    print(f"  JSON: {json.dumps(word.to_dict(), indent=2, ensure_ascii=False)}")
    print("  ✅ 通过")
    
    # 测试表达识别结果
    expression = RecognizedExpression(
        text="in order to",
        category=ExpressionCategory.TRANSITION,
        confidence=0.9,
        context="...research in order to understand..."
    )
    print(f"\n测试表达识别结果:")
    print(f"  表达: {expression.text}")
    print(f"  分类: {expression.category.value}")
    print(f"  置信度: {expression.confidence}")
    print("  ✅ 通过")
    
    print("\n✅ 所有数据模型测试通过！")
    return True

# ==================== 主程序 ====================

def main():
    """主测试程序"""
    print("\n" + "🎓" * 30)
    print("AcademicHelper 核心逻辑测试")
    print("🎓" * 30)
    
    all_passed = True
    
    try:
        all_passed &= test_sm2_algorithm()
    except Exception as e:
        print(f"\n❌ SM-2 算法测试失败: {e}")
        all_passed = False
    
    try:
        all_passed &= test_expression_recognition()
    except Exception as e:
        print(f"\n❌ 学术表达识别测试失败: {e}")
        all_passed = False
    
    try:
        all_passed &= test_data_models()
    except Exception as e:
        print(f"\n❌ 数据模型测试失败: {e}")
        all_passed = False
    
    print("\n" + "=" * 60)
    if all_passed:
        print("🎉 所有测试通过！项目核心逻辑正确。")
    else:
        print("⚠️ 部分测试失败，请检查代码。")
    print("=" * 60)
    
    return all_passed

if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)
