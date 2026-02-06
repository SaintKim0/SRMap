# Stage 5: 지도 및 위치 기능 통합 PRD

## 1. 개요

### 목표
SceneMap 앱에 지도 및 위치 기반 서비스를 통합하여 사용자가 촬영지를 시각적으로 탐색하고, 현재 위치에서 촬영지까지의 경로를 안내받을 수 있도록 합니다.

### 배경
- 한국 시장을 타겟으로 하는 앱이므로 네이버 지도가 가장 정확한 한국 지도 데이터를 제공
- 사용자들이 촬영지를 방문하기 위해 실제 내비게이션이 필요
- 위치 기반으로 주변 촬영지를 찾는 기능 필요

### 범위
**포함 사항:**
- ✅ 네이버 지도 SDK 통합
- ✅ 현재 위치 표시 및 추적
- ✅ 촬영지 마커 표시
- ✅ 외부 지도 앱 연동 (네이버, 카카오, 구글)
- ✅ 거리 계산 및 표시

**제외 사항:**
- ❌ 앱 내 턴바이턴 내비게이션 (외부 앱 활용)
- ❌ 실시간 교통 정보
- ❌ 대중교통 경로 안내

---

## 2. 기술 스택 결정

### 2.1 지도 솔루션 선택: 네이버 지도

#### 선택 이유
1. **한국 지도 정확도**: 한국 내 POI, 도로, 건물 정보가 가장 정확
2. **무료 사용량**: 월 30만 건까지 무료 (MVP 단계에 충분)
3. **Flutter 지원**: `flutter_naver_map` 패키지 제공
4. **한국어 문서**: 개발자 문서가 한국어로 제공

#### 대안 검토
| 지도 서비스 | 장점 | 단점 | 결론 |
|-----------|------|------|------|
| **네이버 지도** | 한국 데이터 최고, 무료 사용량 충분 | 글로벌 확장 시 제한적 | ✅ **선택** |
| 구글 지도 | 글로벌 지원, 익숙한 UI | 한국 데이터 부족, 유료 | ❌ 제외 |
| 카카오 지도 | 한국 데이터 우수 | Flutter 지원 미흡 | ❌ 제외 |

### 2.2 하이브리드 접근 방식

**앱 내 지도**: 네이버 지도 SDK
- 촬영지 위치 표시
- 마커 클러스터링
- 카메라 컨트롤

**외부 내비게이션**: 사용자 선택
- 네이버 지도 앱
- 카카오맵 앱
- 구글 지도 앱

---

## 3. 주요 기능 명세

### 3.1 지도 화면 (Map Screen)

#### 기본 기능
- **지도 표시**: 네이버 지도 SDK를 사용한 인터랙티브 지도
- **현재 위치**: 사용자의 현재 위치를 파란색 점으로 표시
- **촬영지 마커**: 모든 촬영지를 커스텀 마커로 표시
- **마커 클릭**: 마커 클릭 시 간단한 정보 표시 (이름, 거리)

#### UI 컴포넌트
```
┌─────────────────────────────────┐
│  ← SceneMap        🔍  ⚙️       │ <- 헤더
├─────────────────────────────────┤
│                                 │
│         📍 (마커들)             │
│                                 │
│    🗺️  네이버 지도 영역         │
│                                 │
│         📍 현재위치             │
│                                 │
├─────────────────────────────────┤
│  [📍 내 위치]  [🧭 나침반]      │ <- 지도 컨트롤
└─────────────────────────────────┘
```

### 3.2 위치 서비스 (Location Service)

#### 기능
- ✅ **위치 권한 관리**: 권한 요청 및 상태 확인
- ✅ **현재 위치 가져오기**: GPS를 통한 현재 위치 조회
- ✅ **거리 계산**: 두 지점 간 직선 거리 계산
- ✅ **거리 포맷팅**: 사용자 친화적 거리 표시 (예: "1.2km", "350m")
- ✅ **위치 업데이트 스트림**: 실시간 위치 추적

#### 구현 상태
- `lib/data/services/location_service.dart` **이미 구현됨** ✅
- 사용 패키지: `geolocator`, `permission_handler`

### 3.3 외부 지도 앱 연동 (Navigation Integration)

#### 지원 앱
1. **네이버 지도**
   - URL Scheme: `nmap://`
   - 설치 확인 및 폴백 처리

2. **카카오맵**
   - URL Scheme: `kakaomap://`
   - 설치 확인 및 폴백 처리

3. **구글 지도**
   - URL Scheme: `comgooglemaps://` (iOS), `google.navigation://` (Android)
   - 웹 폴백: `https://maps.google.com`

#### 사용자 플로우
```
촬영지 상세 화면
    ↓
[길찾기] 버튼 클릭
    ↓
앱 선택 바텀시트 표시
    ↓
├─ 네이버 지도
├─ 카카오맵
└─ 구글 지도
    ↓
선택한 앱으로 이동
(앱 미설치 시 웹 또는 스토어로 이동)
```

### 3.4 촬영지 상세 화면 개선

#### 추가 정보
- **현재 위치에서 거리**: "현재 위치에서 2.3km"
- **주소**: 도로명 주소 표시
- **지도 미리보기**: 작은 지도로 위치 표시
- **길찾기 버튼**: 외부 지도 앱 실행

---

## 4. 데이터 모델

### 4.1 Location 모델 확장

기존 `Location` 모델에 필요한 필드가 이미 포함되어 있는지 확인:

```dart
class Location {
  final String id;
  final String name;
  final double latitude;   // ✅ 필수
  final double longitude;  // ✅ 필수
  final String address;    // ✅ 필수
  // ... 기타 필드
}
```

---

## 5. 기술 구현 계획

### 5.1 패키지 의존성

#### pubspec.yaml 추가
```yaml
dependencies:
  # 지도
  flutter_naver_map: ^1.1.2
  
  # 위치 (이미 추가됨)
  geolocator: ^10.1.0
  permission_handler: ^11.0.1
  
  # URL 런처 (외부 앱 실행)
  url_launcher: ^6.2.1
```

### 5.2 네이버 지도 SDK 설정

#### Android 설정 (android/app/build.gradle)
```gradle
android {
    defaultConfig {
        minSdkVersion 21  // 네이버 지도 최소 요구사항
    }
}
```

#### Android Manifest (android/app/src/main/AndroidManifest.xml)
```xml
<manifest>
    <application>
        <meta-data
            android:name="com.naver.maps.map.CLIENT_ID"
            android:value="YOUR_NAVER_CLIENT_ID" />
    </application>
</manifest>
```

#### iOS 설정 (ios/Runner/Info.plist)
```xml
<key>NMFClientId</key>
<string>YOUR_NAVER_CLIENT_ID</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>촬영지까지의 거리를 표시하기 위해 위치 권한이 필요합니다.</string>
```

### 5.3 파일 구조

```
lib/
├── data/
│   └── services/
│       ├── location_service.dart      # ✅ 이미 구현됨
│       ├── map_service.dart           # 🆕 생성 필요
│       └── navigation_service.dart    # 🆕 생성 필요
├── presentation/
│   ├── screens/
│   │   ├── map_screen.dart           # 🆕 생성 필요
│   │   └── location_detail_screen.dart # 🔄 업데이트 필요
│   └── widgets/
│       ├── map_widget.dart           # 🆕 생성 필요
│       └── navigation_button.dart    # 🆕 생성 필요
└── core/
    └── constants/
        └── map_constants.dart        # 🆕 생성 필요
```

---

## 6. API 키 관리

### 6.1 네이버 클라우드 플랫폼 설정

#### 발급 절차
1. [네이버 클라우드 플랫폼](https://www.ncloud.com/) 가입
2. Console > Services > AI·NAVER API > Maps 선택
3. Application 등록
4. Client ID 발급 받기

#### 무료 사용량
- **월 30만 건** 무료
- 초과 시: 1,000건당 ₩2

### 6.2 보안 관리

#### 환경 변수 사용 (권장)
```dart
// lib/core/constants/map_constants.dart
class MapConstants {
  static const String naverMapClientId = 
      String.fromEnvironment('NAVER_MAP_CLIENT_ID');
}
```

#### .env 파일 (대안)
```
NAVER_MAP_CLIENT_ID=your_client_id_here
```

**중요**: `.gitignore`에 API 키 파일 추가

---

## 7. 구현 우선순위

### Phase 1: 기본 위치 서비스 (1일)
- [x] ✅ `location_service.dart` 이미 구현됨
- [ ] 위치 권한 UI 플로우 테스트

### Phase 2: 네이버 지도 통합 (2-3일)
- [ ] 네이버 지도 SDK 설정
- [ ] `map_service.dart` 구현
- [ ] `map_screen.dart` 기본 UI 구현
- [ ] 촬영지 마커 표시

### Phase 3: 외부 내비게이션 연동 (1-2일)
- [ ] `navigation_service.dart` 구현
- [ ] 네이버/카카오/구글 지도 앱 연동
- [ ] 앱 미설치 시 폴백 처리

### Phase 4: UI/UX 개선 (1일)
- [ ] 촬영지 상세 화면에 지도 미리보기 추가
- [ ] 거리 정보 표시
- [ ] 길찾기 버튼 추가

---

## 8. 테스트 계획

### 8.1 단위 테스트
- [ ] `location_service.dart` 거리 계산 로직
- [ ] `navigation_service.dart` URL 생성 로직

### 8.2 통합 테스트
- [ ] 위치 권한 플로우
- [ ] 지도 마커 표시
- [ ] 외부 앱 실행

### 8.3 실기기 테스트
- [ ] Android 실기기에서 위치 권한 및 지도 표시
- [ ] iOS 실기기에서 위치 권한 및 지도 표시
- [ ] 네이버/카카오/구글 지도 앱 연동 확인

---

## 9. 성공 지표

### 기능 완성도
- [ ] 지도에 모든 촬영지 마커 표시
- [ ] 현재 위치 정확도 ±50m 이내
- [ ] 외부 지도 앱 연동 성공률 95% 이상

### 사용자 경험
- [ ] 지도 로딩 시간 3초 이내
- [ ] 위치 권한 요청 거부율 30% 이하
- [ ] 길찾기 기능 사용률 50% 이상

---

## 10. 리스크 및 대응

### 리스크 1: 위치 권한 거부
**대응**: 
- 권한 필요성을 명확히 설명하는 온보딩 화면
- 권한 없이도 지도 탐색은 가능하도록 설계

### 리스크 2: 네이버 지도 API 사용량 초과
**대응**:
- 지도 캐싱 전략
- 사용량 모니터링 대시보드 구축

### 리스크 3: 외부 지도 앱 미설치
**대응**:
- 웹 버전으로 폴백
- 앱 스토어 설치 유도

---

## 11. 다음 단계

1. ✅ Stage 5 PRD 작성 완료
2. 🔄 네이버 클라우드 플랫폼에서 API 키 발급
3. 📦 `pubspec.yaml`에 패키지 추가
4. ⚙️ Android/iOS 네이티브 설정
5. 💻 `map_service.dart` 구현 시작

---

## 12. 참고 자료

- [네이버 지도 API 문서](https://navermaps.github.io/android-map-sdk/guide-ko/)
- [flutter_naver_map 패키지](https://pub.dev/packages/flutter_naver_map)
- [geolocator 패키지](https://pub.dev/packages/geolocator)
- [url_launcher 패키지](https://pub.dev/packages/url_launcher)
