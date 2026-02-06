import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'bookmark.g.dart';

@JsonSerializable()
class Bookmark extends Equatable {
  final String id;
  final String userId;
  final String locationId;
  final DateTime createdAt;

  const Bookmark({
    required this.id,
    required this.userId,
    required this.locationId,
    required this.createdAt,
  });

  factory Bookmark.fromJson(Map<String, dynamic> json) => 
      _$BookmarkFromJson(json);
  
  Map<String, dynamic> toJson() => _$BookmarkToJson(this);

  @override
  List<Object?> get props => [id];
}
