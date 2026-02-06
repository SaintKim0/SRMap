"""
장소 이미지 다운로드 스크립트
실제 장소 이미지를 위해 TourAPI -> Wikimedia Commons 순으로만 사용.
- TourAPI: 한국관광공사 관광사진 (실제 장소). 일 1,000회 제한. .env에 TOUR_API_KEY
- Wikimedia Commons: 공개 API(commons.wikimedia.org/w/api.php) 사용. API 키 불필요.
  ※ 한도가 있는 건 'Wikimedia Enterprise'(enterprise.wikimedia.com) 상용 API이며,
    우리는 위키백과/공용 사이트가 쓰는 공개 MediaWiki API를 사용함 (별도 월 한도 없음, 이용 정책 준수).
- Commons에는 랜드마크·관광지·유명 장소 위주로 많고, 개별 식당/카페 등은 적을 수 있음.
- Pexels는 일반 스톡 위주라 특정 장소 이미지에 부적합하여 사용하지 않음.
"""
import os
import sys
import csv
import json
import time
import requests
import hashlib
from pathlib import Path
from typing import List, Dict, Optional
from urllib.parse import urlencode
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
CSV_FILE = 'assets/data/locations.csv'
OUTPUT_DIR = 'assets/images/downloaded'
METADATA_FILE = 'assets/images/image_metadata.json'
MAX_IMAGES_PER_LOCATION = 5
DAILY_LIMIT = 1000  # 일일 트래픽 제한
REQUEST_DELAY = 0.1  # API 요청 간 지연 (초)

# 서버 설정 (선택사항)
SERVER_BASE_URL = os.getenv('IMAGE_SERVER_BASE_URL', '')  # 예: 'https://your-server.com/images'
UPLOAD_TO_SERVER = os.getenv('UPLOAD_TO_SERVER', 'false').lower() == 'true'


def get_image_hash(url: str) -> str:
    """이미지 URL의 해시값 생성 (중복 체크용)"""
    return hashlib.md5(url.encode()).hexdigest()


def search_tour_api_images(keyword: str, max_results: int = 5) -> List[str]:
    """TourAPI를 사용하여 이미지 검색"""
    if not TOUR_API_KEY:
        print(f"[경고] TourAPI 키가 없습니다. '{keyword}' 스킵")
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
        # 429 Too Many Requests = 일일 트래픽 한도 도달
        if response.status_code == 429:
            raise Exception('DAILY_LIMIT_REACHED')
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
        err_msg = str(e)
        if err_msg == 'DAILY_LIMIT_REACHED':
            raise  # 상위에서 처리 (메타데이터 저장 후 종료)
        print(f"[오류] TourAPI 검색 실패 ({keyword}): {e}")
        return []


def search_wikimedia_images(keyword: str, max_results: int = 5) -> List[str]:
    """Wikimedia Commons API로 이미지 검색 (API 키 불필요)."""
    try:
        # 1) 키워드로 파일 검색 (namespace 6 = File)
        search_url = 'https://commons.wikimedia.org/w/api.php'
        headers = {'User-Agent': 'ScreenMap/1.0 (https://github.com; contact@example.com)'}
        params = {
            'action': 'query',
            'list': 'search',
            'srsearch': keyword,
            'srnamespace': 6,
            'srlimit': max_results,
            'format': 'json',
        }
        r = requests.get(search_url, params=params, headers=headers, timeout=10)
        r.raise_for_status()
        data = r.json()
        queries = data.get('query', {})
        search = queries.get('search', [])
        if not search:
            return []
        # namespace 6 검색 시 title은 이미 "File:파일명" 형식
        titles = [s['title'] for s in search if s.get('title')]
        if not titles:
            return []
        # 2) 이미지 URL 조회 (한 번에 여러 파일)
        params2 = {
            'action': 'query',
            'titles': '|'.join(titles[:max_results]),
            'prop': 'imageinfo',
            'iiprop': 'url',
            'format': 'json',
        }
        r2 = requests.get(search_url, params=params2, headers=headers, timeout=10)
        r2.raise_for_status()
        data2 = r2.json()
        pages = data2.get('query', {}).get('pages', {})
        urls = []
        for pid, p in pages.items():
            if pid == '-1':
                continue
            info = (p.get('imageinfo') or [{}])[0]
            u = info.get('url')
            if u and u.startswith('http'):
                urls.append(u)
        return urls[:max_results]
    except Exception as e:
        print(f"[Wikimedia] 검색 실패 ({keyword}): {e}")
        return []


def download_image(image_url: str, save_path: Path) -> bool:
    """이미지 다운로드"""
    try:
        response = requests.get(image_url, timeout=30, stream=True)
        response.raise_for_status()
        
        # 이미지 확장자 확인
        content_type = response.headers.get('content-type', '')
        if 'image' not in content_type:
            print(f"⚠️  이미지가 아닌 파일: {image_url}")
            return False
        
        # 확장자 결정
        ext = '.jpg'
        if 'jpeg' in content_type:
            ext = '.jpg'
        elif 'png' in content_type:
            ext = '.png'
        elif 'webp' in content_type:
            ext = '.webp'
        
        # 파일 저장
        save_path = save_path.with_suffix(ext)
        with open(save_path, 'wb') as f:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)
        
        return True
    
    except Exception as e:
        print(f"[오류] 이미지 다운로드 실패 ({image_url}): {e}")
        return False


def upload_to_server(local_path: Path, location_id: str, image_index: int) -> Optional[str]:
    """서버에 이미지 업로드 (선택사항)"""
    if not UPLOAD_TO_SERVER or not SERVER_BASE_URL:
        return None
    
    try:
        # TODO: 실제 서버 업로드 로직 구현
        # 예: FTP, S3, 또는 REST API를 통한 업로드
        # 여기서는 예시만 제공
        filename = f"{location_id}_{image_index}{local_path.suffix}"
        server_url = f"{SERVER_BASE_URL}/{filename}"
        
        # 실제 업로드 코드는 서버 타입에 따라 다름
        # with open(local_path, 'rb') as f:
        #     files = {'image': f}
        #     response = requests.post(f"{SERVER_BASE_URL}/upload", files=files)
        #     server_url = response.json()['url']
        
        return server_url
    
    except Exception as e:
        print(f"[오류] 서버 업로드 실패: {e}")
        return None


def process_locations():
    """모든 장소의 이미지를 다운로드"""
    # 출력 디렉토리 생성
    output_path = Path(OUTPUT_DIR)
    output_path.mkdir(parents=True, exist_ok=True)
    
    # 메타데이터 로드 (이미 처리한 장소 추적)
    metadata = {}
    if os.path.exists(METADATA_FILE):
        with open(METADATA_FILE, 'r', encoding='utf-8') as f:
            metadata = json.load(f)
    
    # CSV 파일 읽기
    locations_processed = 0
    images_downloaded = 0
    api_calls = 0
    
    with open(CSV_FILE, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        locations = list(reader)
    
    print(f"[정보] 총 {len(locations)}개 장소 처리 시작...")
    print(f"[정보] TourAPI: {'사용' if TOUR_API_KEY else '미설정'}, Wikimedia: 사용 (실제 장소 이미지)")
    print(f"[정보] 일일 트래픽 제한(TourAPI): {DAILY_LIMIT}회")
    print(f"[정보] API 요청 간 지연: {REQUEST_DELAY}초\n")
    
    for idx, row in enumerate(locations, 1):
        location_id = row.get('no', str(idx))
        location_name = row.get('place_name', '').strip()
        address = row.get('address', '').strip()
        content_title = row.get('title', '').strip()
        
        if not location_name:
            continue
        
        # 이미 처리한 장소는 스킵
        if location_id in metadata and metadata[location_id].get('processed', False):
            print(f"[스킵] [{idx}/{len(locations)}] {location_name} - 이미 처리됨")
            continue
        
        # 일일 트래픽 제한 체크
        if api_calls >= DAILY_LIMIT:
            print(f"\n[경고] 일일 트래픽 제한 도달! ({api_calls}/{DAILY_LIMIT})")
            print("[안내] 내일 다시 실행하거나 API 키를 추가로 발급받으세요.")
            break
        
        # 검색 키워드 조합 (개선: 콘텐츠 제목 제거, 장소명 + 지역명만 사용)
        search_keywords = [location_name]
        
        if address:
            # 주소에서 시/군/구 추출
            address_parts = address.split()
            city_district = None
            
            # 첫 번째 부분이 도/시인 경우
            if address_parts and (address_parts[0].endswith('도') or address_parts[0].endswith('시')):
                # 두 번째 부분이 시/군/구인 경우
                if len(address_parts) > 1 and (address_parts[1].endswith('시') or 
                                                address_parts[1].endswith('군') or 
                                                address_parts[1].endswith('구')):
                    # 세 번째 부분도 구인 경우 (예: "경기도 수원시 영통구")
                    if len(address_parts) > 2 and address_parts[2].endswith('구'):
                        city_district = f"{address_parts[1]} {address_parts[2]}"
                    else:
                        city_district = address_parts[1]
                else:
                    # 첫 번째 부분만 (예: "서울특별시")
                    city_district = address_parts[0]
            # 첫 번째 부분이 시/군/구인 경우
            elif address_parts and (address_parts[0].endswith('시') or 
                                     address_parts[0].endswith('군') or 
                                     address_parts[0].endswith('구')):
                city_district = address_parts[0]
            # 두 번째 부분이 시/군/구인 경우
            elif len(address_parts) > 1 and (address_parts[1].endswith('시') or 
                                              address_parts[1].endswith('군') or 
                                              address_parts[1].endswith('구')):
                city_district = address_parts[1]
            
            if city_district:
                search_keywords.append(city_district)
        
        keyword = ' '.join(search_keywords)  # 장소명 + 시/군/구만 사용
        
        print(f"[검색] [{idx}/{len(locations)}] {location_name} - 검색 중...")
        
        # API 호출
        api_calls += 1
        try:
            image_urls = search_tour_api_images(keyword, MAX_IMAGES_PER_LOCATION)
        except Exception as e:
            if str(e) == 'DAILY_LIMIT_REACHED':
                print(f"\n[한도] TourAPI 일일 트래픽 한도 도달 (429). 진행 상황 저장 후 종료합니다.")
                with open(METADATA_FILE, 'w', encoding='utf-8') as f:
                    json.dump(metadata, f, ensure_ascii=False, indent=2)
                print(f"[안내] 내일 다시 'python scripts/download_images.py' 실행 시 이어서 진행됩니다.")
                return
            raise
        time.sleep(REQUEST_DELAY)  # API 요청 간 지연
        
        # TourAPI 결과 없으면 Wikimedia Commons로 대체 (실제 장소/랜드마크 사진 많음)
        if not image_urls:
            image_urls = search_wikimedia_images(keyword, MAX_IMAGES_PER_LOCATION)
            if image_urls:
                print(f"   [Wikimedia] {len(image_urls)}개 이미지 검색됨")
            time.sleep(0.2)
        
        if not image_urls:
            print(f"   [실패] 이미지를 찾을 수 없음")
            metadata[location_id] = {
                'processed': True,
                'images': [],
                'keyword': keyword,
            }
            continue
        
        # 이미지 다운로드
        downloaded_images = []
        location_dir = output_path / location_id
        location_dir.mkdir(exist_ok=True)
        
        for img_idx, image_url in enumerate(image_urls, 1):
            image_hash = get_image_hash(image_url)
            image_filename = f"{image_hash}"
            image_path = location_dir / image_filename
            
            # 이미 다운로드한 이미지는 스킵
            if image_path.exists() or any(f.startswith(image_hash) for f in os.listdir(location_dir)):
                print(f"   [스킵] 이미지 {img_idx} - 이미 다운로드됨")
                downloaded_images.append(str(image_path))
                continue
            
            print(f"   [다운로드] 이미지 {img_idx}/{len(image_urls)} 다운로드 중...")
            if download_image(image_url, image_path):
                downloaded_images.append(str(image_path))
                images_downloaded += 1
                
                # 서버 업로드 (선택사항)
                if UPLOAD_TO_SERVER:
                    server_url = upload_to_server(image_path, location_id, img_idx)
                    if server_url:
                        downloaded_images[-1] = server_url  # 로컬 경로를 서버 URL로 교체
            else:
                print(f"   [실패] 이미지 {img_idx} 다운로드 실패")
        
        # 메타데이터 저장
        metadata[location_id] = {
            'processed': True,
            'images': downloaded_images,
            'keyword': keyword,
            'location_name': location_name,
            'processed_at': time.strftime('%Y-%m-%d %H:%M:%S'),
        }
        
        locations_processed += 1
        
        # 진행 상황 저장 (중간 저장)
        if idx % 10 == 0:
            with open(METADATA_FILE, 'w', encoding='utf-8') as f:
                json.dump(metadata, f, ensure_ascii=False, indent=2)
            print(f"\n[저장] 진행 상황 저장됨 ({idx}/{len(locations)})\n")
    
    # 최종 메타데이터 저장
    with open(METADATA_FILE, 'w', encoding='utf-8') as f:
        json.dump(metadata, f, ensure_ascii=False, indent=2)
    
    print(f"\n[완료] 완료!")
    print(f"   처리된 장소: {locations_processed}개")
    print(f"   다운로드된 이미지: {images_downloaded}개")
    print(f"   API 호출 횟수: {api_calls}회")
    print(f"   메타데이터: {METADATA_FILE}")


if __name__ == '__main__':
    if not TOUR_API_KEY:
        print("[안내] TourAPI 키가 없습니다. Wikimedia Commons만 사용합니다.")
        print("   실제 장소 이미지 확보를 위해 .env에 TOUR_API_KEY 권장.")
    process_locations()
