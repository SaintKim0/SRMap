import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'scene.g.dart';

@JsonSerializable()
class Scene extends Equatable {
  final String id;
  final String locationId;
  final String contentId;
  final String description;
  final String? episode;
  final String? sceneImageUrl;
  final int sceneOrder;

  const Scene({
    required this.id,
    required this.locationId,
    required this.contentId,
    required this.description,
    this.episode,
    this.sceneImageUrl,
    this.sceneOrder = 0,
  });

  factory Scene.fromJson(Map<String, dynamic> json) => 
      _$SceneFromJson(json);
  
  Map<String, dynamic> toJson() => _$SceneToJson(this);

  @override
  List<Object?> get props => [id];
}
