"""
천하제빵 CSV 파일의 누락된 정보를 네이버 검색 API와 네이버 지도 API로 보완하는 스크립트
"""
import os
import csv
import time
import requests
from dotenv import load_dotenv

load_dotenv()

NAVER_CLIENT_ID = os.getenv('NAVER_SEARCH_CLIENT_ID')
NAVER_CLIENT_SECRET = os.getenv('NAVER_SEARCH_CLIENT_SECRET')
NAVER_MAP_CLIENT_ID = os.getenv('NAVER_MAP_CLIENT_ID')
NAVER_MAP_CLIENT_SECRET = os.getenv('NAVER_MAP_CLIENT_SECRET')

def search_naver_local(query):
    """네이버 지역 검색 API로 장소 정보 검색"""
    url = "https://openapi.naver.com/v1/search/local.json"
    headers = {
        "X-Naver-Client-Id": NAVER_CLIENT_ID,
        "X-Naver-Client-Secret": NAVER_CLIENT_SECRET
    }
    params = {
        "query": query,
        "display": 5,
        "start": 1,
        "sort": "random"
    }
    
    try:
        response = requests.get(url, headers=headers, params=params)
        if response.status_code == 200:
            return response.json()
        else:
            print(f"  [!] API 오류: {response.status_code}")
            return None
    except Exception as e:
        print(f"  [!] 요청 실패: {e}")
        return None

def geocode_address(address):
    """네이버 지오코딩 API로 주소를 좌표로 변환"""
    url = "https://naveropenapi.apigw.ntruss.com/map-geocode/v2/geocode"
    headers = {
        "x-ncp-apigw-api-key-id": NAVER_MAP_CLIENT_ID,
        "x-ncp-apigw-api-key": NAVER_MAP_CLIENT_SECRET
    }
    params = {"query": address}
    
    try:
        response = requests.get(url, headers=headers, params=params)
        if response.status_code == 200:
            data = response.json()
            if data.get('addresses') and len(data['addresses']) > 0:
                addr = data['addresses'][0]
                return {
                    'latitude': addr.get('y'),
                    'longitude': addr.get('x'),
                    'roadAddress': addr.get('roadAddress', ''),
                    'jibunAddress': addr.get('jibunAddress', '')
                }
        return None
    except Exception as e:
        print(f"  [!] 지오코딩 실패: {e}")
        return None

def enhance_bakery_info(name, current_address):
    """빵집 정보 보완"""
    print(f"\n🔍 검색 중: {name}")
    
    # 지역 정보 추출
    region = current_address.split()[0] if current_address != "정보없음" else ""
    search_query = f"{name} {region} 빵집" if region else f"{name} 빵집"
    
    result = search_naver_local(search_query)
    time.sleep(0.1)  # API 호출 제한 방지
    
    if not result or not result.get('items'):
        print(f"  [X] 검색 결과 없음")
        return None
    
    # 가장 관련성 높은 결과 선택
    item = result['items'][0]
    
    info = {
        'name': item.get('title', '').replace('<b>', '').replace('</b>', ''),
        'address': item.get('roadAddress', item.get('address', '')),
        'phone': item.get('telephone', ''),
        'category': item.get('category', '')
    }
    
    # 네이버 좌표를 WGS84로 변환
    # mapx, mapy는 네이버 좌표계 (KATEC)
    # 간단한 변환: mapx/mapy를 10^7로 나누면 대략적인 경도/위도
    mapx = item.get('mapx', '')
    mapy = item.get('mapy', '')
    
    if mapx and mapy:
        try:
            # 네이버 좌표를 WGS84로 변환
            longitude = float(mapx) / 10000000
            latitude = float(mapy) / 10000000
            info['latitude'] = latitude
            info['longitude'] = longitude
            print(f"  ✓ 좌표: ({latitude}, {longitude})")
        except (ValueError, TypeError) as e:
            print(f"  [!] 좌표 변환 실패: {e}")
    
    print(f"  ✓ 주소: {info.get('address', '없음')}")
    print(f"  ✓ 전화: {info.get('phone', '없음')}")
    
    return info

def process_csv(input_file, output_file):
    """CSV 파일 처리"""
    print(f"\n{'='*60}")
    print(f"천하제빵 데이터 보완 시작")
    print(f"{'='*60}")
    
    if not NAVER_CLIENT_ID or not NAVER_CLIENT_SECRET:
        print("\n[!] 네이버 검색 API 키가 설정되지 않았습니다.")
        print("    .env 파일에 NAVER_SEARCH_CLIENT_ID와 NAVER_SEARCH_CLIENT_SECRET을 설정하세요.")
        return
    
    if not NAVER_MAP_CLIENT_ID or not NAVER_MAP_CLIENT_SECRET:
        print("\n[!] 네이버 지도 API 키가 설정되지 않았습니다.")
        print("    .env 파일에 NAVER_MAP_CLIENT_ID와 NAVER_MAP_CLIENT_SECRET을 설정하세요.")
        return
    
    rows = []
    updated_count = 0
    
    with open(input_file, 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        header = next(reader)
        rows.append(header)
        
        print(f"\n헤더: {header[:13]}")  # 처음 13개 컬럼만 출력
        
        for idx, row in enumerate(reader, start=1):
            if len(row) < 11:
                rows.append(row)
                continue
            
            # 컬럼: no, media_type, title, place_name, place_type, description, 
            #       opening_hours, break_time, closed_days, address, latitude, longitude, phone...
            name = row[3]
            address = row[9]
            lat = row[10] if len(row) > 10 else ""
            lon = row[11] if len(row) > 11 else ""
            
            # 정보가 부족한 경우에만 API 호출
            needs_update = (address == "정보없음" or not lat.strip() or not lon.strip())
            
            if needs_update:
                print(f"\n[{idx}] {name} - 업데이트 필요")
                print(f"    현재 주소: {address}")
                print(f"    현재 좌표: ({lat}, {lon})")
                
                enhanced = enhance_bakery_info(name, address)
                
                if enhanced:
                    # 주소 업데이트
                    if address == "정보없음" and enhanced.get('address'):
                        row[9] = enhanced['address']
                        print(f"    → 주소 업데이트: {enhanced['address']}")
                    
                    # 좌표 업데이트
                    if enhanced.get('latitude'):
                        # row 길이 확인 및 확장
                        while len(row) <= 11:
                            row.append('')
                        row[10] = str(enhanced['latitude'])
                        row[11] = str(enhanced['longitude'])
                        print(f"    → 좌표 업데이트: ({enhanced['latitude']}, {enhanced['longitude']})")
                    
                    # 전화번호 업데이트
                    while len(row) <= 12:
                        row.append('')
                    if not row[12] or row[12] == "정보없음":
                        if enhanced.get('phone'):
                            row[12] = enhanced['phone']
                            print(f"    → 전화 업데이트: {enhanced['phone']}")
                    
                    updated_count += 1
                    print(f"    ✓ 업데이트 완료")
                else:
                    print(f"    - 정보 없음, 원본 유지")
            else:
                print(f"[{idx}] {name} - 스킵 (정보 충분)")
            
            rows.append(row)
    
    # 결과 저장
    print(f"\n파일 저장 중: {output_file}")
    with open(output_file, 'w', encoding='utf-8', newline='') as f:
        writer = csv.writer(f)
        writer.writerows(rows)
    
    print(f"\n{'='*60}")
    print(f"✓ 완료: {updated_count}개 항목 업데이트")
    print(f"✓ 저장: {output_file}")
    print(f"{'='*60}\n")
    
    # 검증
    print("파일 검증 중...")
    with open(output_file, 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        next(reader)  # 헤더 스킵
        count_with_coords = sum(1 for row in reader if len(row) > 11 and row[10].strip() and row[11].strip())
    print(f"좌표 정보가 있는 항목: {count_with_coords}개")

if __name__ == "__main__":
    input_file = "doc/data/천하제빵.csv"
    output_file = "doc/data/천하제빵_enhanced.csv"
    
    process_csv(input_file, output_file)

