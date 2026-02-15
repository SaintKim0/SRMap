// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Location _$LocationFromJson(Map<String, dynamic> json) => Location(
  id: json['id'] as String,
  name: json['name'] as String,
  address: json['address'] as String,
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
  category: json['category'] as String,
  mediaType: json['mediaType'] as String?,
  contentTitle: json['contentTitle'] as String?,
  contentReleaseYear: (json['contentReleaseYear'] as num?)?.toInt(),
  michelinTier: json['michelinTier'] as String?,
  chefName: json['chefName'] as String?,
  foodCategory: json['food_category'] as String?,
  representativeMenu: json['representative_menu'] as String?,
  phoneNumber: json['phoneNumber'] as String?,
  website: json['website'] as String?,
  openingHours: json['openingHours'] as String?,
  imageUrls: (json['imageUrls'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  parking: json['parking'] as String?,
  transportation: json['transportation'] as String?,
  viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
  bookmarkCount: (json['bookmarkCount'] as num?)?.toInt() ?? 0,
  description: json['description'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$LocationToJson(Location instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'address': instance.address,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'category': instance.category,
  'phoneNumber': instance.phoneNumber,
  'website': instance.website,
  'openingHours': instance.openingHours,
  'imageUrls': instance.imageUrls,
  'parking': instance.parking,
  'transportation': instance.transportation,
  'viewCount': instance.viewCount,
  'bookmarkCount': instance.bookmarkCount,
  'description': instance.description,
  'mediaType': instance.mediaType,
  'contentTitle': instance.contentTitle,
  'contentReleaseYear': instance.contentReleaseYear,
  'michelinTier': instance.michelinTier,
  'chefName': instance.chefName,
  'food_category': instance.foodCategory,
  'representative_menu': instance.representativeMenu,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};
