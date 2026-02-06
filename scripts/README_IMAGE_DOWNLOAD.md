# 이미지 다운로드 및 서버 저장 가이드

## 개요

**실제 장소 이미지**만 사용합니다: **TourAPI(한국관광공사) → Wikimedia Commons**. TourAPI 한도(일 1,000회)나 검색 실패 시 Wikimedia로 대체합니다. Pexels는 일반 스톡이라 특정 장소 이미지에 부적합하여 사용하지 않습니다.

- **Wikimedia 한도**: 이미지에 나오는 월 5,000회 한도는 **Wikimedia Enterprise**(enterprise.wikimedia.com) 상용 API 기준입니다. 우리는 **commons.wikimedia.org 공개 MediaWiki API**를 사용하며, 별도 월 한도는 없고 이용 정책·User-Agent 준수만 하면 됩니다.

### Commons에 우리가 원하는 이미지가 있을까?

| 장소 유형 | TourAPI | Wikimedia Commons |
|----------|---------|-------------------|
| **유명 관광지·랜드마크** (경복궁, 롯데타워, 국립공원 등) | ○ 많음 | ○ 많음 |
| **지역명·거리·지역 풍경** | △ 있음 | △ 있음 |
| **개별 식당·카페·드라마 촬영지** (이름 있는 소규모 장소) | △ 관광공사 등록분 위주 | △ 거의 없거나 검색 안 나올 수 있음 |

- **실제 장소 이미지**를 많이 채우려면 **TourAPI**가 핵심입니다. Commons는 보조(유명 장소·지역 풍경)로 두는 것이 좋습니다.
- 개별 상호명·비유명 촬영지 등은 둘 다 없을 수 있어, 그런 장소는 placeholder/픽토그램 등으로 처리하는 방안을 고려할 수 있습니다.

## 사용 방법

### 1. 필수 패키지 설치

```bash
pip install requests python-dotenv
```

### 2. 환경 변수 설정

`.env` 파일에 다음을 확인/추가:

```env
# 한국관광공사 TourAPI (실제 장소 관광사진, 일 1,000회 제한)
TOUR_API_KEY=your_tour_api_key_here
# 또는 DATA_GO_KR_API_KEY=...

# Wikimedia Commons 공개 API(commons.wikimedia.org/w/api.php) — API 키 없음
# ※ 랜드마크·관광지·유명 장소 위주로 많고, 개별 식당/카페 등은 검색 결과가 적을 수 있음

# 서버 업로드 사용 시 (선택사항)
IMAGE_SERVER_BASE_URL=https://your-server.com/images
UPLOAD_TO_SERVER=true
```

### 3. 이미지 다운로드 실행

```bash
python scripts/download_images.py
```

**특징:**
- 일일 트래픽 제한(1000회)을 자동으로 체크
- 중간에 중단되어도 재실행 시 이미 처리한 장소는 스킵
- 진행 상황을 `assets/images/image_metadata.json`에 저장
- 이미지는 `assets/images/downloaded/{location_id}/` 폴더에 저장

### 4. CSV 파일 업데이트

다운로드한 이미지 URL을 CSV 파일에 반영:

```bash
python scripts/update_location_images.py
```

이 스크립트는:
- `assets/images/image_metadata.json`을 읽어서
- 각 장소의 이미지 URL을 `locations.csv`에 추가
- 결과를 `locations_updated.csv`로 저장

### 5. 서버에 이미지 업로드

#### 옵션 A: 수동 업로드

1. `assets/images/downloaded/` 폴더의 모든 이미지를 서버에 업로드
2. 서버 URL을 `.env`의 `IMAGE_SERVER_BASE_URL`에 설정
3. `update_location_images.py`를 수정하여 서버 URL 사용

#### 옵션 B: 자동 업로드 (스크립트 수정 필요)

`download_images.py`의 `upload_to_server()` 함수를 실제 서버 타입에 맞게 수정:

**FTP 예시:**
```python
import ftplib

def upload_to_server(local_path: Path, location_id: str, image_index: int) -> Optional[str]:
    ftp = ftplib.FTP('your-ftp-server.com')
    ftp.login('username', 'password')
    # 업로드 로직
```

**AWS S3 예시:**
```python
import boto3

s3 = boto3.client('s3')
s3.upload_file(str(local_path), 'your-bucket', f'{location_id}/{filename}')
```

**REST API 예시:**
```python
with open(local_path, 'rb') as f:
    files = {'image': f}
    response = requests.post(f"{SERVER_BASE_URL}/upload", files=files)
    return response.json()['url']
```

## 파일 구조

```
assets/
├── images/
│   ├── downloaded/          # 다운로드한 이미지
│   │   ├── 1/              # 장소 ID별 폴더
│   │   │   ├── abc123.jpg
│   │   │   └── def456.png
│   │   └── 2/
│   └── image_metadata.json  # 이미지 메타데이터
└── data/
    ├── locations.csv        # 원본 CSV
    └── locations_updated.csv # 이미지 URL이 추가된 CSV
```

## 일일 트래픽 제한 대응

### 방법 1: 여러 날에 나눠서 실행

스크립트는 자동으로 일일 제한을 체크하고 중단합니다. 다음 날 다시 실행하면 이어서 진행됩니다.

### 방법 2: 여러 API 키 사용

`.env`에 여러 키를 설정하고 스크립트를 수정하여 키를 순환 사용:

```python
TOUR_API_KEY_1=key1
TOUR_API_KEY_2=key2
TOUR_API_KEY_3=key3
```

### 방법 3: API 키 추가 발급

공공데이터포털에서 추가 API 키를 발급받아 사용

## 주의사항

1. **저작권**: TourAPI 이미지는 공공누리 1유형으로 자유롭게 사용 가능하지만, 서버에 저장할 때도 출처 표기를 권장합니다.

2. **저장 공간**: 약 15,000개 장소 × 평균 3개 이미지 = 약 45,000개 이미지가 필요할 수 있습니다. 충분한 저장 공간을 확보하세요.

3. **네트워크**: 대량 다운로드는 시간이 오래 걸릴 수 있습니다. 안정적인 인터넷 연결이 필요합니다.

4. **서버 비용**: 클라우드 서버를 사용하는 경우 스토리지 및 대역폭 비용을 고려하세요.

## 추천 서버 옵션

1. **GitHub (추천)**: 완전 무료, CDN 효과, 버전 관리
   - `scripts/upload_to_github.py` 사용
   - `scripts/setup_github_images.md` 참고
2. **AWS S3 + CloudFront**: 확장성 좋음, CDN 제공
3. **Google Cloud Storage**: AWS 대안
4. **Vercel/Netlify**: 정적 파일 호스팅, 무료 티어 제공
5. **자체 서버**: FTP/SFTP로 업로드

## 다음 단계

1. 이미지 다운로드 완료 후
2. 서버에 업로드
   - **GitHub 사용 시**: `python scripts/upload_to_github.py`
   - **다른 서버**: 서버 타입에 맞게 업로드
3. `.env`에 `IMAGE_SERVER_BASE_URL` 설정
4. 앱 재실행 → 자동으로 서버 이미지 우선 사용
5. API 트래픽 절약! 🎉

## GitHub 사용 (추천)

GitHub를 이미지 서버로 사용하는 방법은 `scripts/setup_github_images.md`를 참고하세요.

**장점:**
- 완전 무료
- CDN 효과
- 버전 관리
- 간단한 설정
