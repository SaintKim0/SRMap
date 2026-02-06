"""
다운로드한 이미지를 locations.csv에 업데이트하는 스크립트
"""
import csv
import json
from pathlib import Path
from typing import Dict, List

CSV_FILE = 'assets/data/locations.csv'
METADATA_FILE = 'assets/images/image_metadata.json'
OUTPUT_CSV = 'assets/data/locations_updated.csv'
SERVER_BASE_URL = ''  # 서버 URL이 있으면 여기에 설정


def load_metadata() -> Dict:
    """이미지 메타데이터 로드"""
    if not Path(METADATA_FILE).exists():
        print(f"❌ 메타데이터 파일이 없습니다: {METADATA_FILE}")
        return {}
    
    with open(METADATA_FILE, 'r', encoding='utf-8') as f:
        return json.load(f)


def get_image_urls(location_id: str, metadata: Dict, use_server: bool = False) -> List[str]:
    """장소 ID에 해당하는 이미지 URL 목록 가져오기"""
    location_data = metadata.get(location_id, {})
    images = location_data.get('images', [])
    
    if not images:
        return []
    
    if use_server and SERVER_BASE_URL:
        # 서버 URL로 변환
        urls = []
        for img_path in images:
            if img_path.startswith('http'):
                urls.append(img_path)  # 이미 서버 URL
            else:
                # 로컬 경로를 서버 URL로 변환
                filename = Path(img_path).name
                urls.append(f"{SERVER_BASE_URL}/{location_id}/{filename}")
        return urls
    
    # 로컬 경로 반환 (앱에서 사용할 때는 assets 경로로 변환 필요)
    return images


def update_csv():
    """CSV 파일 업데이트"""
    metadata = load_metadata()
    
    if not metadata:
        print("❌ 업데이트할 이미지가 없습니다.")
        return
    
    updated_count = 0
    
    with open(CSV_FILE, 'r', encoding='utf-8') as infile, \
         open(OUTPUT_CSV, 'w', encoding='utf-8', newline='') as outfile:
        
        reader = csv.DictReader(infile)
        fieldnames = reader.fieldnames
        
        if 'image_urls' not in fieldnames:
            # image_urls 컬럼이 없으면 추가
            fieldnames = list(fieldnames) + ['image_urls']
        
        writer = csv.DictWriter(outfile, fieldnames=fieldnames)
        writer.writeheader()
        
        for row in reader:
            location_id = row.get('no', '')
            
            if location_id in metadata:
                image_urls = get_image_urls(location_id, metadata, use_server=False)
                # CSV에 저장할 때는 세미콜론으로 구분
                row['image_urls'] = ';'.join(image_urls) if image_urls else ''
                updated_count += 1
            
            writer.writerow(row)
    
    print(f"✅ CSV 업데이트 완료!")
    print(f"   📝 업데이트된 장소: {updated_count}개")
    print(f"   💾 출력 파일: {OUTPUT_CSV}")
    print(f"\n💡 {OUTPUT_CSV}를 확인한 후 locations.csv로 교체하세요.")


if __name__ == '__main__':
    update_csv()
