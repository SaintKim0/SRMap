// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'peat_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PeatProfile _$PeatProfileFromJson(Map<String, dynamic> json) => PeatProfile(
  priceScore: (json['priceScore'] as num).toDouble(),
  energyScore: (json['energyScore'] as num).toDouble(),
  authorityScore: (json['authorityScore'] as num).toDouble(),
  tasteScore: (json['tasteScore'] as num).toDouble(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$PeatProfileToJson(PeatProfile instance) =>
    <String, dynamic>{
      'priceScore': instance.priceScore,
      'energyScore': instance.energyScore,
      'authorityScore': instance.authorityScore,
      'tasteScore': instance.tasteScore,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
