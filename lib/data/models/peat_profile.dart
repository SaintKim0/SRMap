import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'peat_profile.g.dart';

/// P.E.A.T (Price, Energy, Authority, Taste) 기반 미식 성향 프로필 (v2.0 Spectrum)
/// 
/// 각 지표는 -1.0 ~ 1.0 범위의 스펙트럼으로 표현됩니다.
/// 중간 지대(Middle Ground)를 포함하여 3단계로 분류합니다.
/// 
/// - Price: Premium(P) > 0.33 | Moderate(M) | Economy(E) < -0.33
/// - Energy: Calm(C) > 0.33 | Balanced(B) | Vivid(V) < -0.33
/// - Authority: Star(S) > 0.33 | Open-minded(O) | Hype(H) < -0.33
/// - Taste: Classic(C) > 0.33 | Balanced(B) | Fusion(F) < -0.33
@JsonSerializable()
class PeatProfile extends Equatable {
  /// 가격 성향: -1.0 (가성비) ~ 1.0 (가심비)
  final double priceScore;
  
  /// 공간 에너지: -1.0 (활기찬) ~ 1.0 (조용한)
  final double energyScore;
  
  /// 신뢰 출처: -1.0 (트렌드) ~ 1.0 (전문가)
  final double authorityScore;
  
  /// 맛 성향: -1.0 (창의적) ~ 1.0 (전통적)
  final double tasteScore;
  
  /// 프로필 생성 일시
  final DateTime createdAt;
  
  /// 마지막 업데이트 일시
  final DateTime? updatedAt;

  // 임계값 (0.33 이상/이하로 구분)
  static const double _threshold = 0.33;

  const PeatProfile({
    required this.priceScore,
    required this.energyScore,
    required this.authorityScore,
    required this.tasteScore,
    required this.createdAt,
    this.updatedAt,
  });

  /// 기본 프로필 (모든 지표 중립)
  factory PeatProfile.neutral() {
    return PeatProfile(
      priceScore: 0.0,
      energyScore: 0.0,
      authorityScore: 0.0,
      tasteScore: 0.0,
      createdAt: DateTime.now(),
    );
  }

  factory PeatProfile.fromJson(Map<String, dynamic> json) => 
      _$PeatProfileFromJson(json);
  
  Map<String, dynamic> toJson() => _$PeatProfileToJson(this);

  /// P.E.A.T 유형 코드 생성 (예: P.C.S.C, M.B.O.B)
  String get typeCode {
    return '${_getPriceCode()}.${_getEnergyCode()}.${_getAuthorityCode()}.${_getTasteCode()}';
  }

  String _getPriceCode() {
    if (priceScore > _threshold) return 'P'; // Premium
    if (priceScore < -_threshold) return 'E'; // Economy
    return 'M'; // Moderate
  }

  String _getEnergyCode() {
    if (energyScore > _threshold) return 'C'; // Calm
    if (energyScore < -_threshold) return 'V'; // Vivid
    return 'B'; // Balanced
  }

  String _getAuthorityCode() {
    if (authorityScore > _threshold) return 'S'; // Star (Specialist)
    if (authorityScore < -_threshold) return 'H'; // Hype
    return 'O'; // Open-minded
  }

  String _getTasteCode() {
    if (tasteScore > _threshold) return 'C'; // Classic
    if (tasteScore < -_threshold) return 'F'; // Fusion (Creative)
    return 'B'; // Balanced
  }

  /// 유형 이름 (한글)
  String get typeName {
    // 1. 정확히 매칭되는 코드가 있으면 반환
    if (_typeNames.containsKey(typeCode)) {
      return _typeNames[typeCode]!;
    }
    
    // 2. 하이브리드 조합 로직
    // 대표 성향을 기반으로 이름 생성
    return _generateHybridName();
  }

  String _generateHybridName() {
    // 간단한 조합 로직 (예시)
    final p = _getPriceCode();
    final a = _getAuthorityCode();
    
    if (p == 'P' && a == 'S') return '미식 귀족';
    if (p == 'E' && a == 'H') return '가성비 헌터';
    if (p == 'M' && a == 'O') return '실속파 미식가';
    if (p == 'P' && a == 'H') return '트렌디 럭셔리';
    
    return '자유로운 미식가';
  }

  /// 유형 설명
  String get typeDescription {
    if (_typeDescriptions.containsKey(typeCode)) {
      return _typeDescriptions[typeCode]!;
    }
    return '당신은 어느 한쪽에 치우치기보다 상황에 맞춰 유연하게 맛집을 선택하는 조화로운 미식가입니다.';
  }

  /// 추천 레스토랑 타입
  List<String> get recommendedCategories {
    // 1. 매칭되는 코드가 있으면 반환
    if (_recommendedCategories.containsKey(typeCode)) {
      return _recommendedCategories[typeCode]!;
    }
    
    // 2. 기본 추천
    final List<String> categories = [];
    if (authorityScore > 0) categories.add('미슐랭/블루리본');
    if (authorityScore < 0) categories.add('TV 맛집');
    if (priceScore > 0) categories.add('파인 다이닝');
    if (priceScore < 0) categories.add('가성비 맛집');
    
    return categories.isNotEmpty ? categories : ['전체 추천'];
  }

  /// 프로필 업데이트
  PeatProfile copyWith({
    double? priceScore,
    double? energyScore,
    double? authorityScore,
    double? tasteScore,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PeatProfile(
      priceScore: priceScore ?? this.priceScore,
      energyScore: energyScore ?? this.energyScore,
      authorityScore: authorityScore ?? this.authorityScore,
      tasteScore: tasteScore ?? this.tasteScore,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    priceScore,
    energyScore,
    authorityScore,
    tasteScore,
    createdAt,
  ];

  // ==========================================
  // 유형별 데이터 매핑 (주요 16개 + 하이브리드 예시)
  // ==========================================
  
  static const Map<String, String> _typeNames = {
    // Pure Types (극단형)
    'P.C.S.C': '명품 입맛의 미식 귀족',
    'P.C.S.F': '완벽주의 미식 비평가', // N -> F
    'E.V.H.C': '정 많은 노포 헌터',
    'E.V.H.F': '가성비 찾는 방송 추격자', // N -> F
    
    // Hybrid Types (요청사항 반영)
    'M.C.S.C': '실속 있는 미식가',
    'E.V.O.C': '트렌디한 노포 마니아',
    'P.B.H.F': '화려한 미식 탐험가',
    
    // Balanced Types
    'M.B.O.B': '올라운더 미식가',
  };

  static const Map<String, String> _typeDescriptions = {
    // Pure Types
    'P.C.S.C': '가격보다는 완벽한 경험이 중요합니다. 미슐랭 3스타, 파인 다이닝을 선호하며 맛, 서비스, 분위기의 삼박자를 모두 따집니다.',
    'P.C.S.F': '셰프의 철학과 창의성을 중시합니다. 조용한 공간에서 새로운 미식 경험을 탐구하는 고독한 미식가입니다.',
    'E.V.H.C': 'TV 예능에 나온 시장 맛집이나 노포를 좋아합니다. 왁자지껄한 분위기를 즐기며 전통적인 맛을 추구합니다.',
    'E.V.H.F': 'TV 예능에 나온 맛집을 정복하는 게 취미입니다. 합리적인 가격의 로컬 맛집을 선호하며, SNS 인증샷과 공유를 즐깁니다.',
    
    // Hybrid Types
    'M.C.S.C': '미슐랭 스타보다는 빕 구르망이나 블루리본 서베이를 신뢰합니다. 가격은 합리적이어야 하지만 전문가의 검증은 포기 못 하며, 조용한 곳을 찾는 스타일입니다.',
    'E.V.O.C': '예능에 나온 노포를 좋아하지만, 맛은 전통적이어야 합니다. 왁자지껄한 분위기를 즐기며 흑백요리사의 "시장 장인" 같은 스타일에 열광합니다.',
    'P.B.H.F': '돈을 아끼지 않고 흑백요리사 식당이나 화제의 컨템퍼러리 다이닝을 찾아다닙니다. 너무 정적인 것보다는 활기찬 셰프의 퍼포먼스를 즐깁니다.',
    
    // Balanced Types
    'M.B.O.B': '어느 한쪽에 치우치기보다 상황과 기분에 맞춰 유연하게 식당을 선택합니다. 당신에게 실패란 없습니다.',
  };

  static const Map<String, List<String>> _recommendedCategories = {
    'P.C.S.C': ['미슐랭 3스타', '파인 다이닝'],
    'P.C.S.F': ['미슐랭 1-2스타', '컨템퍼러리'],
    'E.V.H.C': ['TV 방영 맛집', '오래된 노포'],
    'E.V.H.F': ['SNS 핫플', '퓨전 한식'],
    
    'M.C.S.C': ['빕 구르망', '블루리본'],
    'E.V.O.C': ['허영만의 백반기행', '노포'],
    'P.B.H.F': ['흑백요리사', '다이닝 바'],
    
    'M.B.O.B': ['전체', '상황별 추천'],
  };
}
