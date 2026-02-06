"""실시간 진행 상황 표시 스크립트"""
import json
import os
import sys
from pathlib import Path

# Windows 콘솔 인코딩
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

METADATA_FILE = 'assets/images/image_metadata.json'
DOWNLOADED_DIR = 'assets/images/downloaded'

def show_progress():
    """진행 상황 표시"""
    print("=" * 60)
    print("이미지 다운로드 진행 상황")
    print("=" * 60)
    
    # 메타데이터 확인
    if os.path.exists(METADATA_FILE):
        with open(METADATA_FILE, 'r', encoding='utf-8') as f:
            metadata = json.load(f)
        
        processed = sum(1 for v in metadata.values() if isinstance(v, dict) and v.get('processed', False))
        with_images = sum(1 for v in metadata.values() if isinstance(v, dict) and v.get('images', []))
        total_items = len(metadata)
        
        print(f"\n[메타데이터]")
        print(f"  처리된 장소: {processed}개")
        print(f"  이미지가 있는 장소: {with_images}개")
        print(f"  총 메타데이터 항목: {total_items}개")
    else:
        print(f"\n[메타데이터] 파일이 아직 생성되지 않았습니다")
        processed = 0
        total_items = 0
    
    # 다운로드된 파일 확인
    if os.path.exists(DOWNLOADED_DIR):
        downloaded_path = Path(DOWNLOADED_DIR)
        dirs = [d for d in downloaded_path.iterdir() if d.is_dir()]
        total_files = sum(len(list(d.iterdir())) for d in dirs)
        
        print(f"\n[다운로드된 파일]")
        print(f"  장소 폴더: {len(dirs)}개")
        print(f"  이미지 파일: {total_files}개")
        
        # 최근 처리된 장소 표시
        if dirs:
            print(f"\n[최근 다운로드된 장소]")
            for d in sorted(dirs, key=lambda x: x.stat().st_mtime, reverse=True)[:5]:
                files = list(d.iterdir())
                print(f"  {d.name}: {len(files)}개 이미지")
    else:
        print(f"\n[다운로드된 파일] 폴더가 아직 생성되지 않았습니다")
    
    # 전체 진행률
    total_locations = 15456
    if processed > 0:
        progress = (processed / total_locations) * 100
        remaining = total_locations - processed
        print(f"\n[전체 진행률]")
        print(f"  {processed:,}/{total_locations:,}개 ({progress:.2f}%)")
        print(f"  남은 장소: {remaining:,}개")
        
        # 예상 시간 계산 (일일 1000회 제한 기준)
        if processed < 1000:
            remaining_today = 1000 - processed
            days_needed = (remaining / 1000) + (1 if remaining % 1000 > 0 else 0)
            print(f"  오늘 남은 처리 가능: {remaining_today}개")
            print(f"  예상 소요 일수: 약 {days_needed}일")
    else:
        print(f"\n[전체 진행률] 아직 시작되지 않았습니다")
    
    print("=" * 60)

if __name__ == '__main__':
    show_progress()
