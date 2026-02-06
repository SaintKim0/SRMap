import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User extends Equatable {
  final String id;
  final String theme; // 'light', 'dark', 'system'
  final String language; // 'ko', 'en'
  final DateTime createdAt;

  const User({
    required this.id,
    this.theme = 'system',
    this.language = 'ko',
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => 
      _$UserFromJson(json);
  
  Map<String, dynamic> toJson() => _$UserToJson(this);

  User copyWith({
    String? theme,
    String? language,
  }) {
    return User(
      id: id,
      theme: theme ?? this.theme,
      language: language ?? this.language,
      createdAt: createdAt,
    );
  }

  bool get isLightTheme => theme == 'light';
  bool get isDarkTheme => theme == 'dark';
  bool get isSystemTheme => theme == 'system';

  @override
  List<Object?> get props => [id];
}
