"""
다이닝코드에서 추출한 데이터를 tasty_boys.csv로 저장하는 스크립트

사용 방법:
1. 브라우저에서 https://www.diningcode.com/list.dc?query=경기도+맛있는녀석들 열기
2. 페이지를 끝까지 스크롤하여 모든 데이터 로드
3. F12 눌러 개발자 도구 열기
4. Console 탭에서 extract_data.js 파일의 코드 복사하여 실행
5. 클립보드에 복사된 CSV 데이터를 아래 data 변수에 붙여넣기
6. 이 스크립트 실행: python save_tasty_boys_data.py
"""

import csv
from datetime import datetime

# 여기에 브라우저 콘솔에서 복사한 CSV 데이터를 붙여넣으세요
# 예시:
# data = '''
# "0","show","맛있는녀석들","보림숯불갈비","restaurant","","","","","경기도 이천시 중리천로72번길 23","37.277844","127.445342","","2026-01-31"
# "0","show","맛있는녀석들","맷돌우리콩감자탕 본점","restaurant","","","","","경기도 파주시 숲속노을로 330","37.7287166","126.7073858","","2026-01-31"
# ...
# '''

data = """"""

def save_csv_data(csv_text, output_file='d:/00_projects/02_TasteMap/doc/tasty_boys.csv'):
    """CSV 텍스트를 파일로 저장"""
    
    if not csv_text.strip():
        print("❌ 데이터가 비어있습니다!")
        print("\n사용 방법:")
        print("1. 브라우저 콘솔에서 extract_data.js 코드 실행")
        print("2. 복사된 CSV 데이터를 이 파일의 data 변수에 붙여넣기")
        print("3. 다시 실행")
        return
    
    # 줄 단위로 분리
    lines = [line.strip() for line in csv_text.strip().split('\n') if line.strip()]
    
    # CSV 파일로 저장
    with open(output_file, 'w', encoding='utf-8', newline='') as f:
        f.write('\n'.join(lines))
    
    print("=" * 60)
    print(f"✅ {len(lines)}개 식당 데이터 저장 완료!")
    print(f"   파일: {output_file}")
    print("=" * 60)
    
    # 통계 출력
    print(f"\n📊 저장된 데이터:")
    print(f"   - 총 식당 수: {len(lines)}개")
    
    # 처음 5개 샘플 출력
    print(f"\n🍽️  샘플 데이터 (처음 5개):")
    for i, line in enumerate(lines[:5], 1):
        parts = line.split('","')
        if len(parts) >= 4:
            name = parts[3].replace('"', '')
            print(f"   {i}. {name}")


def main():
    print("=" * 60)
    print("다이닝코드 맛있는녀석들 데이터 저장")
    print("=" * 60)
    print()
    
    if not data.strip():
        print("⚠️  data 변수가 비어있습니다!")
        print()
        print("📝 사용 방법:")
        print("1. 브라우저에서 다이닝코드 페이지 열기")
        print("   URL: https://www.diningcode.com/list.dc?query=경기도+맛있는녀석들")
        print()
        print("2. 페이지를 끝까지 스크롤 (모든 122개 식당 로드)")
        print()
        print("3. F12 눌러 개발자 도구 > Console 탭")
        print()
        print("4. extract_data.js 파일의 코드를 복사하여 실행")
        print()
        print("5. 클립보드에 복사된 CSV 데이터를")
        print("   이 파일의 data = \"\"\"\"\"\" 사이에 붙여넣기")
        print()
        print("6. 다시 실행: python save_tasty_boys_data.py")
        print()
        return
    
    save_csv_data(data)


if __name__ == "__main__":
    main()
