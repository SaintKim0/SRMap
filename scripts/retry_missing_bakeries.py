"""
천하제빵 CSV - 검색 안된 항목들을 네이버 지도 API로 재검색
"""
import os
import csv
import time
import requests
from dotenv import load_dotenv

load_dotenv()

NAVER_CLIENT_ID = os.getenv('NAVER_SEARCH_CLIENT_ID')
NAVER_CLIENT_SECRET = os.getenv('NAVER_SEARCH_CLIENT_SECRET')

def search_naver_local(query):
    """네이버 지역 검색 API"""
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
        return None
    except Exception as e:
        print(f"  [!] 요청 실패: {e}")
        return None

def search_with_variations(name, region):
    """다양한 검색어로 시도"""
    search_queries = [
        f"{name} {region}",
        f"{name} {region} 빵집",
        f"{name} {region} 베이커리",
        f"{name} 빵집",
        name
    ]
    
    for query in search_queries:
        print(f"  시도: {query}")
        result = search_naver_local(query)
        time.sleep(0.1)
        
        if result and result.get('items'):
            return result['items'][0]
    
    return None

def process_missing_items():
    """검색 안된 항목들 재처리"""
    print(f"\n{'='*60}")
    print(f"검색 안된 항목 재검색 시작")
    print(f"{'='*60}\n")
    
    input_file = "doc/data/천하제빵.csv"
    output_file = "doc/data/천하제빵_retry.csv"
    
    rows = []
    updated_count = 0
    
    with open(input_file, 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        header = next(reader)
        rows.append(header)
        
        for idx, row in enumerate(reader, start=1):
            if len(row) < 12:
                rows.append(row)
                continue
            
            name = row[3]
            address = row[9]
            lat = row[10] if len(row) > 10 else ""
            lon = row[11] if len(row) > 11 else ""
            
            # 좌표가 없는 항목만 재검색
            if not lat.strip() or not lon.strip():
                print(f"\n[{idx}] {name} - 재검색")
                
                # 지역 정보 추출
                region = address.split()[0] if address != "정보없음" else ""
                
                item = search_with_variations(name, region)
                
                if item:
                    # 주소 업데이트
                    new_address = item.get('roadAddress', item.get('address', ''))
                    if new_address and address == "정보없음":
                        row[9] = new_address
                        print(f"  ✓ 주소: {new_address}")
                    
                    # 좌표 추출
                    mapx = item.get('mapx', '')
                    mapy = item.get('mapy', '')
                    
                    if mapx and mapy:
                        try:
                            longitude = float(mapx) / 10000000
                            latitude = float(mapy) / 10000000
                            
                            while len(row) <= 11:
                                row.append('')
                            row[10] = str(latitude)
                            row[11] = str(longitude)
                            print(f"  ✓ 좌표: ({latitude}, {longitude})")
                            
                            # 전화번호
                            phone = item.get('telephone', '')
                            if phone:
                                while len(row) <= 12:
                                    row.append('')
                                if not row[12] or row[12] == "정보없음":
                                    row[12] = phone
                                    print(f"  ✓ 전화: {phone}")
                            
                            updated_count += 1
                        except (ValueError, TypeError) as e:
                            print(f"  [!] 좌표 변환 실패: {e}")
                else:
                    print(f"  [X] 검색 실패 - 수동 입력 필요")
            
            rows.append(row)
    
    # 저장
    with open(output_file, 'w', encoding='utf-8', newline='') as f:
        writer = csv.writer(f)
        writer.writerows(rows)
    
    print(f"\n{'='*60}")
    print(f"✓ 추가 업데이트: {updated_count}개")
    print(f"✓ 저장: {output_file}")
    print(f"{'='*60}\n")
    
    # 검증
    with open(output_file, 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        next(reader)
        total = sum(1 for _ in reader)
    
    with open(output_file, 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        next(reader)
        with_coords = sum(1 for row in reader if len(row) > 11 and row[10].strip() and row[11].strip())
    
    print(f"최종 결과: 총 {total}개 중 {with_coords}개 항목에 좌표 정보")
    print(f"남은 항목: {total - with_coords}개")

if __name__ == "__main__":
    process_missing_items()
