# SceneMap 프로젝트

## 프로젝트 개요
SceneMap은 화면 구성 및 매핑을 관리하는 Flutter 애플리케이션입니다.

## 기술 스택
- **Framework**: Flutter 3.10.4+
- **언어**: Dart
- **상태 관리**: Provider
- **라우팅**: GoRouter
- **로컬 저장소**: SharedPreferences, SQLite
- **이미지 처리**: ImagePicker, CachedNetworkImage

## 프로젝트 구조

```
lib/
├── core/                    # 핵심 기능
│   ├── constants/          # 상수 정의
│   ├── theme/              # 테마 설정
│   └── utils/              # 유틸리티 함수
├── data/                    # 데이터 레이어
│   ├── models/             # 데이터 모델
│   ├── repositories/       # 저장소 패턴
│   └── services/           # API 및 서비스
└── presentation/            # UI 레이어
    ├── screens/            # 화면
    ├── widgets/            # 재사용 가능한 위젯
    └── providers/          # 상태 관리 프로바이더

assets/
├── images/                  # 이미지 리소스
├── icons/                   # 아이콘 리소스
└── fonts/                   # 폰트 파일
```

## 주요 패키지

### 상태 관리
- `provider`: 상태 관리

### 네비게이션
- `go_router`: 선언적 라우팅

### 로컬 저장소
- `shared_preferences`: 키-값 저장소
- `sqflite`: SQLite 데이터베이스
- `path_provider`: 파일 경로 접근

### 이미지 처리
- `image_picker`: 이미지 선택
- `cached_network_image`: 네트워크 이미지 캐싱

### UI 컴포넌트
- `flutter_svg`: SVG 이미지 지원
- `google_fonts`: Google Fonts 사용

### 유틸리티
- `intl`: 국제화 및 날짜 포맷
- `uuid`: 고유 ID 생성
- `equatable`: 객체 비교 간소화

### HTTP & API
- `http`: HTTP 클라이언트
- `dio`: 고급 HTTP 클라이언트

### 코드 생성
- `json_annotation`: JSON 직렬화 어노테이션
- `build_runner`: 코드 생성 도구
- `json_serializable`: JSON 직렬화 코드 생성

## 시작하기

### 패키지 설치
```bash
flutter pub get
```

### 앱 실행
```bash
flutter run
```

### 코드 생성 (JSON 직렬화)
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## 개발 가이드라인

### 폴더 구조 규칙
- **core**: 앱 전반에서 사용되는 공통 기능
- **data**: 비즈니스 로직과 데이터 처리
- **presentation**: UI 관련 코드만 포함

### 네이밍 컨벤션
- 파일명: `snake_case.dart`
- 클래스명: `PascalCase`
- 변수/함수명: `camelCase`
- 상수: `UPPER_SNAKE_CASE`

## 다음 단계
1. 데이터 모델 정의
2. 화면 UI 구현
3. 상태 관리 설정
4. API 연동 (필요시)
