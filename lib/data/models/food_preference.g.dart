// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'food_preference.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FoodPreference _$FoodPreferenceFromJson(Map<String, dynamic> json) =>
    FoodPreference(
      preferredCuisines:
          (json['preferredCuisines'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      spicyLevel: (json['spicyLevel'] as num?)?.toInt() ?? 1,
      dislikedIngredients:
          (json['dislikedIngredients'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      characterType: json['characterType'] as String? ?? '미식가',
    );

Map<String, dynamic> _$FoodPreferenceToJson(FoodPreference instance) =>
    <String, dynamic>{
      'preferredCuisines': instance.preferredCuisines,
      'spicyLevel': instance.spicyLevel,
      'dislikedIngredients': instance.dislikedIngredients,
      'characterType': instance.characterType,
    };
