# 맛집지도 UI/UX 스타일 통일안

전체 앱에서 **글꼴·텍스트 크기·굵기**를 통일하고, **카드·버튼·패딩·간격·아이콘** 등 모든 요소를 **반응형**으로 설계하기 위한 기준 문서입니다.

- **§6** — 스마트폰 화면 크기별 **텍스트** 반응형 (Small &lt;360 / Medium &lt;400 / Large ≥400).
- **§8** — **카드·버튼·패딩·간격·아이콘** 반응형 수치 (S/M/L).
- **반응형 점검**: [doc/RESPONSIVE_AUDIT.md](RESPONSIVE_AUDIT.md) — 현재 반응형 적용/미적용 구간 목록.

---

## 1. 글꼴 (Font Family)

| 항목 | 값 | 비고 |
|------|-----|------|
| **기본 글꼴** | **Roboto** (Google Fonts) | `app_theme.dart`에서 `GoogleFonts.robotoTextTheme()` 사용 중 |
| **한글 지원** | Roboto 기본 (시스템 폰트 폴백) | 필요 시 `NotoSansKR` 등 한글 전용 폰트 추가 검토 |

**권장**: 앱 전체에서 Theme의 `textTheme`만 사용하고, 인라인 `fontFamily` 지정은 지양합니다.

---

## 2. 텍스트 크기 체계 (Typography Scale)

### 2.1 역할별 크기 정의

Material 3 Text Theme 역할을 기준으로, **고정 크기**를 정의합니다.  
(반응형이 필요한 곳만 별도 breakpoint 적용)

| 역할 | 용도 | fontSize | fontWeight | 사용 예 |
|------|------|----------|------------|---------|
| **displayLarge** | 대형 타이틀 (스플래시 등) | 32 | bold | — |
| **displayMedium** | 페이지급 대제목 | 28 | bold | — |
| **displaySmall** | 섹션 대제목 | 24 | bold | 마이페이지 닉네임, 모달 제목 |
| **headlineLarge** | 화면/카드 제목 | 20 | bold | 카드 제목, 바텀시트 제목 |
| **headlineMedium** | 부제목 | 18 | bold | 장소명(상세), 리스트 제목 |
| **headlineSmall** | 소제목 | 16 | bold | AppBar 타이틀, 섹션 헤더 |
| **titleLarge** | 카드/리스트 항목 제목 | 15 | bold | 맛집명, 작품명 |
| **titleMedium** | 일반 제목 | 14 | bold | 섹션 제목, 버튼 라벨 |
| **titleSmall** | 보조 제목 | 13 | bold | 칩, 작은 제목 |
| **bodyLarge** | 본문 큰 글자 | 16 | normal | 앱 안내 본문 |
| **bodyMedium** | 본문 기본 | 14 | normal | 설명, 리스트 부가 정보 |
| **bodySmall** | 본문 작은 글자 | 12 | normal | 주소, 캡션, 보조 문구 |
| **labelLarge** | 라벨(버튼·탭 등) | 14 | w600 | 네비게이션, 버튼 |
| **labelMedium** | 작은 라벨 | 12 | w500 | 칩, 뱃지 |
| **labelSmall** | 최소 라벨 | 11 | w500 | 통계 숫자 라벨, 푸터 |

### 2.2 숫자 요약 (기준 크기)

| 크기 | 역할 |
|------|------|
| **11** | labelSmall (통계 라벨, 최소 텍스트) |
| **12** | bodySmall, labelMedium (주소, 캡션, 칩) |
| **13** | titleSmall (작은 제목) |
| **14** | titleMedium, bodyMedium, labelLarge (섹션 제목, 본문, 버튼) |
| **15** | titleLarge (카드/리스트 제목) |
| **16** | headlineSmall, bodyLarge (AppBar, 본문 큰 글자) |
| **18** | headlineMedium (상세 제목) |
| **20** | headlineLarge (카드/바텀시트 제목) |
| **24** | displaySmall (대제목) |
| **28** | displayMedium |
| **32** | displayLarge |

---

## 3. 폰트 굵기 (Font Weight)

| 굵기 | 용도 |
|------|------|
| **FontWeight.w500** (Medium) | 라벨, 보조 텍스트 |
| **FontWeight.w600** (SemiBold) | 버튼, 탭, 강조 라벨 |
| **FontWeight.bold** (700) | 제목, 강조 문구 |
| **FontWeight.normal** (400) | 본문 |

인라인 사용 시 `FontWeight.w500` 등으로 통일하고, 가능하면 `Theme.of(context).textTheme`의 스타일을 그대로 사용합니다.

---

## 4. 텍스트 색상

| 역할 | 색상 | 용도 |
|------|------|------|
| **주요 텍스트** | `textPrimaryColor` (0xFF5A5754) / `Theme.textTheme.bodyLarge?.color` | 제목, 본문 |
| **보조 텍스트** | `textSecondaryColor` (0xFF3A4A5C) | 부가 정보 |
| **캡션/라벨** | `Colors.grey[600]` / `textTertiaryColor` | 주소, 날짜, 보조 문구 |
| **비활성/힌트** | `Colors.grey[500]` | placeholder, 비활성 |
| **강조(링크·버튼)** | `Theme.primaryColor` | 링크, CTA |

가능하면 `Theme.of(context).textTheme` 또는 `AppTheme.textPrimaryColor` 등 테마 상수 사용을 권장합니다.

---

## 5. 화면별 적용 가이드

### 5.1 공통

- **AppBar 타이틀**: `headlineSmall` (16, bold) — 화면 폭에 따라 14/16/17 등 반응형 유지 가능.
- **섹션 헤더** (예: "맛집 둘러보기", "최근 추가"): `titleMedium` (14, bold).
- **빈 상태 문구**: `bodyLarge`.
- **버튼 라벨**: `labelLarge` (14, w600) 또는 `titleMedium` (14, bold).

### 5.2 홈

- **앱 안내 제목**: `titleMedium` (14, bold).
- **앱 안내 본문**: `bodyMedium` (14).
- **섹터 버튼** (전체보기, 흑백요리사 등): `labelMedium` (12) 또는 작은 화면 10/11.
- **SectorCard 제목**: `headlineSmall` (16) 또는 `titleLarge` (15), bold.
- **SectorCard 칩**: `labelMedium` (12, w500).
- **작품 카드 제목**: `titleLarge` (15, bold).
- **작품 카드 보조(맛집 N개)**: `bodySmall` (12).

### 5.3 리스트·카드

- **맛집/장소명**: `titleLarge` (15, bold).
- **주소·부가정보**: `bodySmall` (12), 색상 grey[600]/700.
- **통계(조회수·저장)**: `labelSmall` (11) 또는 `bodySmall` (12).

### 5.4 상세(장소 상세)

- **장소명**: `headlineMedium` (18, bold).
- **주소·영업시간 등**: `bodySmall` (12).
- **섹션 제목**: `titleMedium` (14, bold).
- **바텀시트 제목**: `headlineLarge` (20, bold).
- **버튼 라벨(길찾기 등)**: `labelLarge` (14, w600).

### 5.5 마이페이지

- **닉네임**: `displaySmall` (24, bold).
- **한줄소개**: `bodyLarge` (16), grey[600].
- **통계 숫자**: `titleMedium` (14) 또는 20 bold.
- **통계 라벨**: `labelSmall` (11) 또는 `bodySmall` (12).
- **메뉴 항목**: `titleMedium` (14).

### 5.6 검색·설정·지도

- **검색 결과 제목**: `titleMedium` (14, bold).
- **설정 화면 제목**: `headlineSmall` (16, bold).
- **지도 바텀시트 제목**: `headlineLarge` (20, bold) 또는 `headlineMedium` (18).

---

## 6. 스마트폰 화면 크기별 반응형

### 6.1 브레이크포인트 정의

앱 전역에서 **화면 폭(screenWidth)** 기준으로 아래 3단계를 사용합니다.

| 구간 | 조건 | 대상 기기 예 |
|------|------|----------------|
| **Small (S)** | `screenWidth < 360` | 소형 폰 (약 4.7" 이하) |
| **Medium (M)** | `360 ≤ screenWidth < 400` | 중형 폰 (약 5"~5.5") |
| **Large (L)** | `screenWidth ≥ 400` | 대형 폰·폴더블 (약 5.5" 이상) |

**코드 예시**: `final w = MediaQuery.of(context).size.width;` 후 `w < 360`, `w < 400`으로 분기.

### 6.2 역할별 반응형 텍스트 크기

Theme의 **기준 크기(§2)** 는 **Large** 기준입니다. Small/Medium에서는 아래처럼 한 단계씩 줄입니다.

| 역할 | Small (&lt;360) | Medium (360~399) | Large (≥400) | 비고 |
|------|-----------------|------------------|-------------|------|
| **AppBar 타이틀** | 14 | 16 | 17 | headlineSmall 계열 |
| **섹션 헤더** | 13 | 14 | 15 | titleMedium 계열 |
| **카드/리스트 제목** | 13 | 14 | 15 | titleLarge (맛집명, 작품명) |
| **주소·캡션·보조** | 10 | 11 | 12 | bodySmall / labelMedium |
| **섹터 버튼(탭)** | 10 | 11 | 12 | labelMedium |
| **작품 카드 보조** | 11 | 12 | 13 | bodySmall / titleSmall |
| **버튼 라벨** | 11 | 12 | 13 | labelLarge 작은 버튼용 |
| **통계·아이콘 라벨** | 9 | 10 | 11 | labelSmall |

- **Display/Headline 대제목**(24, 20, 18)은 반응형 생략 가능(고정 권장).
- **본문**(16, 14)은 필요 시에만 14→13, 16→14 등 한 단계만 축소.

### 6.3 패딩·간격 반응형 (참고)

| 요소 | Small | Medium | Large |
|------|-------|--------|-------|
| **카드 내부 padding** | 6~8 | 8 | 10~12 |
| **섹션 좌우 padding** | 12 | 16 | 16 |
| **버튼 세로 padding** | 8 | 10 | 10~12 |
| **아이콘 크기(보조)** | 10~12 | 11~13 | 12~14 |

레이아웃 비율(예: 버튼 영역 80%)은 그대로 두고, **숫자만** 위 구간별로 적용하면 됩니다.

### 6.4 적용 규칙

1. **공통**: `final w = MediaQuery.of(context).size.width;`로 폭 확인 후, `w < 360` / `w < 400` 분기.
2. **텍스트**: 위 표에 맞춰 `Theme.of(context).textTheme.xxx.copyWith(fontSize: fontSize)` 형태로 반응형 크기 주입.
3. **유틸 도우미**(선택): `AppTypography.responsiveTitle(context)` 등으로 `BuildContext`만 넘겨 크기 반환하는 함수 두면 재사용에 유리합니다.

Theme 자체는 **Large 기준 고정 크기**로 두고, 화면·위젯에서 **반응형이 필요한 부분만** 위 표에 따라 분기하는 구성을 권장합니다.

---

## 7. 구현 상태 (app_theme.dart)

`lib/core/theme/app_theme.dart`에 아래 스타일이 정의되어 있습니다. 화면에서는 `Theme.of(context).textTheme.xxx`를 사용하면 됩니다.

- [x] `displayLarge` ~ `displaySmall` (32 / 28 / 24, bold)
- [x] `headlineLarge` (20), `headlineMedium` (18), `headlineSmall` (16) — bold
- [x] `titleLarge` (15), `titleMedium` (14), `titleSmall` (13) — bold
- [x] `bodyLarge` (16), `bodyMedium` (14), `bodySmall` (12)
- [x] `labelLarge` (14, w600), `labelMedium` (12, w500), `labelSmall` (11, w500)
- [x] 공통 색상: `textPrimaryColor` / `textSecondaryColor`

**다음 단계**: 각 화면·위젯에서 **인라인 `fontSize`·`fontWeight`** 를 점진적으로 `textTheme.xxx` 또는 `.copyWith(color: ...)`로 교체하면 통일감이 높아집니다.

---

## 8. 카드·버튼·전체 요소 반응형 설계 기준

앱 내 **카드, 버튼, 패딩, 간격, 아이콘, 모서리** 등 모든 요소는 동일 브레이크포인트(**§6**: S &lt;360 / M &lt;400 / L ≥400)에 맞춰 반응형으로 설계합니다.

### 8.1 패딩·여백 (Padding / Margin)

| 용도 | Small (&lt;360) | Medium (360~399) | Large (≥400) |
|------|-----------------|------------------|-------------|
| **화면 좌우 padding** (screenPadding) | 12 | 16 | 16 |
| **카드 내부 padding** (cardPadding) | 12 | 14 | 16 |
| **카드 margin** (세로/가로) | 6, 12 | 8, 16 | 8, 16 |
| **버튼 padding** (세로/가로) | 8, 12 | 10, 16 | 10~12, 20~24 |
| **섹션 간 세로 간격** (spacingL) | 20 | 24 | 24 |
| **요소 간 간격** (spacingM) | 12 | 16 | 16 |
| **작은 간격** (spacingS) | 8 | 8 | 10 |
| **최소 간격** (spacingXS) | 4 | 4 | 6 |

### 8.2 카드 (Card / Container)

| 항목 | Small | Medium | Large |
|------|-------|--------|-------|
| **borderRadius** (cardRadius) | 12 | 14 | 16 |
| **내부 padding** | 12 | 14 | 16 |
| **칩·태그 영역 height** (chipRowHeight) | 36 | 38 | 40 |
| **작품 카드 아이콘 박스** (iconBoxSize) | 48×48 | 52×52 | 56×56 |
| **아이콘 박스 borderRadius** | 8 | 10 | 10 |

### 8.3 버튼 (Button)

| 항목 | Small | Medium | Large |
|------|-------|--------|-------|
| **Elevated/Outlined padding** (세로/가로) | 8, 12 | 10, 16 | 12, 24 |
| **TextButton padding** | 4, 6 | 4, 8 | 4, 8 |
| **IconButton 최소 터치 영역** | 40×40 | 44×44 | 48×48 |
| **버튼 내 아이콘 크기** | 18 | 20 | 22~24 |
| **버튼 최소 높이** (길찾기 등) | 32 | 34 | 36~40 |

### 8.4 아이콘 크기 (Icon Size)

| 용도 | Small | Medium | Large |
|------|-------|--------|-------|
| **카드/섹션 제목 아이콘** (iconSizeL) | 20 | 22 | 24 |
| **리스트·보조 아이콘** (iconSizeM) | 12 | 13 | 14 |
| **캡션·라벨 아이콘** (iconSizeS) | 10 | 11 | 12 |
| **프로필 Avatar radius** | 44 | 48 | 50~52 |

### 8.5 기타

| 항목 | Small | Medium | Large |
|------|-------|--------|-------|
| **가로 스크롤 카드 높이** (선택) | 176 | 184 | 192 |
| **바텀시트 상단 padding** | 16 | 18 | 20 |
| **Divider 두께** | 1 | 1 | 1 |

### 8.6 적용 방법

1. **공통**: `final w = MediaQuery.of(context).size.width;` 후 `w < 360` / `w < 400` 분기.
2. **권장**: `lib/core/constants/` 에 **AppSpacing** (또는 **AppLayout**) 클래스를 두고, `AppSpacing.cardPadding(context)`, `AppSpacing.buttonPadding(context)` 등으로 S/M/L 값을 반환하도록 하면 화면·위젯에서 일관 적용 가능.
3. **점검**: 반응형 미적용 구간은 **doc/RESPONSIVE_AUDIT.md** 에 정리되어 있으므로, 해당 위치부터 위 표에 맞춰 교체하면 됩니다.

---

## 9. 요약

| 구분 | 기준 |
|------|------|
| **글꼴** | Roboto (Theme textTheme) |
| **제목** | 24 / 20 / 18 / 16 / 15 / 14 / 13 (역할별, §2) |
| **본문** | 16 / 14 / 12 |
| **라벨·캡션** | 14 / 12 / 11 |
| **굵기** | 제목 bold, 본문 normal, 라벨 w500·w600 |
| **색상** | textPrimary / textSecondary / grey[600] 등 테마 통일 |
| **텍스트 반응형** | §6: Small/Medium/Large, 역할별 fontSize |
| **요소 반응형** | §8: 카드·버튼·패딩·간격·아이콘 S/M/L 수치 표 |
| **점검** | doc/RESPONSIVE_AUDIT.md — 미적용 구간 목록 |

- **기준 크기**: §2·§7 (Theme은 Large 기준 고정).
- **전체 반응형**: §6(텍스트) + §8(카드·버튼·패딩·간격·아이콘)을 적용하면, 카드·버튼 포함 앱 내 모든 요소가 스마트폰 화면 크기에 맞게 설계됩니다.
