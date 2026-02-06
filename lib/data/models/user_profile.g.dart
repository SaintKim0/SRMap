// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => UserProfile(
  nickname: json['nickname'] as String? ?? '드라마 러버',
  statusMessage: json['statusMessage'] as String? ?? '도깨비 신부 찾으러 다니는 중 🗡️',
  profileImage: json['profileImage'] as String?,
);

Map<String, dynamic> _$UserProfileToJson(UserProfile instance) =>
    <String, dynamic>{
      'nickname': instance.nickname,
      'statusMessage': instance.statusMessage,
      'profileImage': instance.profileImage,
    };
