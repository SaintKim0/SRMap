# locations.csv 업데이트 간단 가이드

## 📍 파일 위치
```
d:\00_projects\02_TasteMap\assets\data\locations.csv
```

## 🔄 업데이트 3단계

### 1️⃣ 데이터 수정
```csv
# CSV 형식 (15개 컬럼)
no,media_type,title,place_name,place_type,description,opening_hours,break_time,closed_days,address,latitude,longitude,phone,last_updated,michelin_tier

# 예시: 새 맛집 추가
8035,show,1박2일 시즌4,새맛집,restaurant,설명,매일 11-22시,없음,연중무휴,서울 강남구 테헤란로 123,37.123456,127.123456,02-1234-5678,2026-02-06,
```

**필수 컬럼**: no, media_type, title, place_name, address, latitude, longitude, last_updated

**media_type**: `show`, `movie`, `kpop`, `michelin`, `black_white`

### 2️⃣ 파일 교체
```bash
# 1. 백업 (중요!)
cp assets/data/locations.csv assets/data/locations_backup.csv

# 2. 수정한 파일로 교체
# UTF-8 인코딩으로 저장 필수!
```

### 3️⃣ 테스트 및 배포
```bash
# 1. 앱에서 테스트
flutter run
# 앱에서 'r' 키 (Hot Restart)

# 2. 버전 업데이트 (pubspec.yaml)
version: 1.0.2+3

# 3. CHANGELOG 작성

# 4. 빌드
flutter build apk --split-per-abi --release
```

## 🛠️ 위도/경도 찾기

### 네이버 지도
1. https://map.naver.com
2. 맛집 검색
3. URL에서 좌표 확인: `?lng=127.123&lat=37.123`

### Google Maps
1. 맛집 위치 우클릭
2. "이 위치의 좌표" 클릭

## ⚠️ 주의사항

### 절대 금지
- ❌ `no` 번호 재정렬 (기존 데이터 깨짐)
- ❌ 컬럼 순서/이름 변경
- ❌ UTF-8이 아닌 인코딩 사용

### 필수
- ✅ 백업 먼저
- ✅ UTF-8 인코딩
- ✅ 15개 컬럼 유지
- ✅ 위도/경도 범위 확인 (한국: 위도 33-38.6, 경도 124-132)

## 📋 체크리스트

- [ ] CSV 백업 완료
- [ ] UTF-8 인코딩 확인
- [ ] 위도/경도 검증
- [ ] 앱 테스트 완료
- [ ] 버전 번호 업데이트
- [ ] CHANGELOG 작성
- [ ] APK 빌드

---

**상세 가이드**: `DATA_UPDATE_GUIDE.md` 참고
