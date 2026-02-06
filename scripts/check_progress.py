"""진행 상황 확인 스크립트"""
import json
import os
from pathlib import Path

METADATA_FILE = 'assets/images/image_metadata.json'
DOWNLOADED_DIR = 'assets/images/downloaded'

# 메타데이터 확인
if os.path.exists(METADATA_FILE):
    with open(METADATA_FILE, 'r', encoding='utf-8') as f:
        metadata = json.load(f)
    
    processed = sum(1 for v in metadata.values() if isinstance(v, dict) and v.get('processed', False))
    with_images = sum(1 for v in metadata.values() if isinstance(v, dict) and v.get('images', []))
    
    print(f"[메타데이터]")
    print(f"  처리된 장소: {processed}개")
    print(f"  이미지가 있는 장소: {with_images}개")
    print(f"  총 메타데이터 항목: {len(metadata)}개")
else:
    print("[메타데이터] 파일이 없습니다")
    processed = 0

# 다운로드된 파일 확인
if os.path.exists(DOWNLOADED_DIR):
    downloaded_path = Path(DOWNLOADED_DIR)
    dirs = [d for d in downloaded_path.iterdir() if d.is_dir()]
    total_files = sum(len(list(d.iterdir())) for d in dirs)
    
    print(f"\n[다운로드된 파일]")
    print(f"  장소 폴더: {len(dirs)}개")
    print(f"  이미지 파일: {total_files}개")
    
    # 각 폴더별 이미지 수
    if len(dirs) > 0:
        print(f"\n[상세]")
        for d in sorted(dirs)[:10]:  # 처음 10개만
            files = list(d.iterdir())
            print(f"  {d.name}: {len(files)}개 이미지")
        if len(dirs) > 10:
            print(f"  ... 외 {len(dirs) - 10}개 폴더")
else:
    print(f"\n[다운로드된 파일] 폴더가 없습니다")

# 전체 진행률
total_locations = 15456  # CSV 파일의 총 장소 수
if processed > 0:
    progress = (processed / total_locations) * 100
    print(f"\n[전체 진행률]")
    print(f"  {processed}/{total_locations}개 ({progress:.2f}%)")
