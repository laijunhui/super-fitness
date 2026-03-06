# 身体指标健康建议功能 - 产品需求文档

**版本**: 1.0
**日期**: 2026-03-06
**状态**: 初版需求
**功能代号**: body_info_extra

---

## 1. 需求概述

### 1.1 需求背景

当前"身体"模块仅展示BMI、BMR、体脂率等基础数据，用户无法直观了解自身指标是否处于健康范围，也无法获取针对性的改善建议。

### 1.2 需求目标

1. 基于用户录入的身体指标，自动判断各项指标是否超出健康范围，并展示对应的注意事项
2. 根据当前身体状况，提供个性化的饮食和运动建议
3. 当用户更新身体参数时，健康建议自动更新

---

## 2. 功能清单

### 2.1 健康指标评估

| 指标 | 评估内容 |
|------|----------|
| BMI | 是否在正常范围(18.5-24)，超出范围给出警告 |
| 体脂率 | 根据性别和年龄，评估是否偏高/偏低 |
| 腰围 | 评估是否超标（男性>90cm，女性>85cm），缺失时根据身高体重估算 |
| 胸围 | 缺失时根据身高体重估算，仅展示 |
| 基础代谢 | 评估BMR是否偏低（与同龄同性别人群对比） |

### 2.2 自动估算功能

当用户未录入腰围或胸围时，系统根据身高和体重自动估算默认值，并标注"\*系统生成"。

- **腰围估算公式**: 身高(cm) × 0.42（男性）或 身高(cm) × 0.38（女性）
- **胸围估算公式**: 身高(cm) × 0.53（男性）或 身高(cm) × 0.49（女性）

> 注：估算值仅供参考，不作为健康评估依据，仅在缺失时展示。

### 2.2 健康建议模块

| 建议类型 | 内容来源 |
|----------|----------|
| 饮食建议 | 根据BMI和活动水平推荐每日摄入热量 |
| 运动建议 | 根据BMI和身体状况推荐运动强度和类型 |

### 2.3 自动更新机制

- 用户在 BodyInputScreen 更新身体数据后，保存时自动重新计算健康评估
- BodyMetricsScreen 展示时自动加载最新评估结果

---

## 3. 业务规则定义

### 3.1 健康范围标准

#### BMI评估标准

| 分类 | BMI范围 | 风险等级 | 建议颜色 |
|------|---------|----------|----------|
| 偏瘦 | < 18.5 | 中等 | #FFA726 (橙色) |
| 正常 | 18.5 - 24 | 低 | #66BB6A (绿色) |
| 偏胖 | 24 - 28 | 中等 | #FFA726 (橙色) |
| 肥胖 | 28 - 30 | 高 | #EF5350 (红色) |
| 重度肥胖 | >= 30 | 极高 | #E53935 (深红) |

#### 体脂率评估标准（成年人）

| 性别 | 低 | 正常 | 偏高 | 高 |
|------|-----|------|------|-----|
| 男性 | < 6% | 6%-17% | 18%-24% | > 24% |
| 女性 | < 14% | 14%-24% | 25%-31% | > 31% |

#### 腰围评估标准

| 性别 | 正常 | 偏高（风险） | 高风险 |
|------|------|--------------|--------|
| 男性 | < 85cm | 85-90cm | > 90cm |
| 女性 | < 80cm | 80-85cm | > 85cm |

### 3.2 饮食建议规则

| 身体状况 | 每日建议摄入 |
|----------|--------------|
| 偏瘦 | TDEE + 300~500千卡 |
| 正常 | TDEE ± 0千卡 |
| 偏胖 | TDEE - 300~500千卡 |
| 肥胖 | TDEE - 500~700千卡 |

### 3.3 运动建议规则

| BMI分类 | 建议运动类型 | 运动频率 | 每次时长 |
|---------|--------------|----------|----------|
| 偏瘦 | 力量训练 + 适量有氧 | 每周3-4次 | 45-60分钟 |
| 正常 | 有氧 + 力量训练 | 每周3-5次 | 30-60分钟 |
| 偏胖 | 有氧为主 + 力量训练 | 每周4-5次 | 40-60分钟 |
| 肥胖/重度肥胖 | 低冲击有氧 + 拉伸 | 每周5次 | 30-45分钟 |

---

## 4. 页面设计

### 4.1 BodyMetricsScreen 增强设计

```
┌─────────────────────────────────────┐
│  身体指标                    [添加] │
├─────────────────────────────────────┤
│                                     │
│  ┌─────────┐ ┌─────────┐           │
│  │   BMI   │ │   BMR   │           │
│  │  22.5   │ │ 1650    │           │
│  │  正常   │ │  千卡/天 │           │
│  └─────────┘ └─────────┘           │
│                                     │
│  ┌─────────┐ ┌─────────┐           │
│  │  体脂率 │ │   腰围   │           │
│  │  18.5%  │ │  82cm   │           │
│  │  正常   │ │  正常   │           │
│  └─────────┘ └─────────┘           │
│                                     │
│  ──────── 健康评估 ────────        │
│                                     │
│  ⚠ BMI略高 (25.2)                  │
│    您的体重属于偏胖范围，建议适当   │
│    控制饮食并增加运动量。           │
│                                     │
│  ⚠ 体脂率偏高 (22%)                │
│    建议减少高脂肪食物摄入，增加     │
│    有氧运动。                       │
│                                     │
│  ──────── 建议 ────────            │
│                                     │
│  🍽 饮食建议                        │
│    建议每日摄入约1850千卡          │
│    - 早餐: 400-500千卡             │
│    - 午餐: 600-700千卡             │
│    - 晚餐: 500-600千卡             │
│    - 加餐: 100-200千卡             │
│                                     │
│  🏃 运动建议                        │
│    每周运动4-5次，每次40-60分钟    │
│    推荐: 跑步、游泳、骑行、瑜伽    │
│                                     │
├─────────────────────────────────────┤
│  [首页] [运动] [身体] [我的]        │
└─────────────────────────────────────┘
```

### 4.2 评估结果展示规则

- **正常指标**: 显示绿色对勾，不展开详情
- **异常指标**: 显示对应颜色图标 + 简短警告 + 详细说明（可展开）
- **多项异常**: 按严重程度排序展示

---

## 5. 技术实现

### 5.1 新增文件结构

```
lib/
├── core/
│   ├── constants/
│   │   └── health_constants.dart     # 健康范围常量 [新增]
│   └── utils/
│       └── health_advice_utils.dart  # 健康建议生成工具 [新增]
├── domain/
│   ├── entities/
│   │   └── health_advice_entity.dart # 健康建议实体 [新增]
│   └── usecases/
│       └── body_metrics/
│           └── get_health_advice_usecase.dart # [新增]
└── presentation/
    ├── providers/
    │   └── health_advice_provider.dart # [新增]
    ├── screens/
    │   └── body/
    │       └── widgets/
    │           ├── health_evaluation_card.dart   # [新增]
    │           ├── diet_advice_card.dart         # [新增]
    │           └── exercise_advice_card.dart       # [新增]
    └── widgets/
```

### 5.2 健康建议数据模型

```dart
// 估算值标记
class EstimatedValue {
  final double value;
  final bool isEstimated;  // true表示系统估算
  final String? source;   // 估算来源说明
}

// 健康评估结果
class HealthEvaluation {
  final IndicatorType type;      // 指标类型
  final double value;            // 当前值
  final String unit;             // 单位
  final EstimatedValue? estimatedWaist;  // 腰围估算信息
  final EstimatedValue? estimatedChest;  // 胸围估算信息
  final HealthStatus status;     // 健康状态
  final String shortWarning;      // 简短警告
  final String detailedAdvice;   // 详细建议
}

// 饮食建议
class DietAdvice {
  final int dailyCalories;        // 每日建议热量
  final String breakfastRange;   // 早餐范围
  final String lunchRange;       // 午餐范围
  final String dinnerRange;      // 晚餐范围
  final String snackRange;       // 加餐范围
  final List<String> foodTips;   // 饮食小贴士
}

// 运动建议
class ExerciseAdvice {
  final int weeklyFrequency;      // 每周次数
  final int durationPerSession;  // 每次时长
  final List<String> recommendedTypes; // 推荐运动类型
  final List<String> exerciseTips;    // 运动小贴士
}
```

### 5.3 自动估算方法实现

```dart
import '../entities/body_metrics_entity.dart';

/// 自动估算腰围和胸围
/// 当用户未录入时，根据身高体重估算
class BodyEstimateUtils {
  /// 估算腰围
  /// [height] 身高(cm)
  /// [gender] 性别
  /// 返回估算腰围(cm)
  static double estimateWaist(double height, Gender gender) {
    final multiplier = gender == Gender.male ? 0.42 : 0.38;
    return double.parse((height * multiplier).toStringAsFixed(1));
  }

  /// 估算胸围
  /// [height] 身高(cm)
  /// [gender] 性别
  /// 返回估算胸围(cm)
  static double estimateChest(double height, Gender gender) {
    final multiplier = gender == Gender.male ? 0.53 : 0.49;
    return double.parse((height * multiplier).toStringAsFixed(1));
  }

  /// 获取带估算标记的腰围值
  /// [waist] 用户输入的腰围（可为空）
  /// [height] 身高(cm)
  /// [gender] 性别
  static EstimatedValue getWaistValue(double? waist, double height, Gender gender) {
    if (waist != null && waist > 0) {
      return EstimatedValue(value: waist, isEstimated: false);
    }
    return EstimatedValue(
      value: estimateWaist(height, gender),
      isEstimated: true,
      source: '*系统生成',
    );
  }

  /// 获取带估算标记的胸围值
  /// [chest] 用户输入的胸围（可为空）
  /// [height] 身高(cm)
  /// [gender] 性别
  static EstimatedValue getChestValue(double? chest, double height, Gender gender) {
    if (chest != null && chest > 0) {
      return EstimatedValue(value: chest, isEstimated: false);
    }
    return EstimatedValue(
      value: estimateChest(height, gender),
      isEstimated: true,
      source: '*系统生成',
    );
  }
}
```

### 5.4 Provider集成

在 `BodyMetricsProvider` 中新增方法：

```dart
class BodyMetricsProvider extends ChangeNotifier {
  // 现有属性...

  // 新增
  List<HealthEvaluation> healthEvaluations = [];
  DietAdvice? dietAdvice;
  ExerciseAdvice? exerciseAdvice;

  // 加载健康建议
  Future<void> loadHealthAdvice() async {
    final latest = await repository.getLatestBodyMetrics();
    if (latest != null) {
      healthEvaluations = HealthAdviceUtils.evaluateAll(latest);
      dietAdvice = HealthAdviceUtils.generateDietAdvice(latest);
      exerciseAdvice = HealthAdviceUtils.generateExerciseAdvice(latest);
      notifyListeners();
    }
  }
}
```

---

## 6. 验收标准

### 6.1 功能验收

| 编号 | 验收项 | 验收条件 |
|------|--------|----------|
| AC-01 | BMI评估 | 当BMI<18.5或>=24时，显示对应警告 |
| AC-02 | 体脂率评估 | 根据性别显示对应的体脂率评估结果 |
| AC-03 | 腰围评估 | 当腰围超标时显示风险提示 |
| AC-04 | 饮食建议 | 根据TDEE生成三餐分配建议 |
| AC-05 | 运动建议 | 根据BMI推荐运动类型和频率 |
| AC-06 | 数据更新 | 更新体重后，重新计算建议 |
| AC-07 | 空数据处理 | 无身体数据时不显示建议模块 |
| AC-08 | 腰围自动估算 | 腰围为空时显示系统估算值，后缀标注"(*系统生成)" |
| AC-09 | 胸围自动估算 | 胸围为空时显示系统估算值，后缀标注"(*系统生成)" |

### 6.2 UI验收

| 编号 | 验收项 | 验收条件 |
|------|--------|----------|
| UI-01 | 评估卡片 | 异常指标以卡片形式展示，带颜色区分 |
| UI-02 | 建议卡片 | 饮食和运动建议分别独立展示 |
| UI-03 | 状态同步 | 保存身体数据后，建议自动刷新 |
| UI-04 | 估算标记 | 系统生成的腰围/胸围值显示"(*系统生成)"后缀 |

---

## 7. 后续迭代

### 7.1 Phase 2（可选）

- 添加年龄分层评估（青少年vs成年人vs老年人）
- 添加更多指标：血压、血糖、血脂（预留接口）
- 添加目标设定功能（目标体重、目标日期）

### 7.2 Phase 3（可选）

- 添加饮食记录功能
- 生成周报/月报
- 数据可视化（趋势图）

---

## 8. 依赖现有模块

| 模块 | 依赖关系 |
|------|----------|
| BodyMetricsModel | 复用现有模型，需新增 chest 字段 |
| BodyMetricsRepository | 获取最新身体数据 |
| CalorieUtils | 复用BMI、BMR、TDEE计算 |
| BodyMetricsProvider | 集成健康建议状态 |

