import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'content.g.dart';

@JsonSerializable()
class Content extends Equatable {
  final String id;
  final String title;
  final String type; // 'drama' or 'movie'
  final String? posterUrl;
  final int? releaseYear;
  final String? genre;
  final String? description;
  final DateTime createdAt;

  const Content({
    required this.id,
    required this.title,
    required this.type,
    this.posterUrl,
    this.releaseYear,
    this.genre,
    this.description,
    required this.createdAt,
  });

  factory Content.fromJson(Map<String, dynamic> json) => 
      _$ContentFromJson(json);
  
  Map<String, dynamic> toJson() => _$ContentToJson(this);

  bool get isDrama => type == 'drama';
  bool get isMovie => type == 'movie';

  @override
  List<Object?> get props => [id];
}
