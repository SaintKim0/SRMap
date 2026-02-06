import csv

def merge_restaurant_data():
    """미슐랭과 흑백요리사 데이터를 병합"""
    
    all_rows = []
    
    # 1. 미슐랭 데이터 로드
    print("[1] 미슐랭 데이터 로드 중...")
    michelin_file = 'd:/00_projects/01_ScreenMap_Backup/doc/michelin_geocoded.csv'
    with open(michelin_file, 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        header = next(reader)  # 헤더 스킵
        michelin_rows = list(reader)
        all_rows.extend(michelin_rows)
        print(f"   미슐랭: {len(michelin_rows)}개")
    
    # 2. 흑백요리사 데이터 로드
    print("[2] 흑백요리사 데이터 로드 중...")
    black_white_file = 'd:/00_projects/01_ScreenMap_Backup/doc/black_white_geocoded.csv'
    with open(black_white_file, 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        header = next(reader)  # 헤더 스킵
        bw_rows = list(reader)
        all_rows.extend(bw_rows)
        print(f"   흑백요리사: {len(bw_rows)}개")
    
    # 3. 연번 재정렬
    print("[3] 연번 재정렬 중...")
    for idx, row in enumerate(all_rows):
        row[0] = str(15273 + idx)  # 기존 locations.csv 다음 번호부터 시작
    
    # 4. 병합 파일 저장
    output_file = 'd:/00_projects/01_ScreenMap_Backup/doc/all_restaurants_merged.csv'
    with open(output_file, 'w', encoding='utf-8', newline='') as f:
        writer = csv.writer(f, quoting=csv.QUOTE_ALL)
        
        # 헤더 작성
        header = ["연번", "미디어타입", "제목", "장소명", "장소타입", "장소설명", 
                  "영업시간", "브레이크타임", "휴무일", "주소", "위도", "경도", "전화번호", "최종작성일"]
        writer.writerow(header)
        writer.writerows(all_rows)
    
    print(f"\n[완료] 병합 완료!")
    print(f"  - 미슐랭: {len(michelin_rows)}개")
    print(f"  - 흑백요리사: {len(bw_rows)}개")
    print(f"  - 총계: {len(all_rows)}개")
    print(f"  - 출력 파일: {output_file}")
    print(f"\n이 파일을 assets/data/locations.csv에 추가하시면 됩니다!")

if __name__ == "__main__":
    merge_restaurant_data()
