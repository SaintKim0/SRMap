"""
Selenium으로 다이닝코드 페이지에서 JavaScript 실행하여 데이터 추출
"""
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
import time
import json
import csv
from datetime import datetime

def extract_data_with_selenium():
    """Selenium으로 브라우저 제어하여 데이터 추출"""
    
    print("=" * 70)
    print("다이닝코드 데이터 자동 추출 시작")
    print("=" * 70)
    print()
    
    # Chrome 옵션 설정
    chrome_options = Options()
    # chrome_options.add_argument('--headless')  # 백그라운드 실행 (주석 처리하면 브라우저가 보임)
    chrome_options.add_argument('--no-sandbox')
    chrome_options.add_argument('--disable-dev-shm-usage')
    chrome_options.add_argument('--window-size=1920,1080')
    
    driver = None
    
    try:
        print("1. Chrome 브라우저 시작 중...")
        driver = webdriver.Chrome(options=chrome_options)
        
        # 페이지 열기
        url = "https://www.diningcode.com/list.dc?query=%EA%B2%BD%EA%B8%B0%EB%8F%84+%EB%A7%9B%EC%9E%88%EB%8A%94%EB%85%80%EC%84%9D%EB%93%A4"
        print(f"2. 페이지 로딩 중...")
        driver.get(url)
        
        # 페이지 로딩 대기
        time.sleep(5)
        
        print("3. 페이지 스크롤 중 (모든 데이터 로드)...")
        # 여러 번 스크롤하여 모든 데이터 로드
        for i in range(10):
            driver.execute_script("window.scrollTo(0, document.body.scrollHeight);")
            time.sleep(2)
            print(f"   스크롤 {i+1}/10...")
        
        print("\n4. localStorage에서 데이터 추출 중...")
        
        # JavaScript 실행하여 데이터 추출
        js_code = """
        let listDataStr = localStorage.getItem('listData');
        if (!listDataStr) return null;
        
        let listData = JSON.parse(listDataStr);
        if (!listData.poi_section || !listData.poi_section.list) return null;
        
        return listData.poi_section.list;
        """
        
        restaurants = driver.execute_script(js_code)
        
        if not restaurants:
            print("❌ 데이터를 찾을 수 없습니다!")
            return None
        
        print(f"✅ {len(restaurants)}개 식당 데이터 추출 완료!\n")
        
        # CSV 형식으로 변환
        csv_data = []
        today = datetime.now().strftime('%Y-%m-%d')
        
        for r in restaurants:
            name = r.get('nm', '')
            if r.get('branch'):
                name += ' ' + r['branch']
            
            address = r.get('road_addr', '') or r.get('addr', '')
            lat = r.get('lat', 0.0)
            lng = r.get('lng', 0.0)
            
            row = [
                "0",
                "show",
                "맛있는녀석들",
                name,
                "restaurant",
                "",
                "",
                "",
                "",
                address,
                str(lat),
                str(lng),
                "",
                today
            ]
            csv_data.append(row)
        
        return csv_data
        
    except Exception as e:
        print(f"\n❌ 오류 발생: {e}")
        import traceback
        traceback.print_exc()
        return None
        
    finally:
        if driver:
            print("\n5. 브라우저 종료 중...")
            driver.quit()


def save_to_csv(data, filename='d:/00_projects/02_TasteMap/doc/tasty_boys.csv'):
    """CSV 파일로 저장"""
    
    if not data:
        print("저장할 데이터가 없습니다.")
        return
    
    with open(filename, 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f, quoting=csv.QUOTE_ALL)
        writer.writerows(data)
    
    print(f"\n{'=' * 70}")
    print(f"✅ {len(data)}개 식당 데이터 저장 완료!")
    print(f"   파일: {filename}")
    print(f"{'=' * 70}")
    
    # 샘플 출력
    print(f"\n🍽️  샘플 데이터 (처음 5개):")
    for i, row in enumerate(data[:5], 1):
        print(f"{i}. {row[3]}")
        print(f"   주소: {row[9][:50]}...")
        print(f"   좌표: ({row[10]}, {row[11]})")
    
    print(f"\n🍽️  샘플 데이터 (마지막 5개):")
    for i, row in enumerate(data[-5:], len(data)-4):
        print(f"{i}. {row[3]}")
        print(f"   주소: {row[9][:50]}...")


def main():
    # 데이터 추출
    data = extract_data_with_selenium()
    
    # CSV 저장
    if data:
        save_to_csv(data)
    else:
        print("\n데이터 추출 실패")


if __name__ == "__main__":
    main()
