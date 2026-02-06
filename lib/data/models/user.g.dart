// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: json['id'] as String,
  theme: json['theme'] as String? ?? 'system',
  language: json['language'] as String? ?? 'ko',
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'theme': instance.theme,
  'language': instance.language,
  'createdAt': instance.createdAt.toIso8601String(),
};
