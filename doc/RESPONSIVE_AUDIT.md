# 반응형 설계 점검 결과

카드, 버튼, 패딩·간격 등 **앱 내 모든 요소**의 반응형 적용 여부를 점검한 결과입니다.  
브레이크포인트: **Small &lt;360** / **Medium 360~399** / **Large ≥400** (화면 폭 기준).

---

## 1. 반응형 적용됨 (MediaQuery / LayoutBuilder 사용)

| 위치 | 요소 | 반응형 처리 내용 |
|------|------|------------------|
| **home_screen** | AppBar 타이틀 | `screenWidth`에 따라 14/16/17 |
| **home_screen** | 섹터 버튼(전체보기 등) | fontSize 10/11/12, padding vertical 8/10 |
| **home_screen** | 섹터 영역 | navAreaWidth 80%, 버튼 균등 분할 |
| **home_screen** | 작품 카드 제목·보조 | titleFontSize 13/14/15, addressFontSize, iconSize |
| **home_screen** | 섹션 헤더 | titleFontSize, buttonFontSize, horizontalPadding 12/16 |
| **home_screen** | 가로 리스트(카드) | cardAreaWidth 90%, cardSpacing 8/10, cardWidth 계산 |
| **location_card** | 세로/가로 카드 | titleFontSize, addressFontSize, statFontSize, iconSize, padding 6~10, SizedBox 간격 |

---

## 2. 고정값 사용 — 반응형 미적용

### 2.1 카드 (Card / Container)

| 위치 | 요소 | 현재 값 | 권장 |
|------|------|---------|------|
| **sector_card** | margin | horizontal 16, vertical 8 | §9 표: screenPadding, cardMargin |
| **sector_card** | padding | 16 | §9: cardPadding S/M/L |
| **sector_card** | borderRadius | 16 | §9: cardRadius (12/14/16) |
| **sector_card** | 칩 영역 height | 40 | §9: chipRowHeight (36/38/40) |
| **sector_card** | 아이콘·텍스트 | fontSize 24/20/14, size 14 | Theme + §6 반응형 fontSize |
| **home_screen** | 앱 안내 카드 padding | 16 | cardPadding 반응형 |
| **home_screen** | 작품 카드 아이콘 박스 | 56×56, borderRadius 10 | §9: iconBoxSize, iconBoxRadius |
| **home_screen** | KMDb 카드 padding | 12 | cardPadding |
| **my_page_screen** | body padding | 16 | screenPadding |
| **my_page_screen** | 통계 카드 padding | vertical 20 | cardPadding |
| **my_page_screen** | 통계 카드 borderRadius | 16 | cardRadius |
| **my_page_screen** | 프로필 Avatar | radius 50, Icon 50 | §9: avatarSize |
| **location_detail_screen** | 카드 margin/padding | 16/12/16 등 | screenPadding, cardPadding |
| **map_screen** | 바텀시트 padding | 20 | sheetPadding |
| **location_list_screen** | 리스트 padding | 16, bottom 12 | screenPadding |
| **search_screen** | 리스트 padding | 16, bottom 12 | screenPadding |
| **bookmark_list_screen** 등 | 화면 padding | 16, bottom 16 | screenPadding |

### 2.2 버튼 (Elevated / Outlined / Text / Icon)

| 위치 | 요소 | 현재 값 | 권장 |
|------|------|---------|------|
| **location_detail_screen** | 길찾기 버튼 padding | vertical 10, horizontal 4 | §9: buttonPadding |
| **home_screen** | OutlinedButton (맛집 둘러보기) | styleFrom 기본 | buttonPadding 반응형 |
| **home_screen** | TextButton (전체보기) | padding 6~8, 4 | buttonPadding |
| **app_theme** | ElevatedButton | horizontal 24, vertical 12 | §9: buttonPadding (S/M/L) |
| **IconButton** 전역 | 아이콘·영역 | 기본 크기 | §9: iconButtonTapTarget |

### 2.3 간격·패딩 (SizedBox / EdgeInsets)

| 위치 | 현재 | 권장 |
|------|------|------|
| **home_screen** | SizedBox(height: 16/24), padding 8/12 | §9: spacingXS/S/M/L |
| **sector_card** | SizedBox 8/12, Divider 1 | spacingXS, spacingS |
| **location_detail_screen** | 다양한 SizedBox 4/6/8/12/16 | spacingXS ~ spacingL |
| **my_page_screen** | 8/16/24 | spacingS/M/L |
| **리스트 항목 간격** | 8/12/16 | spacingS 또는 spacingM |

### 2.4 아이콘 크기

| 위치 | 현재 | 권장 |
|------|------|------|
| **sector_card** | 아이콘 24, 화살표 14 | §9: iconSizeL, iconSizeS |
| **location_card** | iconSize 12~14 (반응형 있음) | 유지, §9 표와 통일 |
| **작품 카드** | 28 (내부 아이콘) | iconSizeM 반응형 |
| **KMDb 로딩** | 16 | iconSizeS |
| **CircleAvatar** | 50 | avatarSize 반응형 |

### 2.5 기타

| 위치 | 요소 | 현재 | 권장 |
|------|------|------|------|
| **home_screen** | 가로 리스트 카드 height | 192 고정 | §9: horizontalCardHeight 또는 비율 |
| **location_detail_screen** | 하단 버튼 height | 34 | buttonMinHeight 반응형 |
| **skeleton_loader** | padding 12/16, borderRadius 4/12 | §9 spacing·cardRadius |

---

## 3. 정리

- **반응형 적용**: 홈(섹터·작품 카드·섹션 헤더·가로 리스트), **location_card** 일부.
- **미적용**: **sector_card** 전부, **my_page_screen** 전부, **location_detail_screen** 대부분, **map_screen** 바텀시트, **리스트/검색/설정** 화면 패딩, **버튼 padding** 전역, **아이콘 크기** 다수, **간격(SizedBox)** 대부분.

**다음 단계**:  
1) **UI_UX_STYLE_GUIDE.md §9**에 따라 카드·버튼·패딩·간격·아이콘의 **S/M/L 수치**를 정리하고,  
2) 위 표의 **권장** 항목대로 `MediaQuery.of(context).size.width` 분기 또는 공통 **AppSpacing** 유틸 도입 후 점진 적용.
