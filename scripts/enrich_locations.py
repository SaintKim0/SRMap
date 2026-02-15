import csv
import os
import requests
import json
import time
from dotenv import load_dotenv

# .env 파일 로드
load_dotenv()

CLIENT_ID = os.getenv('NAVER_SEARCH_CLIENT_ID')
CLIENT_SECRET = os.getenv('NAVER_SEARCH_CLIENT_SECRET')

INPUT_FILE = r'd:\00_projects\02_TasteMap\assets\data\locations.csv'
OUTPUT_FILE = r'd:\00_projects\02_TasteMap\assets\data\locations_enriched.csv'

def get_naver_info(name, address):
    url = "https://openapi.naver.com/v1/search/local.json"
    headers = {
        "X-Naver-Client-Id": CLIENT_ID,
        "X-Naver-Client-Secret": CLIENT_SECRET
    }
    
    # 상호명과 주소 일부를 조합하여 검색 정확도 향상
    # 주소에서 '시/도'와 '구/군' 정도만 사용
    addr_parts = address.split()
    query_addr = " ".join(addr_parts[:2]) if len(addr_parts) >= 2 else address
    query = f"{name} {query_addr}"
    
    params = {
        "query": query,
        "display": 1,
        "sort": "random"
    }
    
    try:
        response = requests.get(url, headers=headers, params=params)
        if response.status_code == 200:
            data = response.json()
            if data['items']:
                item = data['items'][0]
                category = item.get('category', '')
                
                # 카테고리에서 정보 추출 (예: "한식>순두부" -> category: "한식", menu: "순두부")
                food_category = ""
                representative_menu = ""
                
                if '>' in category:
                    parts = category.split('>')
                    food_category = parts[0].strip()
                    representative_menu = parts[1].strip()
                else:
                    food_category = category.strip()
                
                return food_category, representative_menu
        else:
            print(f"Error: {response.status_code} for {query}")
    except Exception as e:
        print(f"Exception for {query}: {e}")
    
    return "", ""

def main():
    if not CLIENT_ID or not CLIENT_SECRET:
        print("API keys not found in .env")
        return

    # 기존에 처리된 데이터가 있는지 확인
    processed_count = 0
    if os.path.exists(OUTPUT_FILE):
        with open(OUTPUT_FILE, 'r', encoding='utf-8') as f:
            reader = csv.reader(f)
            processed_count = sum(1 for row in reader) - 1 # 헤더 제외
            print(f"Resuming from item {processed_count + 1}...")

    with open(INPUT_FILE, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        fieldnames = reader.fieldnames + ['food_category', 'representative_menu']
        rows = list(reader)
        total = len(rows)
        
        print(f"Total rows: {total}")
        
        # 'a' (append) 모드로 열거나 처음부터 시작
        mode = 'a' if processed_count > 0 else 'w'
        with open(OUTPUT_FILE, mode, encoding='utf-8', newline='') as out_f:
            writer = csv.DictWriter(out_f, fieldnames=fieldnames)
            if mode == 'w':
                writer.writeheader()
            
            for i, row in enumerate(rows):
                # 이미 처리된 행은 건너뜀
                if i < processed_count:
                    continue
                    
                name = row['place_name']
                address = row['address']
                
                print(f"[{i+1}/{total}] Searching for {name}...")
                
                cat, menu = get_naver_info(name, address)
                row['food_category'] = cat
                row['representative_menu'] = menu
                
                writer.writerow(row)
                time.sleep(0.1)
                
                # 100개마다 저장 상황 출력
                if (i + 1) % 100 == 0:
                    print(f"--- Processed {i+1} items ---")

    print(f"Enrichment completed. Saved to {OUTPUT_FILE}")

if __name__ == "__main__":
    main()
