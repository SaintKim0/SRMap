# 버전 관리 가이드

## 버전 번호 규칙 (Semantic Versioning)

```
MAJOR.MINOR.PATCH+BUILD
예: 1.2.3+45
```

- **MAJOR**: 주요 변경 (하위 호환성 없음)
- **MINOR**: 새 기능 추가 (하위 호환성 유지)
- **PATCH**: 버그 수정
- **BUILD**: 빌드 번호 (자동 증가)

## 버전 업데이트 절차

### 1. pubspec.yaml 수정
```yaml
version: 1.1.0+2  # MAJOR.MINOR.PATCH+BUILD
```

### 2. CHANGELOG.md 업데이트
```markdown
## [1.1.0] - 2026-02-XX

### Added
- 새로운 기능 설명

### Changed
- 변경된 기능 설명

### Fixed
- 수정된 버그 설명
```

### 3. 빌드 및 테스트
```bash
# 클린 빌드
flutter clean
flutter pub get

# 테스트 실행
flutter test

# APK 빌드
flutter build apk --split-per-abi --release
```

### 4. Git 태그 생성
```bash
git add .
git commit -m "Release v1.1.0"
git tag -a v1.1.0 -m "Release version 1.1.0"
git push origin main --tags
```

## 릴리스 체크리스트

### 빌드 전
- [ ] 버전 번호 업데이트 (pubspec.yaml)
- [ ] CHANGELOG.md 작성
- [ ] 모든 테스트 통과 확인
- [ ] 알려진 버그 문서화

### 빌드
- [ ] `flutter clean` 실행
- [ ] `flutter build apk --split-per-abi --release`
- [ ] APK 크기 확인 (arm64-v8a 기준 60MB 이하 권장)

### 빌드 후
- [ ] 실제 디바이스에서 테스트
- [ ] 주요 기능 동작 확인
- [ ] 릴리스 노트 작성
- [ ] Git 태그 생성 및 푸시

### 배포
- [ ] Google Play Console 업로드
- [ ] 스토어 설명 업데이트
- [ ] 스크린샷 업데이트 (필요시)

## 버전별 주요 변경사항 요약

### v1.0.0 (2026-02-06)
- 첫 번째 프로덕션 릴리스
- 네이버 지도 통합
- 섹터별 맛집 탐색
- 미식 DNA 분석
- 프로필 관리

### v1.1.0 (계획)
- 리뷰 기능
- 소셜 공유
- 추천 알고리즘 개선

## 긴급 패치 절차

버그 수정이 긴급한 경우:

1. PATCH 번호만 증가 (예: 1.0.0 → 1.0.1)
2. CHANGELOG에 `### Fixed` 섹션만 추가
3. 빠른 빌드 및 배포
4. 핫픽스 태그 생성: `git tag -a v1.0.1-hotfix`

## 참고 자료

- [Semantic Versioning](https://semver.org/)
- [Keep a Changelog](https://keepachangelog.com/)
- [Flutter Versioning](https://docs.flutter.dev/deployment/android#versioning-the-app)
