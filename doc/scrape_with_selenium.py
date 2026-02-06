from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.chrome.options import Options
import time
import csv
from datetime import datetime
import json

def setup_driver():
    """Chrome 드라이버 설정"""
    chrome_options = Options()
    chrome_options.add_argument('--headless')  # 백그라운드 실행
    chrome_options.add_argument('--no-sandbox')
    chrome_options.add_argument('--disable-dev-shm-usage')
    chrome_options.add_argument('--disable-gpu')
    chrome_options.add_argument('--window-size=1920,1080')
    chrome_options.add_argument('user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36')
    
    driver = webdriver.Chrome(options=chrome_options)
    return driver


def scroll_and_collect_all(driver, url, target_count=122):
    """스크롤하며 모든 식당 데이터 수집"""
    
    print(f"페이지 로딩 중: {url}")
    driver.get(url)
    
    # 초기 로딩 대기
    time.sleep(5)
    
    all_restaurants = []
    last_count = 0
    no_change_count = 0
    scroll_pause_time = 2
    
    print(f"\n목표: {target_count}개 식당 수집")
    print("스크롤하며 데이터 수집 시작...\n")
    
    while len(all_restaurants) < target_count:
        # 현재 페이지의 JavaScript 실행하여 listData 가져오기
        try:
            list_data_json = driver.execute_script("""
                return localStorage.getItem('listData');
            """)
            
            if list_data_json:
                list_data = json.loads(list_data_json)
                
                if 'poi_section' in list_data and 'list' in list_data['poi_section']:
                    current_restaurants = list_data['poi_section']['list']
                    
                    # 중복 제거하며 추가
                    for restaurant in current_restaurants:
                        name = restaurant.get('nm', '')
                        branch = restaurant.get('branch', '')
                        if branch:
                            name = f"{name} {branch}"
                        
                        address = restaurant.get('road_addr', '') or restaurant.get('addr', '')
                        
                        # 중복 체크 (이름 + 주소)
                        is_duplicate = False
                        for existing in all_restaurants:
                            if existing['name'] == name and existing['address'] == address:
                                is_duplicate = True
                                break
                        
                        if not is_duplicate:
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
                            }
                            all_restaurants.append(restaurant_data)
                    
                    current_count = len(all_restaurants)
                    print(f"현재 수집: {current_count}개 / {target_count}개")
                    
                    # 변화가 없으면 카운트 증가
                    if current_count == last_count:
                        no_change_count += 1
                    else:
                        no_change_count = 0
                        last_count = current_count
                    
                    # 5번 연속 변화 없으면 종료
                    if no_change_count >= 5:
                        print("\n더 이상 새로운 데이터가 로드되지 않습니다.")
                        break
        
        except Exception as e:
            print(f"데이터 추출 오류: {e}")
        
        # 페이지 끝까지 스크롤
        driver.execute_script("window.scrollTo(0, document.body.scrollHeight);")
        time.sleep(scroll_pause_time)
        
        # 추가 스크롤 (더 많은 데이터 로드를 위해)
        for _ in range(3):
            driver.execute_script("window.scrollBy(0, 500);")
            time.sleep(0.5)
        
        # 목표 달성 시 종료
        if len(all_restaurants) >= target_count:
            print(f"\n✅ 목표 달성! {len(all_restaurants)}개 수집 완료")
            break
    
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
    print("다이닝코드 '맛있는녀석들' 전체 데이터 수집 (무한 스크롤)")
    print("=" * 70)
    print()
    
    url = "https://www.diningcode.com/list.dc?query=%EA%B2%BD%EA%B8%B0%EB%8F%84+%EB%A7%9B%EC%9E%88%EB%8A%94%EB%85%80%EC%84%9D%EB%93%A4"
    
    driver = None
    try:
        # 드라이버 설정
        print("Chrome 드라이버 초기화 중...")
        driver = setup_driver()
        
        # 데이터 수집
        restaurants = scroll_and_collect_all(driver, url, target_count=122)
        
        if restaurants:
            print(f"\n{'=' * 70}")
            print(f"총 {len(restaurants)}개 식당 데이터 수집 완료!")
            print(f"{'=' * 70}\n")
            
            # CSV 저장
            output_file = 'd:/00_projects/02_TasteMap/doc/tasty_boys.csv'
            save_to_csv(restaurants, output_file)
            
            # 통계 출력
            print(f"\n📊 통계:")
            print(f"  - 전체 식당: {len(restaurants)}개")
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
            print(f"\n🍽️  샘플 데이터 (마지막 5개):")
            for i, restaurant in enumerate(restaurants[-5:], len(restaurants)-4):
                print(f"{i}. {restaurant['name']}")
                print(f"   주소: {restaurant['address'][:50]}...")
                print(f"   평점: {restaurant['user_score']}")
                print()
        else:
            print("\n⚠ 수집된 데이터가 없습니다.")
    
    except Exception as e:
        print(f"\n❌ 오류 발생: {e}")
        print("\n💡 Chrome 드라이버가 설치되어 있는지 확인해주세요.")
        print("   설치 방법: pip install selenium")
        print("   Chrome 드라이버: https://chromedriver.chromium.org/downloads")
    
    finally:
        if driver:
            driver.quit()
            print("\n드라이버 종료 완료")


if __name__ == "__main__":
    main()
