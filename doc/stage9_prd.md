# Stage 9: Public Data API & CSV Integration PRD

## 1. 개요
### 목표
공공데이터포털의 '미디어콘텐츠 영상 촬영지 데이터' API와 CSV 파일(초기 데이터)을 모두 활용하여 앱에 풍부한 촬영지 정보를 제공합니다.

### 전략: Hybrid approach
1.  **초기 로딩 (Fast Start)**: 로컬 CSV 파일(`assets/data/locations.csv`)을 읽어 초기 데이터를 즉시 표시합니다. (약 100+개 예상)
2.  **업데이트 (Freshness)**: 백그라운드에서 API를 호출하여 최신 데이터를 가져오고, 리스트를 업데이트(또는 병합)합니다.

---

## 2. 데이터 소스
### 2.1 CSV (Local)
- **파일**: `doc/한국문화정보원_미디어콘텐츠 영상 촬영지 데이터_20221125.csv` -> `assets/data/locations.csv`로 이동.
- **인코딩**: EUC-KR (CP949) 예상. `cp949` 패키지로 디코딩 필요.
- **데이터 매핑**:
    - `제목` -> `titl` (API 필드명과 통일)
    - `장소명` -> `poiNm`
    - `위도` -> `lcLa`
    - `경도` -> `lcLo`
    - `주소` -> `addr`

### 2.2 API (Remote)
- **URL**: `http://api.kcisa.kr/openapi/API_CNV_053/request`
- **Key**: 사용자 제공 Decoding Key.

---

## 3. 기술 구현 계획

### 3.1 Dependencies
- `csv`: CSV 파싱.
- `cp949`: 한글 인코딩 처리.
- `flutter_dotenv`: API Key 보안.
- `http`: API 호출.
- `xml`: API 응답 파싱.

### 3.2 Services
- **`CsvDataService`**:
    - `loadLocations()`: assets에서 CSV 읽어서 `Location` 리스트 반환.
- **`PublicDataService`**:
    - `fetchLocations()`: API 호출하여 `Location` 리스트 반환.
- **`LocationRepository` Update**:
    - `initialize()`에서 `CsvDataService` 먼저 호출하여 `_allLocations` 채움.
    - 그 후 `PublicDataService` 호출하여 결과가 있으면 `_allLocations` 업데이트 (중복 제거 로직 포함).

---

## 4. 작업 순서
1. `csv`, `cp949` 패키지 추가.
2. CSV 파일 이동 (`assets/data/`).
3. `CsvDataService` 구현 및 테스트.
4. `PublicDataService` 구현.
5. `LocationRepository` 통합.
