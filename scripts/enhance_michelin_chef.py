import csv
import os
import requests
import re
import time
from dotenv import load_dotenv

load_dotenv()

# API Keys
NAVER_CLIENT_ID = os.getenv('NAVER_SEARCH_CLIENT_ID')
NAVER_CLIENT_SECRET = os.getenv('NAVER_SEARCH_CLIENT_SECRET')

def search_web(query):
    url = "https://openapi.naver.com/v1/search/webkr.json"
    headers = {
        "X-Naver-Client-Id": NAVER_CLIENT_ID,
        "X-Naver-Client-Secret": NAVER_CLIENT_SECRET
    }
    params = {"query": query, "display": 5}
    response = requests.get(url, headers=headers, params=params)
    if response.status_code == 200:
        return response.json().get('items', [])
    return []

def clean_html_tags(text):
    return re.sub(r'<[^>]*>', '', text)

def extract_chef_from_snippet(snippet, restaurant_name):
    # Patterns to match chef names in Korean
    chef_patterns = [
        r'([가-힣]{2,4})\s?셰프',
        r'오너\s?셰프\s?([가-힣]{2,4})',
        r'([가-힣]{2,4})\s?오너\s?셰프',
        r'([가-힣]{2,4})\s?총괄\s?셰프',
        r'([가-힣]{2,4})\s?헤드\s?셰프'
    ]
    
    black_list = {
        "오너", "현장", "경우", "모습", "한식을", "덕분에", "됩니다", "부부", 
        "청와대", "핵심은", "스타", "유명", "명의", "지닌", "수련한", 
        "어우러져", "앉아서", "명장", "출신", "위한", "키토리는", "리보다는",
        "되어", "있는", "곳으로", "대해", "주목", "한층", "함께", "나온",
        "들어", "통해", "정보없음", "null", "레스토랑", "신라호텔",
        "오마카세", "마카세는", "벽면에는", "들어선", "들어서면", "요리마다",
        "트렌디", "렌디함과", "쌓은", "이블에서", "베이스는", "꼽으라면", 
        "총괄", "세계적인", "아마도", "대표적", "위치한", "주방장", "헤드",
        "이상의", "제공하", "경력을", "선보이", "하나인", "요리를", "공간",
        "셰프가", "셰프의", "셰프는", "셰프를", "셰프와",
        "프렌치", "젊은", "근무하던", "좌석이", "최고", "매진하는", "이름난", 
        "추구하는", "이다보니", "모색하는", "있던데요", "저분이", "바라보면", 
        "메인", "꼬기", "세리님의", "알고보니", "일식", "보니", "개방되어", 
        "두분", "풍미와", "손질하는", "쓰는", "한식에서", "있어", "공간에서", 
        "앞에", "미국인", "보유한", "젋은"
    }
    
    for pattern in chef_patterns:
        match = re.search(pattern, snippet)
        if match:
            found_name = match.group(1).strip()
            # Strict validation
            if (found_name not in restaurant_name and 
                found_name not in black_list and
                len(found_name) >= 2 and len(found_name) <= 5 and
                re.match(r'^[가-힣]+$', found_name)):
                return found_name
    return None

def main():
    csv_path = 'assets/data/locations.csv'
    output_path = 'assets/data/locations_michelin_enhanced.csv'
    
    with open(csv_path, 'r', encoding='utf-8-sig') as f:
        reader = csv.reader(f)
        header = next(reader)
        rows = list(reader)

    print(f"Loaded {len(rows)} locations.")
    
    # Michelin 2025 rows filter
    # 1: media_type, 2: title, 3: place_name, 9: address
    target_count = 0
    enhanced_count = 0
    
    for i, row in enumerate(rows):
        media_type = row[1]
        title = row[2]
        place_name = row[3]
        description = row[5]
        address = row[9]
        
        if media_type == 'guide' and '2025' in title:
            target_count += 1
            # Only search if chef info is missing or generic
            if '레스토랑' in description or not description or description == '정보없음':
                print(f"[{target_count}] Searching for chef of {place_name}...")
                
                query = f"{place_name} {address.split()[0] if address else ''} 셰프"
                items = search_web(query)
                
                chef_name = None
                for item in items:
                    snippet = clean_html_tags(item.get('description', ''))
                    chef_name = extract_chef_from_snippet(snippet, place_name)
                    if chef_name:
                        break
                
                if chef_name:
                    print(f"  --> Found Chef: {chef_name}")
                    row[5] = f"{chef_name}" # Store name in description col (index 5)
                    enhanced_count += 1
                else:
                    # Try a broader search if not found
                    query_alt = f"{place_name} 오너셰프"
                    items_alt = search_web(query_alt)
                    for item in items_alt:
                        snippet = clean_html_tags(item.get('description', ''))
                        chef_name = extract_chef_from_snippet(snippet, place_name)
                        if chef_name:
                            print(f"  --> Found Chef (Alt Search): {chef_name}")
                            row[5] = f"{chef_name}"
                            enhanced_count += 1
                            break
                
                # Sleep to respect API limits if needed (Naver is quite generous but let's be safe)
                time.sleep(0.2)

    print(f"Finished. Target: {target_count}, Enhanced: {enhanced_count}")
    
    # Save back to CSV (Overwriting or saving to new file first for safety)
    with open(csv_path, 'w', encoding='utf-8-sig', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(header)
        writer.writerows(rows)
    print(f"Updated {csv_path}")

if __name__ == "__main__":
    main()
