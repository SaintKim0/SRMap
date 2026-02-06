import csv
import requests
import time
import os
from dotenv import load_dotenv

# .env 파일 로드
load_dotenv()

# Naver Map API 키 (없으면 Search API 키 사용)
NAVER_CLIENT_ID = os.getenv('NAVER_MAP_CLIENT_ID') or os.getenv('NAVER_SEARCH_CLIENT_ID')
NAVER_CLIENT_SECRET = os.getenv('NAVER_MAP_CLIENT_SECRET') or os.getenv('NAVER_SEARCH_CLIENT_SECRET')

def geocode_address(address):
    """Naver Cloud Platform Geocoding API를 사용하여 주소를 위도/경도로 변환"""
    # NCP Geocoding API 엔드포인트 (공식 문서 기준)
    url = "https://maps.apigw.ntruss.com/map-geocode/v2/geocode"
    
    headers = {
        "x-ncp-apigw-api-key-id": NAVER_CLIENT_ID,
        "x-ncp-apigw-api-key": NAVER_CLIENT_SECRET,
        "Accept": "application/json"
    }
    
    params = {
        "query": address
    }
    
    try:
        response = requests.get(url, headers=headers, params=params)
        
        # 상세 오류 정보 출력
        if response.status_code != 200:
            print(f"  [X] API 오류 ({response.status_code}): {address}")
            print(f"     응답: {response.text[:200]}")
            return '0.0', '0.0', False
        
        data = response.json()
        
        # 응답 구조 확인
        if data.get('status') == 'OK' and data.get('addresses'):
            # 첫 번째 결과 사용
            result = data['addresses'][0]
            lat = result.get('y', '0.0')
            lng = result.get('x', '0.0')
            return lat, lng, True
        else:
            print(f"  [!] Geocoding 실패: {address}")
            print(f"     응답 상태: {data.get('status')}")
            return '0.0', '0.0', False
            
    except Exception as e:
        print(f"  [X] 예외 발생: {address}")
        print(f"     오류: {str(e)}")
        return '0.0', '0.0', False

def main():
    input_file = 'd:/00_projects/01_ScreenMap_Backup/doc/michelin_converted.csv'
    output_file = 'd:/00_projects/01_ScreenMap_Backup/doc/michelin_geocoded.csv'
    
    print(f"[Naver API 설정 확인]")
    print(f"  - Client ID: {NAVER_CLIENT_ID[:10]}..." if NAVER_CLIENT_ID else "  [X] Client ID 없음")
    print(f"  - Client Secret: {'설정됨' if NAVER_CLIENT_SECRET else '[X] 없음'}")
    
    if not NAVER_CLIENT_ID or not NAVER_CLIENT_SECRET:
        print("\n[X] Naver API 키가 설정되지 않았습니다. .env 파일을 확인하세요.")
        return
    
    print(f"\n[Geocoding 시작]")
    
    # CSV 읽기
    rows = []
    with open(input_file, 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        header = next(reader)
        rows = list(reader)
    
    print(f"  - 총 {len(rows)}개 레스토랑")
    
    # Geocoding 수행
    success_count = 0
    fail_count = 0
    
    for idx, row in enumerate(rows):
        restaurant_name = row[3]
        address = row[9]
        
        print(f"\n[{idx+1}/{len(rows)}] {restaurant_name}")
        print(f"  주소: {address}")
        
        # Geocoding
        lat, lng, success = geocode_address(address)
        
        if success:
            row[10] = lat  # 위도
            row[11] = lng  # 경도
            success_count += 1
            print(f"  [OK] 좌표: ({lat}, {lng})")
        else:
            fail_count += 1
        
        # API 요청 제한 방지 (초당 5회)
        time.sleep(0.2)
    
    # 결과 저장
    with open(output_file, 'w', encoding='utf-8', newline='') as f:
        writer = csv.writer(f, quoting=csv.QUOTE_ALL)
        writer.writerow(header)
        writer.writerows(rows)
    
    print(f"\n[완료] Geocoding 완료!")
    print(f"  - 성공: {success_count}개")
    print(f"  - 실패: {fail_count}개")
    print(f"  - 출력 파일: {output_file}")
    
    if fail_count > 0:
        print(f"\n[!] {fail_count}개 레스토랑의 좌표를 찾지 못했습니다.")
        print("  주소를 수정하거나 수동으로 좌표를 입력해야 합니다.")

if __name__ == "__main__":
    main()
