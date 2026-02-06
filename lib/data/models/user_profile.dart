import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_profile.g.dart';

@JsonSerializable()
class UserProfile extends Equatable {
  final String nickname;
  final String statusMessage;
  final String? profileImage;

  const UserProfile({
    this.nickname = '드라마 러버',
    this.statusMessage = '도깨비 신부 찾으러 다니는 중 🗡️',
    this.profileImage,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => 
      _$UserProfileFromJson(json);
  
  Map<String, dynamic> toJson() => _$UserProfileToJson(this);

  UserProfile copyWith({
    String? nickname,
    String? statusMessage,
    String? profileImage,
  }) {
    return UserProfile(
      nickname: nickname ?? this.nickname,
      statusMessage: statusMessage ?? this.statusMessage,
      profileImage: profileImage ?? this.profileImage,
    );
  }

  @override
  List<Object?> get props => [nickname, statusMessage, profileImage];
}
