import csv
import requests
import time
import os
import re
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
    params = {"query": query, "display": 3}
    try:
        response = requests.get(url, headers=headers, params=params)
        if response.status_code == 200:
            return response.json().get('items', [])
    except Exception:
        pass
    return []

def search_web(query):
    """Naver Web Search API를 사용하여 장소 정보 검색"""
    url = "https://openapi.naver.com/v1/search/webkr.json"
    headers = {
        "X-Naver-Client-Id": NAVER_SEARCH_CLIENT_ID,
        "X-Naver-Client-Secret": NAVER_SEARCH_CLIENT_SECRET
    }
    params = {"query": query, "display": 5}
    try:
        response = requests.get(url, headers=headers, params=params)
        if response.status_code == 200:
            return response.json().get('items', [])
    except Exception:
        pass
    return []

def geocode_address(address):
    """Naver Maps Geocoding API를 사용하여 주소를 위도/경도로 변환"""
    url = "https://maps.apigw.ntruss.com/map-geocode/v2/geocode"
    headers = {
        "x-ncp-apigw-api-key-id": NAVER_MAP_CLIENT_ID,
        "x-ncp-apigw-api-key": NAVER_MAP_CLIENT_SECRET,
        "Accept": "application/json"
    }
    params = {"query": address}
    try:
        response = requests.get(url, headers=headers, params=params)
        if response.status_code == 200:
            data = response.json()
            if data.get('status') == 'OK' and data.get('addresses'):
                result = data['addresses'][0]
                return result.get('y', ''), result.get('x', ''), True
    except Exception:
        pass
    return '', '', False

def clean_html_tags(text):
    if not text: return ''
    return text.replace('<b>', '').replace('</b>', '').strip()

def extract_phone_from_snippet(snippet):
    # 전화번호 패턴: 02-123-4567, 031-123-4567, 010-1234-5678, 054) 123-4567 등
    phone_pattern = r'\d{2,3}[-\)]\s?\d{3,4}[-]\s?\d{4}'
    match = re.search(phone_pattern, snippet)
    if match:
        return match.group().replace(')', '-')
    return None

def extract_hours_from_snippet(snippet):
    # 영업시간 패턴: 10:00~21:00, 10시-17시 등 상세 보완용
    # 여기서는 간단히 키워드 기반으로 존재 여부 확인 후 스니펫 일부 반환을 고려할 수 있으나
    # 데이터 구조가 복잡하므로 특정 패턴 매칭 시도
    hours_pattern = r'(\d{1,2}:\d{2})\s?~?\s?(\d{1,2}:\d{2})'
    match = re.search(hours_pattern, snippet)
    if match:
        return f"{match.group(1)} - {match.group(2)}"
    return None

def enhance_row(row):
    # CSV 구조: 0:no, 1:media_type, 2:title, 3:place_name, 4:place_type, 5:description, 6:opening_hours, 7:break_time, 8:closed_days, 9:address, 10:latitude, 11:longitude, 12:phone
    place_name = row[3]
    opening_hours = row[6]
    break_time = row[7]
    closed_days = row[8]
    address = row[9]
    phone = row[12]
    
    query = place_name
    if address:
        area_parts = address.split()
        if area_parts:
            query = f"{area_parts[0]} {place_name}"
    
    # 1. Local Search API
    local_items = search_place(query)
    if local_items:
        match = local_items[0]
        new_address = clean_html_tags(match.get('roadAddress', match.get('address', '')))
        new_phone = match.get('telephone', '')
        
        if new_address and (not address or len(new_address) > len(address) or address == '정보없음'):
            row[9] = new_address
            address = new_address
        if new_phone and (not phone or phone == '정보없음'):
            row[12] = new_phone
            phone = new_phone

    # 2. Web Search API (Supplement missing text fields)
    if any(row[i] == '정보없음' for i in [6, 7, 8, 12]) or not phone:
        web_items = search_web(query + " 영업시간 전화번호 휴무")
        for item in web_items:
            description = clean_html_tags(item.get('description', ''))
            
            # 전화번호 보완
            if (not row[12] or row[12] == '정보없음'):
                p = extract_phone_from_snippet(description)
                if p:
                    row[12] = p
                    print(f"      [WEB] Phone found: {p}")
            
            # 영업시간 보완 (단순 패턴 매칭)
            if (not row[6] or row[6] == '정보없음'):
                h = extract_hours_from_snippet(description)
                if h:
                    row[6] = h
                    print(f"      [WEB] Hours found: {h}")
            
            # 휴무일 보완 (키워드 매칭 - "매주X요일 휴무", "일요일 휴무" 등)
            if (not row[8] or row[8] == '정보없음'):
                match_holiday = re.search(r'([월화수목금토일]요일)\s?(?:정기)?\s?휴무', description)
                if match_holiday:
                    row[8] = f"매주 {match_holiday.group(1)}"
                    print(f"      [WEB] Holiday found: {row[8]}")
    
    # 3. Geocoding (항상 최신 주소 기준)
    if address and address != '정보없음' and (not row[10] or not row[11]):
        lat, lng, success = geocode_address(address)
        if success:
            row[10] = lat
            row[11] = lng
            
    return row

def main():
    base_path = 'd:/00_projects/02_TasteMap/doc/data/'
    input_file = base_path + '전현무계획 3_geocoded.csv'
    output_file = base_path + '전현무계획 3_geocoded.csv'
    
    with open(input_file, 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        header = next(reader)
        rows = list(reader)
    
    print(f"Supplementing missing info for {len(rows)} entries...")
    
    processed_rows = []
    for i, row in enumerate(rows):
        print(f"[{i+1}/{len(rows)}] {row[3]}")
        processed_row = enhance_row(row)
        processed_rows.append(processed_row)
        time.sleep(0.2)

    with open(output_file, 'w', encoding='utf-8', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(header)
        writer.writerows(processed_rows)

    print("\nSuccess! Missing info supplemented using Web Search API.")

if __name__ == "__main__":
    main()
