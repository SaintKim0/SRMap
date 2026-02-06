// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scene.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Scene _$SceneFromJson(Map<String, dynamic> json) => Scene(
  id: json['id'] as String,
  locationId: json['locationId'] as String,
  contentId: json['contentId'] as String,
  description: json['description'] as String,
  episode: json['episode'] as String?,
  sceneImageUrl: json['sceneImageUrl'] as String?,
  sceneOrder: (json['sceneOrder'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$SceneToJson(Scene instance) => <String, dynamic>{
  'id': instance.id,
  'locationId': instance.locationId,
  'contentId': instance.contentId,
  'description': instance.description,
  'episode': instance.episode,
  'sceneImageUrl': instance.sceneImageUrl,
  'sceneOrder': instance.sceneOrder,
};
