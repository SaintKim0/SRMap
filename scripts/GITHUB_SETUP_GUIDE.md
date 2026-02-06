# GitHub 이미지 서버 설정 가이드

## 🚀 빠른 시작 (5단계)

### 1단계: GitHub Personal Access Token 생성 (2분)

1. **GitHub에 로그인**
   - https://github.com 접속

2. **Settings로 이동**
   - 우측 상단 프로필 클릭 → Settings

3. **Developer settings**
   - 좌측 메뉴 하단 "Developer settings" 클릭

4. **Personal access tokens**
   - "Personal access tokens" → "Tokens (classic)" 클릭

5. **새 토큰 생성**
   - "Generate new token (classic)" 클릭
   - Note: "SceneMap Image Upload" 입력
   - Expiration: 원하는 기간 선택 (90일 권장)
   - **권한 선택**: `repo` 체크박스 선택 (전체 저장소 접근)
   - 하단 "Generate token" 클릭

6. **토큰 복사** ⚠️ 중요!
   - 생성된 토큰을 복사 (한 번만 표시됨!)
   - 예: `ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

---

### 2단계: 저장소 정보 확인 (1분)

현재 프로젝트의 GitHub 저장소 정보를 확인하세요:

**방법 1: Git 원격 저장소 확인**
```bash
git remote -v
```

출력 예시:
```
origin  https://github.com/username/repo-name.git (fetch)
origin  https://github.com/username/repo-name.git (push)
```

→ 저장소 이름: `username/repo-name`

**방법 2: GitHub 웹에서 확인**
- 저장소 페이지 URL에서 확인
- 예: `https://github.com/username/repo-name`
→ 저장소 이름: `username/repo-name`

**방법 3: 저장소가 없다면**
- GitHub에서 새 저장소 생성
- 또는 기존 저장소 사용

---

### 3단계: .env 파일 설정 (1분)

`.env` 파일에 다음을 추가하세요:

```env
# GitHub 설정
GITHUB_TOKEN=ghp_your_token_here
GITHUB_REPO=username/repo-name
GITHUB_BRANCH=main
GITHUB_IMAGE_PATH=assets/images
GITHUB_RAW_BASE_URL=https://raw.githubusercontent.com/username/repo-name/main

# ImageService에서 사용할 URL
IMAGE_SERVER_BASE_URL=https://raw.githubusercontent.com/username/repo-name/main/assets/images
```

**설정 예시:**
```env
# GitHub 설정
GITHUB_TOKEN=ghp_abc123def456ghi789jkl012mno345pqr678stu901vwx234yz
GITHUB_REPO=myusername/screenmap-backup
GITHUB_BRANCH=main
GITHUB_IMAGE_PATH=assets/images
GITHUB_RAW_BASE_URL=https://raw.githubusercontent.com/myusername/screenmap-backup/main

# ImageService에서 사용할 URL
IMAGE_SERVER_BASE_URL=https://raw.githubusercontent.com/myusername/screenmap-backup/main/assets/images
```

---

### 4단계: Python 패키지 설치 (1분)

```bash
pip install requests python-dotenv
```

또는

```bash
pip install -r requirements.txt
```

---

### 5단계: 테스트 업로드 (선택사항)

작은 테스트 이미지로 업로드가 잘 되는지 확인:

```bash
# 테스트 이미지 생성 (선택사항)
mkdir -p assets/images/downloaded/test
# 테스트 이미지 파일을 여기에 넣고...

# 업로드 테스트
python scripts/upload_to_github.py
```

---

## 📋 전체 워크플로우

### 1. 이미지 다운로드
```bash
python scripts/download_images.py
```

**특징:**
- TourAPI로 이미지 검색 및 다운로드
- 일일 1000회 제한 자동 체크
- 중단 후 재실행 가능

### 2. GitHub에 업로드
```bash
python scripts/upload_to_github.py
```

**특징:**
- 다운로드한 이미지를 GitHub에 업로드
- raw.githubusercontent.com URL 자동 생성
- 메타데이터에 URL 저장

### 3. 앱에서 사용
- `.env`에 `IMAGE_SERVER_BASE_URL` 설정 완료
- 앱 재실행 시 자동으로 GitHub 이미지 사용
- API 트래픽 절약! 🎉

---

## 🔍 설정 확인 체크리스트

- [ ] GitHub Personal Access Token 생성 완료
- [ ] `.env`에 `GITHUB_TOKEN` 추가
- [ ] `.env`에 `GITHUB_REPO` 추가 (형식: `username/repo-name`)
- [ ] `.env`에 `GITHUB_BRANCH` 추가 (보통 `main`)
- [ ] `.env`에 `IMAGE_SERVER_BASE_URL` 추가
- [ ] Python 패키지 설치 완료 (`requests`, `python-dotenv`)

---

## ❓ 문제 해결

### 토큰 권한 오류
- `repo` 권한이 선택되었는지 확인
- 토큰이 만료되지 않았는지 확인

### 저장소 접근 오류
- 저장소 이름 형식 확인: `username/repo-name` (슬래시 포함)
- 저장소가 private인 경우 토큰에 접근 권한 있는지 확인

### 업로드 실패
- 파일 크기 확인 (100MB 이하)
- 네트워크 연결 확인
- GitHub API 제한 확인 (시간당 5,000회)

---

## 📊 다음 단계

1. ✅ GitHub 설정 완료
2. ⏭️ 이미지 다운로드: `python scripts/download_images.py`
3. ⏭️ GitHub 업로드: `python scripts/upload_to_github.py`
4. ⏭️ 앱 테스트: 앱 재실행하여 이미지 로드 확인

---

## 💡 팁

- **용량 관리**: 이미지가 많으면 GitHub LFS 사용 고려
- **점진적 업로드**: 일일 제한을 고려하여 여러 날에 나눠서 업로드
- **이미지 최적화**: 업로드 전 이미지 압축 권장
