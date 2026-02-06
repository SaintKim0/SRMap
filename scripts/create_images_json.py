"""
각 장소별로 images.json 파일을 생성하는 스크립트
GitHub에서 이미지 목록을 쉽게 가져올 수 있도록 합니다.
"""
import json
import os
from pathlib import Path
from typing import Dict

METADATA_FILE = 'assets/images/image_metadata.json'
OUTPUT_DIR = 'assets/images/json'


def create_images_json():
    """각 장소별 images.json 파일 생성"""
    if not os.path.exists(METADATA_FILE):
        print(f"❌ 메타데이터 파일이 없습니다: {METADATA_FILE}")
        return
    
    with open(METADATA_FILE, 'r', encoding='utf-8') as f:
        metadata = json.load(f)
    
    output_path = Path(OUTPUT_DIR)
    output_path.mkdir(parents=True, exist_ok=True)
    
    created_count = 0
    
    for location_id, location_data in metadata.items():
        if not location_data.get('processed', False):
            continue
        
        images = location_data.get('images', [])
        if not images:
            continue
        
        # images.json 생성
        json_data = {
            'location_id': location_id,
            'location_name': location_data.get('location_name', ''),
            'images': images,
            'count': len(images),
        }
        
        json_file = output_path / f'{location_id}.json'
        with open(json_file, 'w', encoding='utf-8') as f:
            json.dump(json_data, f, ensure_ascii=False, indent=2)
        
        created_count += 1
    
    print(f"✅ JSON 파일 생성 완료!")
    print(f"   📝 생성된 파일: {created_count}개")
    print(f"   📁 위치: {OUTPUT_DIR}")
    print(f"\n💡 이 파일들을 GitHub에 업로드하면")
    print(f"   ImageService가 자동으로 이미지 목록을 가져올 수 있습니다.")


if __name__ == '__main__':
    create_images_json()
