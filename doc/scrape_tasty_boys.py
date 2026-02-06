import requests
from bs4 import BeautifulSoup
import json
import csv
import time
from datetime import datetime
import re

def scrape_diningcode_tasty_boys():
    """다이닝코드에서 '맛있는녀석들' 식당 데이터 수집"""
    
    base_url = "https://www.diningcode.com/list.dc"
    all_restaurants = []
    
    # 경기도 맛있는녀석들 검색
    params = {
        'query': '경기도 맛있는녀석들'
    }
    
    print("다이닝코드에서 '맛있는녀석들' 데이터 수집 시작...")
    
    # 페이지네이션 처리 (총 122개, 페이지당 20개)
    total_pages = 7  # 122개 / 20 = 약 7페이지
    
    for page in range(total_pages):
        from_index = page * 20
        params_with_page = params.copy()
        params_with_page['from'] = from_index
        params_with_page['size'] = 20
        
        print(f"\n페이지 {page + 1}/{total_pages} 수집 중... (from: {from_index})")
        
        try:
            # 요청 헤더 설정
            headers = {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
                'Accept-Language': 'ko-KR,ko;q=0.9,en-US;q=0.8,en;q=0.7',
            }
            
            response = requests.get(base_url, params=params_with_page, headers=headers, timeout=30)
            response.raise_for_status()
            
            # HTML 파싱
            soup = BeautifulSoup(response.text, 'html.parser')
            
            # JavaScript에서 listData 추출
            scripts = soup.find_all('script')
            list_data = None
            
            for script in scripts:
                if script.string and 'localStorage.setItem' in script.string and 'listData' in script.string:
                    # listData JSON 추출
                    match = re.search(r"localStorage\.setItem\('listData',\s*'(.+?)'\);", script.string, re.DOTALL)
                    if match:
                        json_str = match.group(1)
                        # 이스케이프 문자 처리
                        json_str = json_str.replace('\\\\', '\\')
                        json_str = json_str.replace("\\'", "'")
                        
                        try:
                            list_data = json.loads(json_str)
                            break
                        except json.JSONDecodeError as e:
                            print(f"JSON 파싱 오류: {e}")
                            continue
            
            if list_data and 'poi_section' in list_data and 'list' in list_data['poi_section']:
                restaurants = list_data['poi_section']['list']
                print(f"  → {len(restaurants)}개 식당 발견")
                
                for restaurant in restaurants:
                    # 맛있는녀석들 키워드가 있는지 확인
                    has_tasty_boys = False
                    if 'keyword' in restaurant:
                        for kw in restaurant['keyword']:
                            if kw.get('term') == '맛있는녀석들' and kw.get('mark') == 1:
                                has_tasty_boys = True
                                break
                    
                    if has_tasty_boys:
                        # 데이터 추출
                        name = restaurant.get('nm', '')
                        branch = restaurant.get('branch', '')
                        if branch:
                            name = f"{name} {branch}"
                        
                        address = restaurant.get('road_addr', '') or restaurant.get('addr', '')
                        category = restaurant.get('category', '')
                        
                        restaurant_data = {
                            'name': name,
                            'address': address,
                            'category': category,
                            'phone': restaurant.get('phone', ''),
                            'lat': restaurant.get('lat', 0.0),
                            'lng': restaurant.get('lng', 0.0),
                            'score': restaurant.get('score', 0),
                            'user_score': restaurant.get('user_score', 0.0),
                            'review_cnt': restaurant.get('review_cnt', 0),
                            'area': ', '.join(restaurant.get('area', [])),
                        }
                        
                        all_restaurants.append(restaurant_data)
                        print(f"    ✓ {name} ({address[:30]}...)")
            else:
                print(f"  ⚠ 데이터를 찾을 수 없습니다.")
            
            # 요청 간 딜레이
            time.sleep(2)
            
        except Exception as e:
            print(f"  ✗ 오류 발생: {e}")
            continue
    
    return all_restaurants


def save_to_csv(restaurants, filename='tasty_boys.csv'):
    """CSV 파일로 저장 (black_white_season1.csv 형식에 맞춤)"""
    
    current_date = datetime.now().strftime('%Y-%m-%d')
    
    with open(filename, 'w', newline='', encoding='utf-8') as csvfile:
        writer = csv.writer(csvfile, quoting=csv.QUOTE_ALL)
        
        for idx, restaurant in enumerate(restaurants):
            row = [
                "0",  # id
                "show",  # sector
                "맛있는녀석들",  # title
                restaurant['name'],  # name
                "restaurant",  # type
                "",  # chef (빈 값)
                "",  # 빈 필드
                "",  # 빈 필드
                "",  # 빈 필드
                restaurant['address'],  # address
                str(restaurant['lat']),  # latitude
                str(restaurant['lng']),  # longitude
                "",  # 빈 필드
                current_date  # date
            ]
            writer.writerow(row)
    
    print(f"\n✅ {len(restaurants)}개 식당 데이터를 '{filename}' 파일로 저장했습니다.")


def main():
    print("=" * 60)
    print("다이닝코드 '맛있는녀석들' 식당 데이터 수집기")
    print("=" * 60)
    
    # 데이터 수집
    restaurants = scrape_diningcode_tasty_boys()
    
    if restaurants:
        print(f"\n총 {len(restaurants)}개 식당 데이터 수집 완료!")
        
        # CSV 저장
        output_file = 'd:/00_projects/02_TasteMap/doc/tasty_boys.csv'
        save_to_csv(restaurants, output_file)
        
        # 샘플 데이터 출력
        print("\n[샘플 데이터]")
        for i, restaurant in enumerate(restaurants[:5], 1):
            print(f"{i}. {restaurant['name']}")
            print(f"   주소: {restaurant['address']}")
            print(f"   카테고리: {restaurant['category']}")
            print(f"   평점: {restaurant['user_score']} (리뷰 {restaurant['review_cnt']}개)")
            print()
    else:
        print("\n⚠ 수집된 데이터가 없습니다.")


if __name__ == "__main__":
    main()
