# Stage 6: 검색 및 필터링 강화 PRD

## 1. 개요
### 목표
사용자가 원하는 촬영지를 더 빠르고 정확하게 찾을 수 있도록 검색 기능을 고도화하고, 카테고리 필터링을 통해 탐색 경험을 개선합니다.

### 범위
- **검색 로직 개선**: 카테고리 필터가 포함된 상세 검색
- **실시간 검색**: 입력 중 검색어 자동 완성 또는 실시간 결과 표시 (Debounce 적용)
- **UI 개선**: 검색 화면 UX 강화 (최근 검색어, 인기 검색어, 필터 칩)
- **데이터베이스 업데이트**: 검색 쿼리에 카테고리 필터 조건 추가

---

## 2. 주요 기능 명세

### 2.1 상세 검색 (Advanced Search)
- **키워드 검색**: 기존 로직 유지 (장소명, 주소, 작품명)
- **카테고리 필터**: 검색 결과 내에서 특정 카테고리만 필터링
    - 전체 (Default)
    - 카페
    - 식당
    - 공원
    - 건물
    - 거리/기타

### 2.2 실시간 검색 (Real-time Search)
- **Debounce 타임**: 500ms (과도한 쿼리 방지)
- **기능**: 사용자가 타이핑하는 동안 자동으로 검색 수행 및 결과 갱신
- **UX**: 검색 중일 때 로딩 인디케이터 표시

### 2.3 검색 화면 UI (Search Screen UI)
- **상단**: 검색 바 (Text Field + Clear Button)
- **필터 영역**: 검색 바 하단에 가로 스크롤 가능한 칩(Chip) 목록
- **콘텐츠 영역**:
    - **입력 전**: 최근 검색어 (삭제 가능), 인기 검색어 (랭킹 표시)
    - **검색 중**: 결과 리스트 (이미지, 이름, 카테고리, 주소)
    - **결과 없음**: 안내 메시지 및 '다시 시도' 버튼

---

## 3. 기술 구현 계획

### 3.1 Database & Repository
- **`LocationRepository` 수정**:
    - `search` 메서드에 `String? category` 파라미터 추가
    - SQL 쿼리 `WHERE` 절에 카테고리 조건 동적 추가

### 3.2 Provider
- **`LocationDataProvider` 수정**:
    - `searchLocations` 메서드 시그니처 변경 (category 추가)
    - 검색 상태 관리 (Loading, Results, Error)

### 3.3 UI Components
- **`CategorySelector` 위젯**: 가로 스크롤 `ChoiceChip` 리스트 구현
- **`SearchScreen` 수정**:
    - `Timer`를 이용한 Debounce 로직 구현
    - 필터 상태(`selectedCategory`) 관리 및 검색 메서드 연동

---

## 4. 데이터 모델 변경
없음 (기존 `Location` 모델 사용)

---

## 5. 작업 순서
1.  **Backend (Local DB)**: `LocationRepository` 쿼리 업데이트
2.  **State Management**: `LocationDataProvider` 업데이트
3.  **UI Implementation**: `CategorySelector` 제작 및 `SearchScreen` 고도화
4.  **Integration**: 실시간 검색 및 필터 연동 테스트

---

## 6. 테스트 시나리오
- [ ] "도깨비" 검색 후 카테고리를 "카페"로 설정 시, 카페인 촬영지만 나와야 함
- [ ] 검색어 입력 후 0.5초 뒤 자동으로 결과가 나와야 함
- [ ] 최근 검색어 클릭 시 해당 검색어로 재검색 되어야 함
