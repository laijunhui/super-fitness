import '../../core/constants/app_constants.dart';

/// 身体指标数据模型
class BodyMetricsModel {
  final String id;
  final double height;
  final double weight;
  final double? waist;
  final double? chest;  // 胸围（可选）
  final int age;
  final Gender gender;
  final double? bmi;
  final double? bmr;
  final DateTime createdAt;

  BodyMetricsModel({
    required this.id,
    required this.height,
    required this.weight,
    this.waist,
    this.chest,
    required this.age,
    required this.gender,
    this.bmi,
    this.bmr,
    required this.createdAt,
  });

  /// 从Map创建
  factory BodyMetricsModel.fromMap(Map<String, dynamic> map) {
    return BodyMetricsModel(
      id: map['id'],
      height: map['height']?.toDouble() ?? 0,
      weight: map['weight']?.toDouble() ?? 0,
      waist: map['waist']?.toDouble(),
      chest: map['chest']?.toDouble(),
      age: map['age'] ?? 0,
      gender: Gender.values.firstWhere(
        (e) => e.name == map['gender'],
        orElse: () => Gender.male,
      ),
      bmi: map['bmi']?.toDouble(),
      bmr: map['bmr']?.toDouble(),
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'height': height,
      'weight': weight,
      'waist': waist,
      'chest': chest,
      'age': age,
      'gender': gender.name,
      'bmi': bmi,
      'bmr': bmr,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// 复制
  BodyMetricsModel copyWith({
    String? id,
    double? height,
    double? weight,
    double? waist,
    double? chest,
    int? age,
    Gender? gender,
    double? bmi,
    double? bmr,
    DateTime? createdAt,
  }) {
    return BodyMetricsModel(
      id: id ?? this.id,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      waist: waist ?? this.waist,
      chest: chest ?? this.chest,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      bmi: bmi ?? this.bmi,
      bmr: bmr ?? this.bmr,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
