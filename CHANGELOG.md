# Changelog

All notable changes to TasteMap will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.3] - 2026-02-10

### Changed
- Refined Search Screen UI: moved instructions to AppBar title, reduced vertical gaps, and removed "전체 지역" label.
- Overhauled Distance Slider: added specific increments (All, 100km, 50km, 25km, 10km, 5km, My Location) and improved visibility.
- Unified Global AppBar Titles: standardized font size to 17px bold and updated spacing ("맛집 지도") across all screens.
- Updated Entertainment (예능) tab icons to `Icons.live_tv`.

## [1.0.2] - 2026-02-10

### Added
- **동적 프로그램 썸네일**: 공식 이미지가 없는 예능 프로그램에 대해 세련된 디자인의 동적 썸네일 자동 생성
- **썸네일 데모 화면**: 다양한 프로그램 썸네일 시안을 한눈에 볼 수 있는 데모 페이지 추가

### Changed
- **데이터 최적화**: locations.csv 내의 불필요한 중복 항목(약 244개) 제거 및 데이터 무결성 강화

### Technical
- APK 크기: 57.3MB (arm64-v8a), 49.6MB (armeabi-v7a)
- 데이터 용량 절감: locations.csv 약 5% 용량 감소

## [1.0.1] - 2026-02-06

### Added
- **홈 화면 거리 표시**: 인기 맛집 및 섹터별 맛집 리스트에서 현재 위치로부터의 거리 표시

### Technical
- APK 크기: 55MB (arm64-v8a), 47.2MB (armeabi-v7a)

## [1.0.0] - 2026-02-06

### Added
- **지도 기능**
  - 네이버 지도 통합 및 실시간 맛집 마커 표시
  - 섹터별 커스텀 마커 (미슐랭, 흑백요리사, TV 예능)
  - 외부 지도 앱 연동 (네이버, 카카오, 구글)
  - 현재 위치 기반 맛집 탐색

- **검색 및 필터**
  - 지역 기반 검색 (주소/지명으로 해당 지역 맛집 탐색)
  - 다중 섹터 필터 (여러 조건 동시 선택)
  - 거리 슬라이더 (0-50km)
  - 섹터별 자동 뷰 모드 (흑백요리사/미슐랭 → 전국 보기)

- **사용자 기능**
  - 프로필 편집 (닉네임, 상태 메시지, 프로필 이미지)
  - 저장한 맛집 (북마크)
  - 다녀온 곳 (방문 기록 및 월별 통계)
  - 최근 본 맛집 (최대 50개, 개별/전체 삭제)

- **개인화**
  - 미식 DNA 분석 (PEAT 테스트)
  - 음식 취향 설정 (맵기, 선호/기피 음식)
  - 자동 특성 생성 ("매운맛 탐험가" 등)

- **알림**
  - 근처 맛집 알림 (300m-2km 반경 설정)
  - 섹터별 알림 (흑백요리사, 미슐랭, 예능)

- **UI/UX**
  - 섹터 라벨 (미슐랭 등급, 시즌 정보)
  - 거리 표시 (현재 위치 기준)
  - 섹터별 맞춤 플레이스홀더 이미지
  - Blue Fusion 테마 적용
  - 홈 버튼 초기화 기능

### Changed
- 용어 통일: '촬영지' → '맛집'
- 설문 UI 색상: 레드/골드 → Blue Fusion
- 검색창 UI: 흰색 배경, '지역 검색' 힌트
- 최근 검색어 저장 로직: 엔터/검색 버튼 클릭 시에만 저장

### Fixed
- 지도 마커 타원형 → 원형 (1:1 비율)
- 홈 버튼 재클릭 시 필터 초기화
- 섹터 카테고리 오류 수정
- 데이터 동기화 안정성 개선

### Technical
- Flutter 3.10.4
- Dart SDK ^3.10.4
- APK 크기: 55MB (arm64-v8a)
- 맛집 데이터: 1.8MB CSV
- 디버그 서명 사용 (릴리스 키 필요)

## [1.1.0] - 2026-02-14

### Added
- **미슐랭 가이드 2025 고도화**: 전국 미슐랭 2025 맛집 데이터 보완 및 전용 마커 적용
- **미슐랭 셰프 정보**: 미슐랭 2025 레스토랑의 헤드 셰프 정보 수집 및 노출
- **전현무계획 3**: 최신 예능 프로그램 데이터 및 전용 동적 썸네일 추가

### Changed
- **카드 UI 통일**: 미슐랭과 흑백요리사 카드의 높이를 동일하게 맞추고 셰프 정보를 시각적으로 강조
- **데이터 정제**: 자가 진단 및 다단계 클렌징을 통한 셰프 성함 데이터 품질 향상

### Technical
- **CSV 파싱 로직**: 미슐랭 셰프 이름 추출을 위한 CsvDataService 최적화
- **UI 일관성**: Food Sector 전용 높이 보존(Space Reservation) 로직 적용

## [Unreleased]

### Planned for v1.2.0
- 리뷰 작성 및 관리 기능
- 맛집 추천 알고리즘 고도화
- 소셜 공유 기능
- 오프라인 모드 지원

---

[1.0.0]: https://github.com/yourusername/tastemap/releases/tag/v1.0.0
