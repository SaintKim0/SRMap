"""
가장 간단한 방법: 브라우저에서 페이지 소스 저장하기

1. 브라우저에서 경기도 맛있는녀석들 페이지를 끝까지 스크롤
2. 페이지에서 마우스 우클릭 > "페이지 소스 보기" (또는 Ctrl+U)
3. 전체 HTML 소스를 복사 (Ctrl+A, Ctrl+C)
4. 아래 html_source 변수에 붙여넣기
5. 이 스크립트 실행

또는 더 쉬운 방법:
1. 브라우저에서 Ctrl+S로 페이지를 HTML 파일로 저장
2. 저장된 파일 경로를 아래 html_file 변수에 입력
3. 이 스크립트 실행
"""

import re
import json
import csv
from datetime import datetime

# 방법 1: HTML 소스를 직접 붙여넣기
html_source = """"""

# 방법 2: 저장된 HTML 파일 경로
html_file = ""  # 예: "C:/Users/USER/Downloads/list.html"


def extract_from_html(html_content):
    """HTML에서 listData 추출"""
    
    # localStorage.setItem('listData', '...') 패턴 찾기
    pattern = r"localStorage\.setItem\('listData',\s*'(.+?)'\);"
    match = re.search(pattern, html_content, re.DOTALL)
    
    if not match:
        print("❌ listData를 찾을 수 없습니다.")
        return None
    
    json_str = match.group(1)
    
    # 이스케이프 문자 처리
    json_str = json_str.replace('\\\\', '\\')
    json_str = json_str.replace("\\'", "'")
    json_str = json_str.replace('\\"', '"')
    
    try:
        # JSON 파싱
        data = json.loads(json_str)
        
        if 'poi_section' in data and 'list' in data['poi_section']:
            restaurants = data['poi_section']['list']
            print(f"✅ {len(restaurants)}개 식당 데이터 추출 성공!")
            return restaurants
        else:
            print("❌ poi_section.list를 찾을 수 없습니다.")
            return None
            
    except json.JSONDecodeError as e:
        print(f"❌ JSON 파싱 오류: {e}")
        return None


def save_to_csv(restaurants, filename='d:/00_projects/02_TasteMap/doc/tasty_boys.csv'):
    """CSV 파일로 저장"""
    
    if not restaurants:
        print("저장할 데이터가 없습니다.")
        return
    
    current_date = datetime.now().strftime('%Y-%m-%d')
    
    with open(filename, 'w', newline='', encoding='utf-8') as csvfile:
        writer = csv.writer(csvfile, quoting=csv.QUOTE_ALL)
        
        for restaurant in restaurants:
            name = restaurant.get('nm', '')
            if restaurant.get('branch'):
                name += ' ' + restaurant['branch']
            
            address = restaurant.get('road_addr', '') or restaurant.get('addr', '')
            lat = restaurant.get('lat', 0.0)
            lng = restaurant.get('lng', 0.0)
            
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
                current_date
            ]
            writer.writerow(row)
    
    print(f"\n✅ {len(restaurants)}개 식당 데이터를 '{filename}' 파일로 저장했습니다.")
    
    # 샘플 출력
    print(f"\n🍽️  샘플 (처음 5개):")
    for i, r in enumerate(restaurants[:5], 1):
        name = r.get('nm', '') + (' ' + r.get('branch', '') if r.get('branch') else '')
        print(f"{i}. {name}")
    
    print(f"\n🍽️  샘플 (마지막 5개):")
    for i, r in enumerate(restaurants[-5:], len(restaurants)-4):
        name = r.get('nm', '') + (' ' + r.get('branch', '') if r.get('branch') else '')
        print(f"{i}. {name}")


def main():
    print("=" * 70)
    print("다이닝코드 HTML에서 데이터 추출")
    print("=" * 70)
    print()
    
    html_content = None
    
    # 방법 1: 직접 붙여넣은 HTML 소스
    if html_source.strip():
        print("HTML 소스에서 데이터 추출 중...")
        html_content = html_source
    
    # 방법 2: 파일에서 읽기
    elif html_file.strip():
        print(f"파일에서 읽는 중: {html_file}")
        try:
            with open(html_file, 'r', encoding='utf-8') as f:
                html_content = f.read()
        except Exception as e:
            print(f"❌ 파일 읽기 오류: {e}")
            return
    
    else:
        print("⚠️  HTML 소스나 파일 경로를 입력해주세요!")
        print()
        print("📝 사용 방법:")
        print("1. 브라우저에서 페이지를 끝까지 스크롤")
        print("2. Ctrl+S로 HTML 파일로 저장")
        print("3. 저장된 파일 경로를 html_file 변수에 입력")
        print("4. 다시 실행")
        return
    
    # 데이터 추출
    restaurants = extract_from_html(html_content)
    
    # CSV 저장
    if restaurants:
        save_to_csv(restaurants)


if __name__ == "__main__":
    main()
