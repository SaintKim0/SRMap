@echo off
REM GitHub 이미지 서버 빠른 시작 스크립트 (Windows)

echo 🚀 GitHub 이미지 서버 설정 시작
echo.

REM 1. Python 패키지 확인
echo 📦 Python 패키지 확인 중...
python -c "import requests" 2>nul
if errorlevel 1 (
    echo    requests 패키지 설치 중...
    pip install requests python-dotenv
)
echo    ✅ Python 패키지 준비 완료
echo.

REM 2. .env 파일 확인
echo 📝 .env 파일 확인 중...
if not exist .env (
    echo    ❌ .env 파일이 없습니다!
    exit /b 1
)

findstr /C:"GITHUB_TOKEN" .env >nul
if errorlevel 1 (
    echo    ⚠️  GITHUB_TOKEN이 설정되지 않았습니다.
    echo    scripts\GITHUB_SETUP_GUIDE.md를 참고하여 설정하세요.
    exit /b 1
)

findstr /C:"GITHUB_REPO" .env >nul
if errorlevel 1 (
    echo    ⚠️  GITHUB_REPO가 설정되지 않았습니다.
    echo    scripts\GITHUB_SETUP_GUIDE.md를 참고하여 설정하세요.
    exit /b 1
)

echo    ✅ .env 파일 설정 확인 완료
echo.

REM 3. 이미지 다운로드 확인
echo 🖼️  이미지 다운로드 상태 확인 중...
if not exist "assets\images\downloaded" (
    echo    ⚠️  다운로드된 이미지가 없습니다.
    echo    먼저 이미지를 다운로드하세요:
    echo    python scripts\download_images.py
    echo.
    set /p choice="지금 다운로드를 시작하시겠습니까? (y/n) "
    if /i "%choice%"=="y" (
        python scripts\download_images.py
    ) else (
        exit /b 0
    )
)
echo    ✅ 이미지 다운로드 확인 완료
echo.

REM 4. GitHub 업로드
echo 📤 GitHub에 이미지 업로드 시작...
python scripts\upload_to_github.py

echo.
echo ✅ 완료!
echo    앱을 재실행하면 GitHub 이미지를 사용합니다.
pause
