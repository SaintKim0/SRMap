import csv
import requests
import time
import os
from dotenv import load_dotenv
from io import StringIO

# .env 파일 로드
load_dotenv()

# Naver API 키
NAVER_SEARCH_CLIENT_ID = os.getenv('NAVER_SEARCH_CLIENT_ID')
NAVER_SEARCH_CLIENT_SECRET = os.getenv('NAVER_SEARCH_CLIENT_SECRET')
NAVER_MAP_CLIENT_ID = os.getenv('NAVER_MAP_CLIENT_ID') or NAVER_SEARCH_CLIENT_ID
NAVER_MAP_CLIENT_SECRET = os.getenv('NAVER_MAP_CLIENT_SECRET') or NAVER_SEARCH_CLIENT_SECRET

def search_place(query):
    """Naver Local Search API를 사용하여 장소 정보 검색"""
    url = "https://openapi.naver.com/v1/search/local.json"
    
    headers = {
        "X-Naver-Client-Id": NAVER_SEARCH_CLIENT_ID,
        "X-Naver-Client-Secret": NAVER_SEARCH_CLIENT_SECRET
    }
    
    params = {
        "query": query,
        "display": 5  # 상위 5개 결과 가져오기
    }
    
    try:
        response = requests.get(url, headers=headers, params=params)
        
        if response.status_code != 200:
            print(f"  [X] Search API 오류 ({response.status_code})")
            return None
        
        data = response.json()
        
        if data.get('items'):
            return data['items']
        else:
            return None
            
    except Exception as e:
        print(f"  [X] 검색 예외 발생: {str(e)}")
        return None

def geocode_address(address):
    """Naver Maps Geocoding API를 사용하여 주소를 위도/경도로 변환"""
    url = "https://maps.apigw.ntruss.com/map-geocode/v2/geocode"
    
    headers = {
        "x-ncp-apigw-api-key-id": NAVER_MAP_CLIENT_ID,
        "x-ncp-apigw-api-key": NAVER_MAP_CLIENT_SECRET,
        "Accept": "application/json"
    }
    
    params = {
        "query": address
    }
    
    try:
        response = requests.get(url, headers=headers, params=params)
        
        if response.status_code != 200:
            return '', '', False
        
        data = response.json()
        
        if data.get('status') == 'OK' and data.get('addresses'):
            result = data['addresses'][0]
            lat = result.get('y', '')
            lng = result.get('x', '')
            return lat, lng, True
        else:
            return '', '', False
            
    except Exception as e:
        return '', '', False

def convert_katech_to_wgs84(mapx, mapy):
    """KATECH/TM128 좌표를 WGS84로 변환"""
    try:
        from pyproj import Proj, Transformer
        
        # KATECH (TM128) 좌표계
        proj_katech = Proj('+proj=tmerc +lat_0=38 +lon_0=128 +k=0.9999 +x_0=400000 +y_0=600000 +ellps=bessel +units=m +no_defs +towgs84=-115.80,474.99,674.11,1.16,-2.31,-1.63,6.43')
        # WGS84 좌표계
        proj_wgs84 = Proj(proj='latlong', datum='WGS84')
        
        transformer = Transformer.from_proj(proj_katech, proj_wgs84)
        
        mx = float(mapx)
        my = float(mapy)
        
        lon, lat = transformer.transform(mx, my)
        return str(lat), str(lon)
    except Exception as e:
        print(f"  [!] 좌표 변환 실패: {str(e)}")
        return '', ''

def clean_html_tags(text):
    """HTML 태그 제거"""
    if not text:
        return ''
    return text.replace('<b>', '').replace('</b>', '').strip()

def enhance_address(place_name, partial_address, phone):
    """레스토랑 정보를 검색하여 완전한 주소와 좌표 반환"""
    
    # 검색 쿼리 생성
    if partial_address and partial_address.strip():
        # 부분 주소에서 지역 정보 추출 (첫 단어 또는 시/구 정보)
        parts = partial_address.split()
        area = parts[0] if parts else ''
        query = f"{area} {place_name}"
    else:
        query = place_name
    
    print(f"  검색 쿼리: {query}")
    
    # Local Search API로 검색
    items = search_place(query)
    
    if not items:
        print(f"  [!] 검색 결과 없음")
        return None, None, None, None
    
    # 첫 번째 결과 사용 (가장 관련성 높은 결과)
    best_match = items[0]
    
    # 정보 추출
    title = clean_html_tags(best_match.get('title', ''))
    address = clean_html_tags(best_match.get('address', ''))
    road_address = clean_html_tags(best_match.get('roadAddress', ''))
    telephone = best_match.get('telephone', '')
    
    # 도로명 주소 우선, 없으면 지번 주소
    final_address = road_address if road_address else address
    
    # 전화번호 (기존 전화번호가 없을 때만 업데이트)
    final_phone = telephone if telephone and not phone else phone
    
    # Geocoding API 사용하여 정확한 WGS84 좌표 획득
    lat, lng = '', ''
    if final_address:
        print(f"  [OK] 검색 성공: {final_address}")
        lat, lng, success = geocode_address(final_address)
        if success:
            print(f"      좌표: ({lat}, {lng})")
            return final_address, lat, lng, final_phone
        else:
            print(f"  [!] Geocoding 실패")
            return final_address, '', '', final_phone
    
    print(f"  [!] 주소를 찾을 수 없습니다.")
    return None, '', '', final_phone

def main():
    input_file = 'd:/00_projects/02_TasteMap/doc/data/전현무계획.csv'
    output_file = 'd:/00_projects/02_TasteMap/doc/data/전현무계획_enhanced.csv'
    
    print(f"[Naver API 설정 확인]")
    print(f"  - Search Client ID: {NAVER_SEARCH_CLIENT_ID[:10]}..." if NAVER_SEARCH_CLIENT_ID else "  [X] Search Client ID 없음")
    print(f"  - Map Client ID: {NAVER_MAP_CLIENT_ID[:10]}..." if NAVER_MAP_CLIENT_ID else "  [X] Map Client ID 없음")
    
    if not NAVER_SEARCH_CLIENT_ID or not NAVER_SEARCH_CLIENT_SECRET:
        print("\n[X] Naver Search API 키가 설정되지 않았습니다. .env 파일을 확인하세요.")
        return
    
    if not NAVER_MAP_CLIENT_ID or not NAVER_MAP_CLIENT_SECRET:
        print("\n[X] Naver Map API 키가 설정되지 않았습니다. .env 파일을 확인하세요.")
        return
    
    print(f"\n[주소 보완 시작]")
    
    # CSV 읽기 - 헤더 라인 찾기
    with open(input_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    # 실제 CSV 헤더 찾기
    header_line_idx = None
    for idx, line in enumerate(lines):
        if line.startswith('no,media_type,title'):
            header_line_idx = idx
            break
    
    if header_line_idx is None:
        print("[X] CSV 헤더를 찾을 수 없습니다.")
        return
    
    # 헤더와 데이터 분리
    preamble = lines[:header_line_idx]
    csv_content = lines[header_line_idx:]
    
    # CSV 파싱
    csv_text = ''.join(csv_content)
    reader = csv.reader(StringIO(csv_text))
    header = next(reader)
    rows = list(reader)
    
    print(f"  - 총 {len(rows)}개 레스토랑")
    
    # 주소 보완 수행
    success_count = 0
    fail_count = 0
    skip_count = 0
    
    for idx, row in enumerate(rows):
        # CSV 구조: no,media_type,title,place_name,place_type,description,opening_hours,break_time,closed_days,address,latitude,longitude,phone,last_updated,michelin_tier
        # 인덱스:     0   1          2     3          4           5            6             7          8           9       10        11         12    13            14
        place_name = row[3] if len(row) > 3 else ''
        address = row[10] if len(row) > 10 else ''
        current_lat = row[11] if len(row) > 11 else ''
        current_lng = row[12] if len(row) > 12 else ''
        phone = row[13] if len(row) > 13 else ''
        
        print(f"\n[{idx+1}/{len(rows)}] {place_name}")
        print(f"  현재 주소: {address if address else '(없음)'}")
        print(f"  현재 좌표: ({current_lat}, {current_lng})" if current_lat and current_lng else "  현재 좌표: (없음)")
        
        # 이미 좌표가 있으면 스킵
        if current_lat and current_lng:
            print(f"  [SKIP] 이미 좌표가 있습니다.")
            skip_count += 1
            continue
        
        # 주소 보완 시도
        enhanced_address, lat, lng, enhanced_phone = enhance_address(place_name, address, phone)
        
        if enhanced_address or (lat and lng):
            # 행 길이 확인 및 확장
            while len(row) < 15:
                row.append('')
            
            # 주소 업데이트 (더 완전한 주소가 있으면)
            if enhanced_address and (not address or len(enhanced_address) > len(address)):
                row[10] = enhanced_address
                print(f"  [UPDATE] 주소: {enhanced_address}")
            
            # 좌표 업데이트
            if lat and lng:
                row[11] = lat
                row[12] = lng
                success_count += 1
                print(f"  [UPDATE] 좌표: ({lat}, {lng})")
            else:
                fail_count += 1
            
            # 전화번호 업데이트 (기존에 없었으면)
            if enhanced_phone and not phone:
                row[13] = enhanced_phone
                print(f"  [UPDATE] 전화번호: {enhanced_phone}")
        else:
            fail_count += 1
            print(f"  [FAIL] 정보를 찾을 수 없습니다.")
        
        # API 요청 제한 방지
        time.sleep(0.15)
    
    # 결과 저장
    with open(output_file, 'w', encoding='utf-8', newline='') as f:
        # 원본 preamble 유지
        for line in preamble:
            f.write(line)
        
        # CSV 데이터 작성
        writer = csv.writer(f)
        writer.writerow(header)
        writer.writerows(rows)
    
    print(f"\n[완료] 주소 보완 완료!")
    print(f"  - 성공: {success_count}개")
    print(f"  - 실패: {fail_count}개")
    print(f"  - 스킵: {skip_count}개 (이미 좌표 있음)")
    print(f"  - 출력 파일: {output_file}")
    
    if fail_count > 0:
        print(f"\n[!] {fail_count}개 레스토랑의 정보를 찾지 못했습니다.")
        print("  레스토랑이 폐업했거나 이름이 변경되었을 수 있습니다.")

if __name__ == "__main__":
    main()
