# Stage 7: 마이 페이지 및 설정 PRD

## 1. 개요
### 목표
사용자 개인화 기능(찜 목록)과 앱 설정 기능을 제공하는 '마이 페이지'를 구현합니다.

### 범위
- **프로필 영역**: 사용자 닉네임, 프로필 이미지 (MVP 단계에서는 로컬 고정 데이터 또는 랜덤 데이터 사용)
- **나의 활동**:
    - **저장한 촬영지 (찜 목록)**: 사용자가 북마크한 장소 목록 표시
    - **최근 본 촬영지**: 최근 조회한 장소 목록 (Local DB 연동)
- **설정 및 기타**:
    - 테마 설정 (다크 모드/라이트 모드)
    - 앱 버전 정보
    - 공지사항/문의하기 (더미 링크 연결)

---

## 2. 주요 기능 명세

### 2.1 마이 페이지 화면 (My Page Screen)
- **경로**: 하단 탭바 4번째 '마이'
- **구성**:
    1.  **헤더**: 프로필 이미지, 닉네임, 편집 버튼(기능 미동작)
    2.  **통계 요약**: 저장 00, 방문 00
    3.  **메뉴 리스트**:
        - 저장한 촬영지 -> `BookmarkListScreen` 이동
        - 최근 본 촬영지 -> `RecentHistoryScreen` 이동
        - 설정 -> `SettingsScreen` 이동

### 2.2 저장한 촬영지 (Bookmarked Locations)
- **기능**: 사용자가 북마크한 위치들을 그리드 또는 리스트 형태로 표시
- **데이터**: `BookmarkProvider` 또는 `LocationRepository`의 `bookmark_count` > 0 인 항목?(아님 별도 bookmark 테이블 확인 필요하지만 현재 구조상 `Location` 모델의 `isBookmarked` 로컬 관리가 없으므로 `BookmarkProvider` 확인 필요)
- **Note**: 현재 `BookmarkProvider`가 있지만 실제 DB 연동이 `bookmark_count`만 있고 User별 북마크 여부 테이블이 없는 상태일 수 있음. MVP에서는 `SharedPreferences`나 로컬 DB에 ID 리스트를 저장하는 방식으로 구현 필요.

### 2.3 설정 화면 (Settings Screen)
- **기능**:
    - 테마 변경: 시스템/라이트/다크
    - 앱 버전 표시: `package_info_plus` 사용 (없으면 하드코딩)

---

## 3. 기술 구현 계획

### 3.1 데이터 관리
- **Bookmark 기능 보완**:
    - 현재 `BookmarkProvider`가 있으나, 실제 유저의 "찜" 여부를 저장하는 로컬 DB 테이블(`user_bookmarks`)이 필요할 수 있음.
    - 또는 간단하게 `PreferencesService`에 `List<String> bookmarkedIds` 저장.
    - **결정**: `PreferencesService`를 확장하여 북마크된 Location ID 리스트 관리.

### 3.2 화면 구현
- `lib/presentation/screens/my_page_screen.dart`: 메인 마이 페이지
- `lib/presentation/screens/bookmark_list_screen.dart`: 찜 목록
- `lib/presentation/screens/settings_screen.dart`: 설정

---

## 4. 작업 순서
1.  **Backend (Local)**: `PreferencesService`에 북마크 관리 기능 추가 (add, remove, check).
2.  **Provider**: `BookmarkProvider`를 `PreferencesService`와 연동하여 상태 관리하도록 업데이트.
3.  **UI**: 마이 페이지 및 하위 화면 구현.
4.  **Integration**: 상세 화면의 '저장' 버튼과 연동 확인.
