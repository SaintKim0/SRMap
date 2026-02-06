import csv
import requests
import time
import os
from dotenv import load_dotenv
from datetime import datetime

# .env 파일 로드
load_dotenv()

# Naver Map API 키
NAVER_CLIENT_ID = os.getenv('NAVER_MAP_CLIENT_ID') or os.getenv('NAVER_SEARCH_CLIENT_ID')
NAVER_CLIENT_SECRET = os.getenv('NAVER_MAP_CLIENT_SECRET') or os.getenv('NAVER_SEARCH_CLIENT_SECRET')

def geocode_address(address):
    """Naver Cloud Platform Geocoding API를 사용하여 주소를 위도/경도로 변환"""
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
        
        if response.status_code != 200:
            print(f"  [X] API 오류 ({response.status_code}): {address}")
            return '0.0', '0.0', False
        
        data = response.json()
        
        if data.get('status') == 'OK' and data.get('addresses'):
            result = data['addresses'][0]
            lat = result.get('y', '0.0')
            lng = result.get('x', '0.0')
            return lat, lng, True
        else:
            print(f"  [!] Geocoding 실패: {address}")
            return '0.0', '0.0', False
            
    except Exception as e:
        print(f"  [X] 예외 발생: {address} - {str(e)}")
        return '0.0', '0.0', False

def convert_black_white_data(season_num, input_file, start_id):
    """흑백요리사 데이터를 앱 형식으로 변환"""
    output_rows = []
    
    with open(input_file, 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        
        for idx, row in enumerate(reader):
            if len(row) < 14:
                continue
            
            # 컬럼: 0=연번, 1=show, 2=제목, 3=장소명, 4=타입, 5=쉐프명, 6-8=빈값, 9=주소, 10-11=좌표, 12=전화, 13=날짜
            restaurant_name = row[3].strip()
            chef_name = row[5].strip()
            address = row[9].strip()
            phone = row[12].strip() if row[12] else "정보없음"
            
            # 장소 설명 생성 (쉐프 이름 포함)
            description = f"흑백요리사 시즌{season_num} 참가. 쉐프: {chef_name}"
            
            # Geocoding
            print(f"\n[{idx+1}] {restaurant_name}")
            print(f"  주소: {address}")
            print(f"  쉐프: {chef_name}")
            
            lat, lng, success = geocode_address(address)
            
            if success:
                print(f"  [OK] 좌표: ({lat}, {lng})")
            else:
                print(f"  [!] 좌표 실패 - 0.0으로 설정")
            
            # CSV 행 생성
            output_row = [
                str(start_id + idx),                    # 연번
                "show",                                  # 미디어타입
                f"흑백요리사 시즌{season_num}",          # 제목
                restaurant_name,                         # 장소명
                "restaurant",                            # 장소타입
                description,                             # 장소설명 (쉐프 포함)
                "정보없음",                              # 영업시간
                "정보없음",                              # 브레이크타임
                "정보없음",                              # 휴무일
                address,                                 # 주소
                lat,                                     # 위도
                lng,                                     # 경도
                phone,                                   # 전화번호
                datetime.now().strftime("%Y-%m-%d")     # 최종작성일
            ]
            
            output_rows.append(output_row)
            
            # API 제한 방지
            time.sleep(0.2)
    
    return output_rows

def main():
    print("[흑백요리사 데이터 변환 및 Geocoding]")
    print(f"Naver API: {NAVER_CLIENT_ID[:10]}..." if NAVER_CLIENT_ID else "[X] API 키 없음")
    
    if not NAVER_CLIENT_ID or not NAVER_CLIENT_SECRET:
        print("\n[X] Naver API 키가 설정되지 않았습니다.")
        return
    
    all_rows = []
    
    # 시즌1 변환
    print("\n=== 흑백요리사 시즌1 처리 ===")
    season1_file = 'd:/00_projects/01_ScreenMap_Backup/doc/black_white_season1.csv'
    season1_rows = convert_black_white_data(1, season1_file, 16000)
    all_rows.extend(season1_rows)
    print(f"\n시즌1 완료: {len(season1_rows)}개")
    
    # 시즌2 변환
    print("\n=== 흑백요리사 시즌2 처리 ===")
    season2_file = 'd:/00_projects/01_ScreenMap_Backup/doc/black_white_season2.csv'
    season2_rows = convert_black_white_data(2, season2_file, 16000 + len(season1_rows))
    all_rows.extend(season2_rows)
    print(f"\n시즌2 완료: {len(season2_rows)}개")
    
    # 결과 저장
    output_file = 'd:/00_projects/01_ScreenMap_Backup/doc/black_white_geocoded.csv'
    with open(output_file, 'w', encoding='utf-8', newline='') as f:
        writer = csv.writer(f, quoting=csv.QUOTE_ALL)
        
        # 헤더
        header = ["연번", "미디어타입", "제목", "장소명", "장소타입", "장소설명", 
                  "영업시간", "브레이크타임", "휴무일", "주소", "위도", "경도", "전화번호", "최종작성일"]
        writer.writerow(header)
        writer.writerows(all_rows)
    
    print(f"\n[완료] 전체 변환 완료!")
    print(f"  - 총 레스토랑: {len(all_rows)}개")
    print(f"  - 출력 파일: {output_file}")

if __name__ == "__main__":
    main()
