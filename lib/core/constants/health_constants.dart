import 'package:flutter/material.dart';

/// 健康范围相关常量
class HealthConstants {
  HealthConstants._();

  // ==================== BMI评估标准 ====================

  /// BMI分类颜色
  static const Map<String, Color> bmiCategoryColors = {
    '偏瘦': Color(0xFFFFA726),      // 橙色
    '正常': Color(0xFF66BB6A),      // 绿色
    '偏胖': Color(0xFFFFA726),      // 橙色
    '肥胖': Color(0xFFEF5350),      // 红色
    '重度肥胖': Color(0xFFE53935),  // 深红
  };

  /// BMI风险等级
  static const Map<String, HealthRisk> bmiRiskLevels = {
    '偏瘦': HealthRisk.medium,
    '正常': HealthRisk.low,
    '偏胖': HealthRisk.medium,
    '肥胖': HealthRisk.high,
    '重度肥胖': HealthRisk.veryHigh,
  };

  // ==================== 体脂率评估标准 ====================

  /// 男性体脂率范围（%）
  static const Map<String, List<double>> maleBodyFatRanges = {
    '低': [0, 6],
    '正常': [6, 17],
    '偏高': [17, 24],
    '高': [24, 100],
  };

  /// 女性体脂率范围（%）
  static const Map<String, List<double>> femaleBodyFatRanges = {
    '低': [0, 14],
    '正常': [14, 24],
    '偏高': [24, 31],
    '高': [31, 100],
  };

  /// 体脂率颜色
  static const Map<String, Color> bodyFatCategoryColors = {
    '低': Color(0xFFFFA726),    // 橙色
    '正常': Color(0xFF66BB6A),  // 绿色
    '偏高': Color(0xFFFFA726),  // 橙色
    '高': Color(0xFFEF5350),    // 红色
  };

  // ==================== 腰围评估标准 ====================

  /// 男性腰围范围（cm）
  static const Map<String, List<double>> maleWaistRanges = {
    '正常': [0, 85],
    '偏高': [85, 90],
    '高风险': [90, 200],
  };

  /// 女性腰围范围（cm）
  static const Map<String, List<double>> femaleWaistRanges = {
    '正常': [0, 80],
    '偏高': [80, 85],
    '高风险': [85, 200],
  };

  /// 腰围颜色
  static const Map<String, Color> waistCategoryColors = {
    '正常': Color(0xFF66BB6A),  // 绿色
    '偏高': Color(0xFFFFA726),  // 橙色
    '高风险': Color(0xFFEF5350), // 红色
  };

  // ==================== 饮食建议规则 ====================

  /// 每日热量调整（基于TDEE）
  static const Map<String, int> calorieAdjustments = {
    '偏瘦': 400,     // TDEE + 300~500
    '正常': 0,        // TDEE ± 0
    '偏胖': -400,    // TDEE - 300~500
    '肥胖': -600,    // TDEE - 500~700
  };

  /// 三餐热量分配比例
  static const Map<String, double> mealDistribution = {
    'breakfast': 0.25,  // 早餐 25%
    'lunch': 0.35,      // 午餐 35%
    'dinner': 0.30,    // 晚餐 30%
    'snack': 0.10,      // 加餐 10%
  };

  // ==================== 运动建议规则 ====================

  /// 运动建议（按BMI分类）
  static const Map<String, ExerciseSuggestion> exerciseSuggestions = {
    '偏瘦': ExerciseSuggestion(
      weeklyFrequency: 4,
      durationPerSession: 60,
      types: ['力量训练', '器械训练', '跑步', '游泳'],
      tips: [
        '以力量训练为主，增加肌肉量',
        '每次训练后补充优质蛋白质',
        '保证充足睡眠促进肌肉恢复',
      ],
    ),
    '正常': ExerciseSuggestion(
      weeklyFrequency: 4,
      durationPerSession: 45,
      types: ['跑步', '游泳', '骑行', '瑜伽', '力量训练'],
      tips: [
        '有氧运动与力量训练结合',
        '保持每周规律运动习惯',
        '运动后适当拉伸放松',
      ],
    ),
    '偏胖': ExerciseSuggestion(
      weeklyFrequency: 5,
      durationPerSession: 50,
      types: ['跑步', '游泳', '骑行', '快走', '椭圆机'],
      tips: [
        '以有氧运动为主燃烧脂肪',
        '适量加入力量训练提升基础代谢',
        '运动前做好热身避免受伤',
      ],
    ),
    '肥胖': ExerciseSuggestion(
      weeklyFrequency: 5,
      durationPerSession: 40,
      types: ['游泳', '快走', '瑜伽', '椭圆机', '拉伸'],
      tips: [
        '选择低冲击运动保护关节',
        '循序渐进增加运动强度',
        '运动后适当按摩缓解肌肉酸痛',
      ],
    ),
    '重度肥胖': ExerciseSuggestion(
      weeklyFrequency: 5,
      durationPerSession: 30,
      types: ['游泳', '瑜伽', '拉伸', '散步'],
      tips: [
        '以低强度运动为主',
        '避免剧烈运动造成关节损伤',
        '建议在医生指导下进行运动',
      ],
    ),
  };

  // ==================== 饮食建议 ====================

  /// 饮食建议
  static const Map<String, List<String>> dietTips = {
    '偏瘦': [
      '增加优质蛋白质摄入，如鸡胸肉、鱼、蛋、奶制品',
      '适当增加碳水化合物摄入',
      '少食多餐，每天5-6餐',
      '可适量补充坚果和牛油果',
    ],
    '正常': [
      '保持均衡饮食，荤素搭配',
      '每天摄入足量蔬菜水果',
      '适量饮水，每天1500-2000ml',
      '规律用餐，避免暴饮暴食',
    ],
    '偏胖': [
      '控制每日总热量摄入',
      '减少高脂肪、高糖食物',
      '增加膳食纤维摄入',
      '晚餐尽量提前且适量',
    ],
    '肥胖': [
      '严格控制每日热量摄入',
      '以低脂低糖饮食为主',
      '增加蔬菜水果比例',
      '避免宵夜和零食',
    ],
    '重度肥胖': [
      '建议咨询营养师制定个性化方案',
      '严格控制碳水化合物摄入',
      '选择低GI食物',
      '记录饮食日志便于监控',
    ],
  };
}

/// 健康风险等级
enum HealthRisk {
  low,        // 低
  medium,     // 中等
  high,       // 高
  veryHigh,   // 极高
}

/// 运动建议
class ExerciseSuggestion {
  final int weeklyFrequency;        // 每周次数
  final int durationPerSession;   // 每次时长（分钟）
  final List<String> types;        // 推荐运动类型
  final List<String> tips;         // 运动小贴士

  const ExerciseSuggestion({
    required this.weeklyFrequency,
    required this.durationPerSession,
    required this.types,
    required this.tips,
  });
}
