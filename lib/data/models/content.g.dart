// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Content _$ContentFromJson(Map<String, dynamic> json) => Content(
  id: json['id'] as String,
  title: json['title'] as String,
  type: json['type'] as String,
  posterUrl: json['posterUrl'] as String?,
  releaseYear: (json['releaseYear'] as num?)?.toInt(),
  genre: json['genre'] as String?,
  description: json['description'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$ContentToJson(Content instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'type': instance.type,
  'posterUrl': instance.posterUrl,
  'releaseYear': instance.releaseYear,
  'genre': instance.genre,
  'description': instance.description,
  'createdAt': instance.createdAt.toIso8601String(),
};
