import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'location.g.dart';

@JsonSerializable()
class Location extends Equatable {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String category;
  final String? phoneNumber;
  final String? website;
  final String? openingHours;
  final List<String> imageUrls;
  final String? parking;
  final String? transportation;
  final int viewCount;
  final int bookmarkCount;
  final String? description;
  final String? mediaType;
  final String? contentTitle;
  /// 작품 제작·공개 연도 (있으면 작품 카드에 표기)
  final int? contentReleaseYear;
  /// 미슐랭 등급 (3 Star, 2 Star, 1 Star, 빕구르망, michelin 등)
  final String? michelinTier;
  /// 셰프 이름 또는 별명 (흑백요리사 등)
  final String? chefName;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Location({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.category,
    this.mediaType,
    this.contentTitle,
    this.contentReleaseYear,
    this.michelinTier,
    this.chefName,
    this.phoneNumber,
    this.website,
    this.openingHours,
    required this.imageUrls,
    this.parking,
    this.transportation,
    this.viewCount = 0,
    this.bookmarkCount = 0,
    this.description,
    required this.createdAt,
    this.updatedAt,
  });

  factory Location.fromJson(Map<String, dynamic> json) => 
      _$LocationFromJson(json);
  
  Map<String, dynamic> toJson() => _$LocationToJson(this);

  Location copyWith({
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    String? category,
    String? mediaType,
    String? contentTitle,
    String? phoneNumber,
    String? website,
    String? openingHours,
    List<String>? imageUrls,
    String? parking,
    String? transportation,
    int? viewCount,
    int? bookmarkCount,
    String? description,
    String? michelinTier,
    String? chefName,
    DateTime? updatedAt,
  }) {
    return Location(
      id: id,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      category: category ?? this.category,
      mediaType: mediaType ?? this.mediaType,
      contentTitle: contentTitle ?? this.contentTitle,
      contentReleaseYear: contentReleaseYear ?? this.contentReleaseYear,
      michelinTier: michelinTier ?? this.michelinTier,
      chefName: chefName ?? this.chefName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      website: website ?? this.website,
      openingHours: openingHours ?? this.openingHours,
      imageUrls: imageUrls ?? this.imageUrls,
      parking: parking ?? this.parking,
      transportation: transportation ?? this.transportation,
      viewCount: viewCount ?? this.viewCount,
      bookmarkCount: bookmarkCount ?? this.bookmarkCount,
      description: description ?? this.description,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id];
}
