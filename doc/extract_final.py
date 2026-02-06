"""
저장된 HTML 파일에서 다이닝코드 데이터 추출
"""
import re
import json
import csv
from datetime import datetime

def extract_from_html_file(html_file):
    """HTML 파일에서 listData 추출"""
    
    print(f"HTML 파일 읽는 중: {html_file}")
    
    try:
        with open(html_file, 'r', encoding='utf-8') as f:
            html_content = f.read()
    except Exception as e:
        print(f"❌ 파일 읽기 오류: {e}")
        return None
    
    print(f"파일 크기: {len(html_content):,} 바이트")
    
    # localStorage.setItem('listData', '...') 패턴 찾기
    pattern = r"localStorage\.setItem\('listData',\s*'(.+?)'\);"
    match = re.search(pattern, html_content, re.DOTALL)
    
    if not match:
        print("❌ listData를 찾을 수 없습니다.")
        print("다른 패턴 시도 중...")
        
        # 대안 패턴들 시도
        patterns = [
            r'localStorage\.setItem\("listData",\s*"(.+?)"\);',
            r"listData\s*=\s*'(.+?)';",
            r'listData\s*=\s*"(.+?)";',
        ]
        
        for alt_pattern in patterns:
            match = re.search(alt_pattern, html_content, re.DOTALL)
            if match:
                print(f"✅ 대안 패턴으로 발견!")
                break
        
        if not match:
            return None
    
    json_str = match.group(1)
    print(f"추출된 JSON 길이: {len(json_str):,} 문자")
    
    # 이스케이프 문자 처리
    json_str = json_str.replace('\\\\', '\\')
    json_str = json_str.replace("\\'", "'")
    
    try:
        # JSON 파싱
        data = json.loads(json_str)
        
        if 'poi_section' in data and 'list' in data['poi_section']:
            restaurants = data['poi_section']['list']
            print(f"✅ {len(restaurants)}개 식당 데이터 추출 성공!")
            return restaurants
        else:
            print("❌ poi_section.list를 찾을 수 없습니다.")
            print(f"데이터 키: {list(data.keys())}")
            return None
            
    except json.JSONDecodeError as e:
        print(f"❌ JSON 파싱 오류: {e}")
        print(f"오류 위치: {e.pos}")
        print(f"주변 텍스트: {json_str[max(0, e.pos-50):e.pos+50]}")
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
    
    # 통계
    areas = {}
    for r in restaurants:
        area = ', '.join(r.get('area', []))
        areas[area] = areas.get(area, 0) + 1
    
    print(f"\n📊 통계:")
    print(f"   - 총 식당 수: {len(restaurants)}개")
    avg_score = sum(r.get('user_score', 0) for r in restaurants) / len(restaurants) if restaurants else 0
    print(f"   - 평균 평점: {avg_score:.2f}")
    
    print(f"\n📍 지역별 분포 (Top 10):")
    for area, count in sorted(areas.items(), key=lambda x: x[1], reverse=True)[:10]:
        if area:
            print(f"   - {area}: {count}개")
    
    # 샘플 출력
    print(f"\n🍽️  샘플 (처음 5개):")
    for i, r in enumerate(restaurants[:5], 1):
        name = r.get('nm', '') + (' ' + r.get('branch', '') if r.get('branch') else '')
        area = ', '.join(r.get('area', []))
        print(f"{i}. {name} ({area})")
    
    print(f"\n🍽️  샘플 (마지막 5개):")
    for i, r in enumerate(restaurants[-5:], len(restaurants)-4):
        name = r.get('nm', '') + (' ' + r.get('branch', '') if r.get('branch') else '')
        area = ', '.join(r.get('area', []))
        print(f"{i}. {name} ({area})")


def main():
    print("=" * 70)
    print("다이닝코드 HTML 파일에서 데이터 추출")
    print("=" * 70)
    print()
    
    html_file = 'd:/00_projects/02_TasteMap/doc/경기도 맛있는녀석들 맛집 Top100 - 다이닝코드.html'
    
    # 데이터 추출
    restaurants = extract_from_html_file(html_file)
    
    # CSV 저장
    if restaurants:
        save_to_csv(restaurants)
    else:
        print("\n데이터 추출 실패")


if __name__ == "__main__":
    main()
