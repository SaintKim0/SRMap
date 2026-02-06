"""
이미지 다운로드 데이터 초기화 스크립트
메타데이터와 다운로드된 이미지를 백업하고 초기화합니다.
"""
import os
import shutil
from pathlib import Path
from datetime import datetime

METADATA_FILE = 'assets/images/image_metadata.json'
DOWNLOADED_DIR = 'assets/images/downloaded'
BACKUP_DIR = 'assets/images/backup'

def reset_download_data():
    """다운로드 데이터 초기화"""
    print("[초기화] 이미지 다운로드 데이터 초기화 시작\n")
    
    # 백업 디렉토리 생성
    backup_path = Path(BACKUP_DIR)
    backup_path.mkdir(parents=True, exist_ok=True)
    
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    
    # 메타데이터 파일 백업
    metadata_path = Path(METADATA_FILE)
    if metadata_path.exists():
        backup_metadata = backup_path / f'image_metadata_{timestamp}.json'
        shutil.copy2(metadata_path, backup_metadata)
        print(f"[백업] 메타데이터 파일 백업: {backup_metadata}")
        
        # 메타데이터 파일 삭제
        metadata_path.unlink()
        print(f"[삭제] 메타데이터 파일 삭제 완료")
    else:
        print(f"[정보] 메타데이터 파일이 없습니다")
    
    # 다운로드된 이미지 폴더 백업
    downloaded_path = Path(DOWNLOADED_DIR)
    if downloaded_path.exists():
        # 이미지 개수 확인
        image_count = sum(1 for _ in downloaded_path.rglob('*') if _.is_file())
        dir_count = sum(1 for _ in downloaded_path.iterdir() if _.is_dir())
        
        if image_count > 0:
            backup_downloaded = backup_path / f'downloaded_{timestamp}'
            shutil.copytree(downloaded_path, backup_downloaded)
            print(f"[백업] 다운로드된 이미지 백업: {backup_downloaded}")
            print(f"       장소 폴더: {dir_count}개, 이미지 파일: {image_count}개")
        
        # 다운로드 폴더 삭제
        shutil.rmtree(downloaded_path)
        print(f"[삭제] 다운로드 폴더 삭제 완료")
    else:
        print(f"[정보] 다운로드 폴더가 없습니다")
    
    print(f"\n[완료] 초기화 완료!")
    print(f"   백업 위치: {backup_path}")
    print(f"\n[다음] 개선된 검색 키워드로 다시 시작하세요:")
    print(f"   python scripts/download_images.py")


if __name__ == '__main__':
    reset_download_data()
