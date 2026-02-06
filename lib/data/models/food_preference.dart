import 'package:json_annotation/json_annotation.dart';

part 'food_preference.g.dart';

@JsonSerializable()
class FoodPreference {
  /// 선호하는 음식 종류 (한식, 일식, 중식, 양식, 아시안, 분식 등)
  final List<String> preferredCuisines;

  /// 선호하는 맵기 단계 (1: 안매운맛 ~ 5: 아주 매운맛)
  final int spicyLevel;

  /// 기피하는 재료 (오이, 고수, 당근, 가지, 생선 등)
  final List<String> dislikedIngredients;

  /// 사용자 미식 특성 (예: 까다롭지 않은 미식가, 매운맛 정복자 등)
  final String characterType;

  const FoodPreference({
    this.preferredCuisines = const [],
    this.spicyLevel = 1,
    this.dislikedIngredients = const [],
    this.characterType = '미식가',
  });

  factory FoodPreference.fromJson(Map<String, dynamic> json) =>
      _$FoodPreferenceFromJson(json);

  Map<String, dynamic> toJson() => _$FoodPreferenceToJson(this);

  FoodPreference copyWith({
    List<String>? preferredCuisines,
    int? spicyLevel,
    List<String>? dislikedIngredients,
    String? characterType,
  }) {
    return FoodPreference(
      preferredCuisines: preferredCuisines ?? this.preferredCuisines,
      spicyLevel: spicyLevel ?? this.spicyLevel,
      dislikedIngredients: dislikedIngredients ?? this.dislikedIngredients,
      characterType: characterType ?? this.characterType,
    );
  }
}
