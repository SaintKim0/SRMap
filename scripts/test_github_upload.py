"""
GitHub 이미지 업로드 테스트 스크립트
처음 몇 개 장소만 다운로드하고 GitHub에 업로드하여 테스트합니다.
"""
import os
import sys
import csv
import json
import time
import requests
import base64
from pathlib import Path
from typing import List, Optional
import dotenv

# Windows 콘솔 인코딩 설정
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

# .env 파일 로드
dotenv.load_dotenv()

# 설정
TOUR_API_KEY = os.getenv('TOUR_API_KEY') or os.getenv('DATA_GO_KR_API_KEY')
GITHUB_TOKEN = os.getenv('GITHUB_TOKEN')
GITHUB_REPO = os.getenv('GITHUB_REPO')
GITHUB_BRANCH = os.getenv('GITHUB_BRANCH', 'main')
GITHUB_IMAGE_PATH = os.getenv('GITHUB_IMAGE_PATH', 'assets/images')

CSV_FILE = 'assets/data/locations.csv'
OUTPUT_DIR = 'assets/images/downloaded'
TEST_COUNT = 5  # 테스트할 장소 개수


def search_tour_api_images(keyword: str, max_results: int = 3) -> List[str]:
    """TourAPI를 사용하여 이미지 검색"""
    if not TOUR_API_KEY:
        print(f"⚠️  TourAPI 키가 없습니다.")
        return []
    
    try:
        url = 'http://apis.data.go.kr/B551011/PhotoGalleryService1/gallerySearchList1'
        params = {
            'serviceKey': TOUR_API_KEY,
            'numOfRows': max_results,
            'pageNo': 1,
            'MobileOS': 'ETC',
            'MobileApp': 'SceneMap',
            'arrange': 'A',
            'keyword': keyword,
            '_type': 'json',
        }
        
        response = requests.get(url, params=params, timeout=10)
        response.raise_for_status()
        
        data = response.json()
        
        # 응답 구조 확인
        response_data = data.get('response', {})
        if not response_data:
            return []
        
        body = response_data.get('body', {})
        if not body:
            return []
        
        items_data = body.get('items', {})
        if not items_data:
            return []
        
        items = items_data.get('item', [])
        if not items:
            return []
        
        # 단일 항목인 경우 리스트로 변환
        if isinstance(items, dict):
            items = [items]
        elif not isinstance(items, list):
            return []
        
        image_urls = []
        for item in items:
            image_url = item.get('galWebImageUrl', '')
            if image_url:
                image_urls.append(image_url)
        
        return image_urls[:max_results]
    
    except Exception as e:
        print(f"[오류] TourAPI 검색 실패 ({keyword}): {e}")
        return []


def download_image(image_url: str, save_path: Path) -> bool:
    """이미지 다운로드"""
    try:
        response = requests.get(image_url, timeout=30, stream=True)
        response.raise_for_status()
        
        content_type = response.headers.get('content-type', '')
        if 'image' not in content_type:
            return False
        
        ext = '.jpg'
        if 'jpeg' in content_type:
            ext = '.jpg'
        elif 'png' in content_type:
            ext = '.png'
        elif 'webp' in content_type:
            ext = '.webp'
        
        save_path = save_path.with_suffix(ext)
        with open(save_path, 'wb') as f:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)
        
        return True
    
    except Exception as e:
        print(f"❌ 이미지 다운로드 실패: {e}")
        return False


def upload_file_to_github(file_path: Path, repo_path: str) -> Optional[str]:
    """단일 파일을 GitHub에 업로드"""
    if not GITHUB_TOKEN or not GITHUB_REPO:
        print("[오류] GitHub 토큰 또는 저장소 정보가 없습니다.")
        return None
    
    try:
        with open(file_path, 'rb') as f:
            file_content = f.read()
        
        content_base64 = base64.b64encode(file_content).decode('utf-8')
        url = f'https://api.github.com/repos/{GITHUB_REPO}/contents/{repo_path}'
        
        headers = {
            'Authorization': f'token {GITHUB_TOKEN}',
            'Accept': 'application/vnd.github.v3+json',
        }
        
        # 기존 파일 확인
        response = requests.get(url, headers=headers)
        sha = None
        if response.status_code == 200:
            sha = response.json().get('sha')
        
        data = {
            'message': f'Upload test image: {file_path.name}',
            'content': content_base64,
            'branch': GITHUB_BRANCH,
        }
        
        if sha:
            data['sha'] = sha
        
        response = requests.put(url, headers=headers, json=data)
        response.raise_for_status()
        
        raw_url = f'https://raw.githubusercontent.com/{GITHUB_REPO}/{GITHUB_BRANCH}/{repo_path}'
        return raw_url
    
    except Exception as e:
        print(f"[오류] GitHub 업로드 실패 ({file_path.name}): {e}")
        if hasattr(e, 'response') and e.response is not None:
            try:
                error_data = e.response.json()
                print(f"   오류 메시지: {error_data.get('message', 'Unknown error')}")
            except:
                pass
        return None


def test_github_upload():
    """테스트 실행"""
    print("[TEST] GitHub 이미지 업로드 테스트 시작")
    print(f"   저장소: {GITHUB_REPO}")
    print(f"   테스트 장소 수: {TEST_COUNT}개\n")
    
    # 설정 확인
    if not TOUR_API_KEY:
        print("[오류] TourAPI 키가 없습니다!")
        return
    
    if not GITHUB_TOKEN:
        print("[오류] GitHub 토큰이 없습니다!")
        return
    
    if not GITHUB_REPO:
        print("[오류] GitHub 저장소 정보가 없습니다!")
        return
    
    # 출력 디렉토리 생성
    output_path = Path(OUTPUT_DIR)
    output_path.mkdir(parents=True, exist_ok=True)
    
    # CSV 파일 읽기
    with open(CSV_FILE, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        locations = list(reader)
    
    print(f"[정보] 총 {len(locations)}개 장소 중 {TEST_COUNT}개 테스트\n")
    
    success_count = 0
    uploaded_count = 0
    
    for idx, row in enumerate(locations[:TEST_COUNT], 1):
        location_id = row.get('no', str(idx))
        location_name = row.get('place_name', '').strip()
        address = row.get('address', '').strip()
        content_title = row.get('title', '').strip()
        
        if not location_name:
            continue
        
        print(f"[{idx}/{TEST_COUNT}] {location_name}")
        print(f"   [검색] 이미지 검색 중...")
        
        # 검색 키워드
        keyword = location_name
        if content_title:
            keyword = f"{location_name} {content_title}"
        
        # 이미지 검색
        image_urls = search_tour_api_images(keyword, max_results=2)
        time.sleep(0.2)  # API 요청 간 지연
        
        if not image_urls:
            print(f"   [경고] 이미지를 찾을 수 없음\n")
            continue
        
        print(f"   [성공] {len(image_urls)}개 이미지 발견")
        
        # 이미지 다운로드 및 업로드
        location_dir = output_path / location_id
        location_dir.mkdir(exist_ok=True)
        
        uploaded_urls = []
        
        for img_idx, image_url in enumerate(image_urls, 1):
            image_filename = f"test_{location_id}_{img_idx}"
            image_path = location_dir / image_filename
            
            print(f"   [다운로드] 이미지 {img_idx} 다운로드 중...", end=' ')
            
            if download_image(image_url, image_path):
                print("OK", end=' ')
                
                # GitHub 업로드
                repo_path = f"{GITHUB_IMAGE_PATH}/{location_id}/{image_path.name}{image_path.suffix}"
                print(f"[업로드] GitHub 업로드 중...", end=' ')
                
                raw_url = upload_file_to_github(image_path, repo_path)
                
                if raw_url:
                    uploaded_urls.append(raw_url)
                    uploaded_count += 1
                    print("OK")
                    print(f"      URL: {raw_url}")
                else:
                    print("FAIL")
            else:
                print("FAIL")
        
        if uploaded_urls:
            success_count += 1
            print(f"   [완료] {len(uploaded_urls)}개 이미지 업로드됨\n")
        else:
            print(f"   [경고] 업로드 실패\n")
    
    print("=" * 50)
    print(f"[완료] 테스트 완료!")
    print(f"   성공한 장소: {success_count}/{TEST_COUNT}개")
    print(f"   업로드된 이미지: {uploaded_count}개")
    print(f"\n[확인] GitHub 저장소를 확인하세요:")
    print(f"   https://github.com/{GITHUB_REPO}/tree/{GITHUB_BRANCH}/{GITHUB_IMAGE_PATH}")
    print(f"\n[URL] Raw URL 예시:")
    if uploaded_count > 0:
        print(f"   https://raw.githubusercontent.com/{GITHUB_REPO}/{GITHUB_BRANCH}/{GITHUB_IMAGE_PATH}/...")
    print(f"\n[다음] 테스트가 성공하면 전체 이미지 다운로드를 시작하세요:")
    print(f"   python scripts/download_images.py")


if __name__ == '__main__':
    test_github_upload()
