"""
GitHub에 이미지를 업로드하는 스크립트
GitHub API를 사용하여 이미지를 저장소에 업로드합니다.
"""
import os
import json
import base64
import requests
from pathlib import Path
from typing import Dict, List, Optional
import dotenv

# .env 파일 로드
dotenv.load_dotenv()

# 설정
GITHUB_TOKEN = os.getenv('GITHUB_TOKEN')  # Personal Access Token 필요
GITHUB_REPO = os.getenv('GITHUB_REPO', '')  # 예: 'username/repo-name'
GITHUB_BRANCH = os.getenv('GITHUB_BRANCH', 'main')
GITHUB_IMAGE_PATH = os.getenv('GITHUB_IMAGE_PATH', 'assets/images')  # 저장소 내 경로
BASE_URL = os.getenv('GITHUB_RAW_BASE_URL', '')  # 예: 'https://raw.githubusercontent.com/username/repo/main'

METADATA_FILE = 'assets/images/image_metadata.json'
DOWNLOADED_IMAGES_DIR = 'assets/images/downloaded'


def get_github_api_url(endpoint: str) -> str:
    """GitHub API URL 생성"""
    return f'https://api.github.com/repos/{GITHUB_REPO}/{endpoint}'


def upload_file_to_github(file_path: Path, repo_path: str) -> Optional[str]:
    """단일 파일을 GitHub에 업로드"""
    if not GITHUB_TOKEN or not GITHUB_REPO:
        print("❌ GitHub 토큰 또는 저장소 정보가 없습니다.")
        return None
    
    try:
        # 파일 읽기
        with open(file_path, 'rb') as f:
            file_content = f.read()
        
        # Base64 인코딩
        content_base64 = base64.b64encode(file_content).decode('utf-8')
        
        # GitHub API: 파일 생성/업데이트
        url = get_github_api_url(f'contents/{repo_path}')
        
        headers = {
            'Authorization': f'token {GITHUB_TOKEN}',
            'Accept': 'application/vnd.github.v3+json',
        }
        
        # 기존 파일 확인
        response = requests.get(url, headers=headers)
        sha = None
        if response.status_code == 200:
            sha = response.json().get('sha')
        
        # 파일 업로드/업데이트
        data = {
            'message': f'Upload image: {file_path.name}',
            'content': content_base64,
            'branch': GITHUB_BRANCH,
        }
        
        if sha:
            data['sha'] = sha  # 업데이트인 경우
        
        response = requests.put(url, headers=headers, json=data)
        response.raise_for_status()
        
        # Raw URL 생성
        if BASE_URL:
            raw_url = f'{BASE_URL}/{repo_path}'
        else:
            # BASE_URL이 없으면 자동 생성
            raw_url = f'https://raw.githubusercontent.com/{GITHUB_REPO}/{GITHUB_BRANCH}/{repo_path}'
        
        return raw_url
    
    except Exception as e:
        print(f"❌ GitHub 업로드 실패 ({file_path.name}): {e}")
        return None


def upload_images_to_github():
    """다운로드한 모든 이미지를 GitHub에 업로드"""
    if not GITHUB_TOKEN:
        print("❌ 오류: GITHUB_TOKEN이 설정되지 않았습니다!")
        print("   GitHub Personal Access Token을 .env 파일에 추가하세요.")
        print("   생성 방법: https://github.com/settings/tokens")
        return
    
    if not GITHUB_REPO:
        print("❌ 오류: GITHUB_REPO가 설정되지 않았습니다!")
        print("   예: GITHUB_REPO=username/repo-name")
        return
    
    # 메타데이터 로드
    if not os.path.exists(METADATA_FILE):
        print(f"❌ 메타데이터 파일이 없습니다: {METADATA_FILE}")
        print("   먼저 download_images.py를 실행하세요.")
        return
    
    with open(METADATA_FILE, 'r', encoding='utf-8') as f:
        metadata = json.load(f)
    
    downloaded_dir = Path(DOWNLOADED_IMAGES_DIR)
    if not downloaded_dir.exists():
        print(f"❌ 다운로드된 이미지 폴더가 없습니다: {DOWNLOADED_IMAGES_DIR}")
        return
    
    print(f"📤 GitHub에 이미지 업로드 시작...")
    print(f"   저장소: {GITHUB_REPO}")
    print(f"   브랜치: {GITHUB_BRANCH}")
    print(f"   경로: {GITHUB_IMAGE_PATH}\n")
    
    uploaded_count = 0
    failed_count = 0
    
    # 각 장소별로 이미지 업로드
    for location_id, location_data in metadata.items():
        if not location_data.get('processed', False):
            continue
        
        images = location_data.get('images', [])
        if not images:
            continue
        
        location_name = location_data.get('location_name', location_id)
        print(f"📦 [{location_id}] {location_name} - {len(images)}개 이미지")
        
        location_dir = downloaded_dir / location_id
        if not location_dir.exists():
            continue
        
        uploaded_urls = []
        
        for img_idx, img_path in enumerate(images, 1):
            img_file = Path(img_path)
            
            # 파일이 존재하는지 확인
            if not img_file.exists():
                # location_id 폴더 내에서 찾기
                img_file = location_dir / img_file.name
                if not img_file.exists():
                    # 확장자 없이 찾기
                    for ext in ['.jpg', '.jpeg', '.png', '.webp']:
                        candidate = location_dir / f"{img_file.stem}{ext}"
                        if candidate.exists():
                            img_file = candidate
                            break
                    
                    if not img_file.exists():
                        print(f"   ⚠️  이미지 파일을 찾을 수 없음: {img_path}")
                        failed_count += 1
                        continue
            
            # GitHub 저장소 경로
            repo_path = f"{GITHUB_IMAGE_PATH}/{location_id}/{img_file.name}"
            
            print(f"   ⬆️  [{img_idx}/{len(images)}] {img_file.name} 업로드 중...", end=' ')
            
            # 업로드
            raw_url = upload_file_to_github(img_file, repo_path)
            
            if raw_url:
                uploaded_urls.append(raw_url)
                uploaded_count += 1
                print("✅")
            else:
                failed_count += 1
                print("❌")
        
        # 메타데이터 업데이트 (서버 URL로 교체)
        if uploaded_urls:
            metadata[location_id]['images'] = uploaded_urls
            metadata[location_id]['github_uploaded'] = True
            metadata[location_id]['github_uploaded_at'] = __import__('datetime').datetime.now().isoformat()
    
    # 메타데이터 저장
    with open(METADATA_FILE, 'w', encoding='utf-8') as f:
        json.dump(metadata, f, ensure_ascii=False, indent=2)
    
    print(f"\n✅ 업로드 완료!")
    print(f"   ✅ 성공: {uploaded_count}개")
    print(f"   ❌ 실패: {failed_count}개")
    print(f"   💾 메타데이터 업데이트됨: {METADATA_FILE}")


def create_github_release_with_images():
    """GitHub Release를 사용하여 이미지 압축 파일 업로드 (대용량 파일용)"""
    # 이 방법은 이미지가 너무 많을 때 사용
    # GitHub Releases는 각 릴리스당 최대 2GB 지원
    print("💡 GitHub Releases를 사용한 대용량 업로드는 별도 구현이 필요합니다.")
    print("   또는 GitHub LFS (Large File Storage)를 사용하세요.")


if __name__ == '__main__':
    upload_images_to_github()
