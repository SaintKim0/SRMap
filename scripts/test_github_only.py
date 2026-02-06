"""
GitHub 업로드 기능만 테스트하는 스크립트
작은 테스트 이미지를 생성하여 GitHub에 업로드합니다.
"""
import os
import base64
import requests
from pathlib import Path
import dotenv

# PIL은 선택사항
try:
    from PIL import Image, ImageDraw, ImageFont
    HAS_PIL = True
except ImportError:
    HAS_PIL = False

# .env 파일 로드
dotenv.load_dotenv()

# 설정
GITHUB_TOKEN = os.getenv('GITHUB_TOKEN')
GITHUB_REPO = os.getenv('GITHUB_REPO')
GITHUB_BRANCH = os.getenv('GITHUB_BRANCH', 'main')
GITHUB_IMAGE_PATH = os.getenv('GITHUB_IMAGE_PATH', 'assets/images')


def create_test_image(text: str, filename: str):
    """테스트 이미지 생성"""
    if HAS_PIL:
        try:
            # 400x300 이미지 생성
            img = Image.new('RGB', (400, 300), color='lightblue')
            draw = ImageDraw.Draw(img)
            
            # 텍스트 추가
            try:
                # 한글 폰트 시도 (없으면 기본 폰트)
                font = ImageFont.truetype("malgun.ttf", 40)  # Windows 맑은 고딕
            except:
                try:
                    font = ImageFont.truetype("arial.ttf", 40)
                except:
                    font = ImageFont.load_default()
            
            # 텍스트 중앙 배치
            bbox = draw.textbbox((0, 0), text, font=font)
            text_width = bbox[2] - bbox[0]
            text_height = bbox[3] - bbox[1]
            position = ((400 - text_width) // 2, (300 - text_height) // 2)
            
            draw.text(position, text, fill='black', font=font)
            
            # 저장
            img.save(filename, 'PNG')
            return True
        except Exception as e:
            print(f"[오류] 이미지 생성 실패: {e}")
            return False
    else:
        # PIL이 없으면 텍스트 파일로 대체
        return False


def upload_file_to_github(file_path: Path, repo_path: str):
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
            'message': f'Test upload: {file_path.name}',
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
        print(f"[오류] GitHub 업로드 실패: {e}")
        if hasattr(e, 'response') and e.response is not None:
            try:
                error_data = e.response.json()
                print(f"   오류 메시지: {error_data.get('message', 'Unknown error')}")
            except:
                pass
        return None


def test_github_upload():
    """GitHub 업로드 테스트"""
    print("[TEST] GitHub 업로드 기능 테스트")
    print(f"   저장소: {GITHUB_REPO}")
    print(f"   브랜치: {GITHUB_BRANCH}\n")
    
    # 설정 확인
    if not GITHUB_TOKEN:
        print("[오류] GitHub 토큰이 없습니다!")
        print("   .env 파일에 GITHUB_TOKEN을 설정하세요.")
        return
    
    if not GITHUB_REPO:
        print("[오류] GitHub 저장소 정보가 없습니다!")
        print("   .env 파일에 GITHUB_REPO를 설정하세요.")
        return
    
    # 테스트 이미지 생성
    test_dir = Path('assets/images/test')
    test_dir.mkdir(parents=True, exist_ok=True)
    
    test_image_path = test_dir / 'test_image.png'
    
    print("[1단계] 테스트 파일 생성 중...")
    if HAS_PIL:
        if not create_test_image('GitHub Test', str(test_image_path)):
            # 이미지 생성 실패 시 텍스트 파일로 대체
            print("   [대체] 이미지 생성 실패, 텍스트 파일로 테스트합니다.")
            test_image_path = test_dir / 'test.txt'
            with open(test_image_path, 'w', encoding='utf-8') as f:
                f.write('GitHub Upload Test File\nThis is a test file to verify GitHub upload functionality.')
    else:
        # PIL이 없으면 텍스트 파일로 대체
        print("   [정보] PIL이 없어 텍스트 파일로 테스트합니다.")
        test_image_path = test_dir / 'test.txt'
        with open(test_image_path, 'w', encoding='utf-8') as f:
            f.write('GitHub Upload Test File\nThis is a test file to verify GitHub upload functionality.')
    
    if not test_image_path.exists():
        print("[오류] 테스트 파일 생성 실패!")
        return
    
    print(f"   [완료] 테스트 파일 생성: {test_image_path}")
    
    # GitHub 업로드
    print("\n[2단계] GitHub에 업로드 중...")
    repo_path = f"{GITHUB_IMAGE_PATH}/test/{test_image_path.name}"
    print(f"   저장소 경로: {repo_path}")
    
    raw_url = upload_file_to_github(test_image_path, repo_path)
    
    if raw_url:
        print(f"\n[성공] 업로드 완료!")
        print(f"   Raw URL: {raw_url}")
        print(f"\n[확인] 다음 URL에서 확인하세요:")
        print(f"   https://github.com/{GITHUB_REPO}/blob/{GITHUB_BRANCH}/{repo_path}")
        print(f"\n[다음] 이제 전체 이미지 다운로드를 시작할 수 있습니다:")
        print(f"   python scripts/download_images.py")
    else:
        print("\n[실패] 업로드 실패!")
        print("   GitHub 토큰과 저장소 정보를 확인하세요.")


if __name__ == '__main__':
    test_github_upload()
