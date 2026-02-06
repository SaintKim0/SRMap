# GitHub 저장소 정보 설명

## username과 repo-name이란?

### username (사용자명)
- **GitHub 계정의 사용자명**입니다
- GitHub에 로그인할 때 사용하는 계정 이름
- 예: `john-doe`, `myusername`, `developer123`

**확인 방법:**
1. GitHub 웹사이트에 로그인
2. 우측 상단 프로필 아이콘 클릭
3. 사용자명 확인
   - 또는 URL: `https://github.com/여기부분이-username`

### repo-name (저장소 이름)
- **프로젝트 저장소의 이름**입니다
- GitHub에서 프로젝트를 저장하는 폴더 이름
- 예: `screenmap-backup`, `my-app`, `project-name`

**확인 방법:**
1. GitHub에서 저장소 페이지 열기
2. URL에서 확인: `https://github.com/username/여기부분이-repo-name`

---

## 전체 형식: `username/repo-name`

### 예시
```
myusername/screenmap-backup
john-doe/my-flutter-app
developer123/project-name
```

### 현재 프로젝트 기준 추천
프로젝트 폴더명이 `01_ScreenMap_Backup`이므로:

**추천 저장소 이름:**
- `screenmap-backup` (소문자, 하이픈 사용)
- `screen-map-backup`
- `scene-map-app`

**전체 예시:**
```
GITHUB_REPO=myusername/screenmap-backup
```

---

## 저장소가 없다면?

### 방법 1: GitHub에서 새 저장소 생성

1. **GitHub 접속**
   - https://github.com 로그인

2. **새 저장소 생성**
   - 우측 상단 "+" 아이콘 클릭
   - "New repository" 선택

3. **저장소 정보 입력**
   - Repository name: `screenmap-backup` (또는 원하는 이름)
   - Description: "SceneMap - 촬영지 정보 앱"
   - Public 또는 Private 선택
   - **"Create repository" 클릭**

4. **저장소 이름 확인**
   - 생성 후 URL 확인
   - 예: `https://github.com/myusername/screenmap-backup`
   - → `myusername/screenmap-backup`이 정답!

### 방법 2: 기존 저장소 사용

이미 GitHub에 저장소가 있다면:
- 저장소 페이지 URL에서 확인
- 예: `https://github.com/myusername/existing-repo`
- → `myusername/existing-repo` 사용

---

## .env 파일 설정 예시

### 예시 1: 새로 만든 저장소
```env
GITHUB_REPO=myusername/screenmap-backup
GITHUB_BRANCH=main
GITHUB_RAW_BASE_URL=https://raw.githubusercontent.com/myusername/screenmap-backup/main
IMAGE_SERVER_BASE_URL=https://raw.githubusercontent.com/myusername/screenmap-backup/main/assets/images
```

### 예시 2: 기존 저장소 사용
```env
GITHUB_REPO=myusername/my-existing-repo
GITHUB_BRANCH=main
GITHUB_RAW_BASE_URL=https://raw.githubusercontent.com/myusername/my-existing-repo/main
IMAGE_SERVER_BASE_URL=https://raw.githubusercontent.com/myusername/my-existing-repo/main/assets/images
```

---

## 체크리스트

- [ ] GitHub 사용자명 확인 (프로필에서 확인)
- [ ] 저장소 생성 또는 기존 저장소 확인
- [ ] `.env`에 `GITHUB_REPO=username/repo-name` 형식으로 입력
- [ ] 슬래시(`/`) 포함 확인
- [ ] 대소문자 정확히 입력

---

## 주의사항

1. **슬래시 필수**: `username/repo-name` (중간에 `/` 필수)
2. **대소문자 구분**: 정확히 입력해야 함
3. **공백 없음**: 저장소 이름에 공백 사용 시 하이픈(`-`) 사용 권장

---

## 빠른 확인 방법

GitHub 저장소 페이지 URL이 있다면:
```
https://github.com/USERNAME/REPO-NAME
                    ↑        ↑
                  username  repo-name
```

→ `.env`에 입력: `GITHUB_REPO=USERNAME/REPO-NAME`
