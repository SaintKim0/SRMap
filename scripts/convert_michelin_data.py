import csv
import re
from datetime import datetime

def clean_phone(phone):
    """전화번호 정리"""
    if not phone or phone == '':
        return '정보없음'
    return phone.strip()

def parse_address(address):
    """주소에서 도시와 우편번호 제거"""
    # Remove postal code (숫자 5-6자리)
    address = re.sub(r',\s*\d{5,6},', ',', address)
    # Remove country name
    address = address.replace(', 한국', '').replace(',한국', '')
    # Remove city names like Seoul, Busan
    address = re.sub(r',\s*(Seoul|Busan)\s*,', ',', address)
    address = re.sub(r',\s*(Seoul|Busan)\s*$', '', address)
    # Clean up multiple commas
    address = re.sub(r',\s*,', ',', address)
    address = address.strip().strip(',').strip()
    return address

def get_tier_description(tier):
    """미슐랭 등급을 설명으로 변환"""
    tier_map = {
        '3star': '미슐랭 3스타',
        '2star': '미슐랭 2스타',
        '1star': '미슐랭 1스타',
        'michelin': '미슐랭 셀렉티드',
        'bib': '빕 구르망'
    }
    return tier_map.get(tier, '미슐랭 가이드')

def main():
    # 1. 미슐랭 등급 매핑 로드
    tier_mapping = {}
    with open('d:/00_projects/01_ScreenMap_Backup/doc/michelin_tier_mapping.csv', 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            tier_mapping[row['장소명'].strip()] = row['미쉐린등급'].strip()
    
    print(f"✓ 미슐랭 등급 매핑 로드 완료: {len(tier_mapping)}개")
    
    # 2. 미슐랭 레스토랑 데이터 로드 및 변환
    output_rows = []
    matched_count = 0
    unmatched_count = 0
    start_id = 15273  # 시작 연번
    
    with open('d:/00_projects/01_ScreenMap_Backup/doc/michelin2025.csv', 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        
        for idx, row in enumerate(reader):
            if len(row) < 14:
                continue
            
            # 컬럼 인덱스: 0=연번, 1=guide, 2=제목, 3=장소명, 4=타입, 5-8=빈값, 9=전화번호, 10=주소, 11-12=좌표, 13=URL, 14=날짜
            restaurant_name = row[3].strip()
            
            # 미슐랭 등급 찾기
            tier = tier_mapping.get(restaurant_name, 'michelin')
            if restaurant_name in tier_mapping:
                matched_count += 1
            else:
                unmatched_count += 1
                print(f"⚠ 등급 정보 없음: {restaurant_name}")
            
            # 주소 정리
            address = parse_address(row[9])
            
            # 전화번호 정리
            phone = clean_phone(row[8])
            
            # 장소 설명 생성
            tier_desc = get_tier_description(tier)
            description = f"{tier_desc} 레스토랑."
            
            # CSV 행 생성 (14개 컬럼)
            # "연번","미디어타입","제목","장소명","장소타입","장소설명","영업시간","브레이크타임","휴무일","주소","위도","경도","전화번호","최종작성일"
            output_row = [
                str(start_id + idx),                    # 연번
                "guide",                                 # 미디어타입
                "미슐랭 가이드 2025",                    # 제목
                restaurant_name,                         # 장소명
                "restaurant",                            # 장소타입
                description,                             # 장소설명
                "정보없음",                              # 영업시간
                "정보없음",                              # 브레이크타임
                "정보없음",                              # 휴무일
                address,                                 # 주소
                "0.0",                                   # 위도 (나중에 geocoding 필요)
                "0.0",                                   # 경도 (나중에 geocoding 필요)
                phone,                                   # 전화번호
                datetime.now().strftime("%Y-%m-%d")     # 최종작성일
            ]
            
            output_rows.append(output_row)
    
    # 3. 결과 저장
    output_file = 'd:/00_projects/01_ScreenMap_Backup/doc/michelin_converted.csv'
    with open(output_file, 'w', encoding='utf-8', newline='') as f:
        writer = csv.writer(f, quoting=csv.QUOTE_ALL)
        
        # 헤더 작성
        header = ["연번", "미디어타입", "제목", "장소명", "장소타입", "장소설명", 
                  "영업시간", "브레이크타임", "휴무일", "주소", "위도", "경도", "전화번호", "최종작성일"]
        writer.writerow(header)
        
        # 데이터 작성
        writer.writerows(output_rows)
    
    print(f"\n✓ 변환 완료!")
    print(f"  - 총 레스토랑: {len(output_rows)}개")
    print(f"  - 등급 매칭: {matched_count}개")
    print(f"  - 등급 미매칭: {unmatched_count}개")
    print(f"  - 출력 파일: {output_file}")
    print(f"\n⚠ 주의: 위도/경도는 0.0으로 설정되어 있습니다. Geocoding이 필요합니다.")

if __name__ == "__main__":
    main()
