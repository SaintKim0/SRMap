import requests
import json
import csv
import time
from datetime import datetime
import re

def fetch_page_data(from_index=0, size=20):
    """다이닝코드 페이지 데이터 가져오기"""
    
    url = "https://www.diningcode.com/list.dc"
    params = {
        'query': '경기도 맛있는녀석들',
        'from': from_index,
        'size': size
    }
    
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
        'Accept-Language': 'ko-KR,ko;q=0.9,en-US;q=0.8,en;q=0.7',
        'Referer': 'https://www.diningcode.com/',
    }
    
    try:
        response = requests.get(url, params=params, headers=headers, timeout=30)
        response.raise_for_status()
        
        # HTML에서 localStorage.setItem('listData', ...) 부분 찾기
        html_content = response.text
        
        # listData JSON 추출
        match = re.search(r"localStorage\.setItem\('listData',\s*'(.+?)'\);", html_content, re.DOTALL)
        
        if match:
            json_str = match.group(1)
            # 이스케이프 처리
            json_str = json_str.replace('\\\\', '\\')
            json_str = json_str.replace("\\'", "'")
            json_str = json_str.replace('\\"', '"')
            
            try:
                data = json.loads(json_str)
                return data
            except json.JSONDecodeError as e:
                print(f"JSON 파싱 오류: {e}")
                # 대안: 더 간단한 방법으로 재시도
                try:
                    # 백슬래시 처리를 다르게
                    json_str = match.group(1)
                    json_str = json_str.encode().decode('unicode_escape')
                    data = json.loads(json_str)
                    return data
                except:
                    return None
        
        return None
        
    except Exception as e:
        print(f"요청 오류: {e}")
        return None


def scrape_all_restaurants():
    """모든 식당 데이터 수집"""
    
    all_restaurants = []
    total_count = 122
    page_size = 20
    total_pages = (total_count + page_size - 1) // page_size  # 올림 계산
    
    print(f"총 {total_count}개 식당을 {total_pages}페이지에 걸쳐 수집합니다...\n")
    
    for page in range(total_pages):
        from_index = page * page_size
        
        print(f"[{page + 1}/{total_pages}] 페이지 수집 중... (from: {from_index})")
        
        data = fetch_page_data(from_index, page_size)
        
        if data and 'poi_section' in data and 'list' in data['poi_section']:
            restaurants = data['poi_section']['list']
            
            for restaurant in restaurants:
                # 맛있는녀석들 키워드 확인
                has_tasty_boys = False
                if 'keyword' in restaurant:
                    for kw in restaurant['keyword']:
                        if kw.get('term') == '맛있는녀석들' and kw.get('mark') == 1:
                            has_tasty_boys = True
                            break
                
                # 모든 식당 포함 (맛있는녀석들 태그 여부와 관계없이)
                name = restaurant.get('nm', '')
                branch = restaurant.get('branch', '')
                if branch:
                    name = f"{name} {branch}"
                
                address = restaurant.get('road_addr', '') or restaurant.get('addr', '')
                
                restaurant_data = {
                    'name': name,
                    'address': address,
                    'category': restaurant.get('category', ''),
                    'phone': restaurant.get('phone', ''),
                    'lat': restaurant.get('lat', 0.0),
                    'lng': restaurant.get('lng', 0.0),
                    'score': restaurant.get('score', 0),
                    'user_score': restaurant.get('user_score', 0.0),
                    'review_cnt': restaurant.get('review_cnt', 0),
                    'area': ', '.join(restaurant.get('area', [])),
                    'has_tasty_boys_tag': has_tasty_boys
                }
                
                all_restaurants.append(restaurant_data)
                print(f"  ✓ {name} ({restaurant_data['area']})")
            
            print(f"  → {len(restaurants)}개 식당 수집 완료\n")
        else:
            print(f"  ✗ 데이터를 가져올 수 없습니다.\n")
        
        # 요청 간 딜레이 (서버 부하 방지)
        if page < total_pages - 1:
            time.sleep(2)
    
    return all_restaurants


def save_to_csv(restaurants, filename):
    """CSV 파일로 저장"""
    
    current_date = datetime.now().strftime('%Y-%m-%d')
    
    with open(filename, 'w', newline='', encoding='utf-8') as csvfile:
        writer = csv.writer(csvfile, quoting=csv.QUOTE_ALL)
        
        for restaurant in restaurants:
            row = [
                "0",  # id
                "show",  # sector
                "맛있는녀석들",  # title
                restaurant['name'],  # name
                "restaurant",  # type
                "",  # chef
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
    print("=" * 70)
    print("다이닝코드 '맛있는녀석들' 경기도 전체 식당 데이터 수집기")
    print("=" * 70)
    print()
    
    # 데이터 수집
    restaurants = scrape_all_restaurants()
    
    if restaurants:
        print(f"\n{'=' * 70}")
        print(f"총 {len(restaurants)}개 식당 데이터 수집 완료!")
        print(f"{'=' * 70}\n")
        
        # CSV 저장
        output_file = 'd:/00_projects/02_TasteMap/doc/tasty_boys.csv'
        save_to_csv(restaurants, output_file)
        
        # 통계 출력
        tasty_boys_tagged = sum(1 for r in restaurants if r['has_tasty_boys_tag'])
        print(f"\n📊 통계:")
        print(f"  - 전체 식당: {len(restaurants)}개")
        print(f"  - 맛있는녀석들 태그: {tasty_boys_tagged}개")
        print(f"  - 평균 평점: {sum(r['user_score'] for r in restaurants) / len(restaurants):.2f}")
        
        # 지역별 통계
        areas = {}
        for r in restaurants:
            area = r['area']
            areas[area] = areas.get(area, 0) + 1
        
        print(f"\n📍 지역별 분포 (Top 10):")
        for area, count in sorted(areas.items(), key=lambda x: x[1], reverse=True)[:10]:
            print(f"  - {area}: {count}개")
        
        # 샘플 데이터
        print(f"\n🍽️  샘플 데이터 (처음 5개):")
        for i, restaurant in enumerate(restaurants[:5], 1):
            print(f"{i}. {restaurant['name']}")
            print(f"   주소: {restaurant['address'][:50]}...")
            print(f"   카테고리: {restaurant['category']}")
            print(f"   평점: {restaurant['user_score']} (리뷰 {restaurant['review_cnt']}개)")
            print()
    else:
        print("\n⚠ 수집된 데이터가 없습니다.")


if __name__ == "__main__":
    main()
