#!/bin/bash
# GitHub 이미지 서버 빠른 시작 스크립트

echo "🚀 GitHub 이미지 서버 설정 시작"
echo ""

# 1. Python 패키지 확인
echo "📦 Python 패키지 확인 중..."
if ! python -c "import requests" 2>/dev/null; then
    echo "   requests 패키지 설치 중..."
    pip install requests python-dotenv
fi
echo "   ✅ Python 패키지 준비 완료"
echo ""

# 2. .env 파일 확인
echo "📝 .env 파일 확인 중..."
if [ ! -f .env ]; then
    echo "   ❌ .env 파일이 없습니다!"
    exit 1
fi

if ! grep -q "GITHUB_TOKEN" .env; then
    echo "   ⚠️  GITHUB_TOKEN이 설정되지 않았습니다."
    echo "   scripts/GITHUB_SETUP_GUIDE.md를 참고하여 설정하세요."
    exit 1
fi

if ! grep -q "GITHUB_REPO" .env; then
    echo "   ⚠️  GITHUB_REPO가 설정되지 않았습니다."
    echo "   scripts/GITHUB_SETUP_GUIDE.md를 참고하여 설정하세요."
    exit 1
fi

echo "   ✅ .env 파일 설정 확인 완료"
echo ""

# 3. 이미지 다운로드 확인
echo "🖼️  이미지 다운로드 상태 확인 중..."
if [ ! -d "assets/images/downloaded" ]; then
    echo "   ⚠️  다운로드된 이미지가 없습니다."
    echo "   먼저 이미지를 다운로드하세요:"
    echo "   python scripts/download_images.py"
    echo ""
    read -p "지금 다운로드를 시작하시겠습니까? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        python scripts/download_images.py
    else
        exit 0
    fi
fi
echo "   ✅ 이미지 다운로드 확인 완료"
echo ""

# 4. GitHub 업로드
echo "📤 GitHub에 이미지 업로드 시작..."
python scripts/upload_to_github.py

echo ""
echo "✅ 완료!"
echo "   앱을 재실행하면 GitHub 이미지를 사용합니다."
