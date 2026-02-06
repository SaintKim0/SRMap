# GitHub를 이미지 서버로 사용하기

## 개요

GitHub를 무료 이미지 호스팅 서버로 사용하는 방법입니다. GitHub의 raw.githubusercontent.com을 통해 이미지를 제공합니다.

## 장점

- ✅ **완전 무료**: GitHub 무료 플랜 사용
- ✅ **CDN 효과**: GitHub의 글로벌 CDN 활용
- ✅ **버전 관리**: Git으로 이미지 버전 관리 가능
- ✅ **간단한 설정**: API만으로 업로드 가능
- ✅ **안정성**: GitHub 인프라 활용

## 단점

- ⚠️ **용량 제한**: 저장소당 1GB 권장 (무료 플랜)
- ⚠️ **파일 크기 제한**: 단일 파일 100MB 제한
- ⚠️ **대용량 파일**: GitHub LFS 필요 (무료 티어 1GB)

## 설정 방법

### 1단계: GitHub Personal Access Token 생성

1. GitHub에 로그인
2. Settings → Developer settings → Personal access tokens → Tokens (classic)
3. "Generate new token (classic)" 클릭
4. 권한 선택:
   - `repo` (전체 저장소 접근)
5. 토큰 생성 후 복사 (한 번만 표시됨!)

### 2단계: .env 파일 설정

```env
# GitHub 설정
GITHUB_TOKEN=ghp_your_personal_access_token_here
GITHUB_REPO=username/repo-name
GITHUB_BRANCH=main
GITHUB_IMAGE_PATH=assets/images
GITHUB_RAW_BASE_URL=https://raw.githubusercontent.com/username/repo-name/main

# ImageService에서 사용할 URL
IMAGE_SERVER_BASE_URL=https://raw.githubusercontent.com/username/repo-name/main/assets/images
```

### 3단계: 이미지 다운로드

```bash
python scripts/download_images.py
```

### 4단계: GitHub에 업로드

```bash
python scripts/upload_to_github.py
```

## GitHub LFS 사용 (대용량 파일)

이미지가 많거나 파일 크기가 큰 경우 GitHub LFS를 사용하세요.

### LFS 설치 및 설정

```bash
# Git LFS 설치 (한 번만)
git lfs install

# LFS로 추적할 파일 타입 지정
git lfs track "*.jpg"
git lfs track "*.png"
git lfs track "*.webp"

# .gitattributes 파일 커밋
git add .gitattributes
git commit -m "Add Git LFS tracking for images"
```

### LFS 사용 시 주의사항

- 무료 플랜: 1GB 저장소 + 1GB 대역폭/월
- 용량 초과 시 유료 플랜 필요 ($5/월)

## 대안: GitHub Releases 사용

이미지를 zip 파일로 압축하여 GitHub Releases에 업로드:

```bash
# 이미지 압축
cd assets/images/downloaded
zip -r ../../images.zip .

# GitHub Releases에 업로드 (수동 또는 API)
```

## URL 구조

업로드 후 이미지 URL:

```
https://raw.githubusercontent.com/username/repo-name/main/assets/images/1/abc123.jpg
https://raw.githubusercontent.com/username/repo-name/main/assets/images/2/def456.png
```

## 앱에서 사용

`.env`에 `IMAGE_SERVER_BASE_URL`을 설정하면 앱이 자동으로 GitHub 이미지를 우선 사용합니다:

```dart
// ImageService가 자동으로 다음 URL로 요청:
// https://raw.githubusercontent.com/username/repo-name/main/assets/images/{locationId}/images
```

## 저장소 구조 예시

```
your-repo/
├── assets/
│   └── images/
│       ├── 1/
│       │   ├── abc123.jpg
│       │   └── def456.png
│       ├── 2/
│       │   └── xyz789.jpg
│       └── ...
├── lib/
└── ...
```

## 용량 관리

### 현재 용량 확인

```bash
# 저장소 크기 확인 (GitHub 웹에서)
# Settings → Repository settings → Usage

# 또는 로컬에서
du -sh assets/images/downloaded
```

### 최적화 방법

1. **이미지 압축**: JPEG 품질 조정, WebP 변환
2. **필요한 이미지만 업로드**: 인기 장소 우선
3. **GitHub LFS**: 대용량 파일만 LFS 사용
4. **별도 저장소**: 이미지만 별도 저장소로 분리

## 문제 해결

### 업로드 실패

- GitHub 토큰 권한 확인 (`repo` 권한 필요)
- 저장소 이름 확인 (`username/repo-name` 형식)
- 파일 크기 확인 (100MB 이하)

### 용량 초과

- GitHub LFS 사용
- 이미지 압축
- 불필요한 이미지 삭제
- 별도 저장소 사용

### 느린 로딩

- CDN 캐싱 활용
- 이미지 최적화 (WebP 변환)
- 필요한 이미지만 로드

## 다음 단계

1. GitHub에 이미지 업로드 완료
2. `.env`에 `IMAGE_SERVER_BASE_URL` 설정
3. 앱 재실행 → 자동으로 GitHub 이미지 사용
4. API 트래픽 절약! 🎉
