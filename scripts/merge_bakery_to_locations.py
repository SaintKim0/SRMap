"""
천하제빵.csv를 locations.csv에 병합하는 스크립트
"""
import csv

def merge_csv_files():
    """천하제빵 데이터를 locations.csv에 추가"""
    
    # 천하제빵 데이터 읽기 (UTF-8)
    with open('doc/data/천하제빵.csv', 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        header = next(reader)
        bakery_rows = list(reader)
    
    print(f"천하제빵 데이터: {len(bakery_rows)}개 항목")
    
    # locations.csv 읽기 (UTF-8-SIG for BOM)
    with open('assets/data/locations.csv', 'r', encoding='utf-8-sig') as f:
        reader = csv.reader(f)
        loc_header = next(reader)
        location_rows = list(reader)
    
    print(f"기존 locations.csv: {len(location_rows)}개 항목")
    
    # 헤더 확인
    print(f"\n헤더 비교:")
    print(f"천하제빵: {header[:5]}")
    print(f"locations: {loc_header[:5]}")
    
    if header != loc_header:
        print("⚠️ 헤더가 다르지만 계속 진행합니다 (컬럼 순서가 같으면 OK)")
    
    # 기존 ID 확인 (중복 방지)
    existing_ids = {row[0] for row in location_rows if len(row) > 0}
    print(f"\n기존 ID 개수: {len(existing_ids)}")
    
    # 새로운 ID 생성 (기존 최대 ID + 1부터)
    max_id = 0
    for row in location_rows:
        if len(row) > 0 and row[0].isdigit():
            max_id = max(max_id, int(row[0]))
    
    print(f"기존 최대 ID: {max_id}")
    
    # 천하제빵 데이터에 새 ID 부여
    new_rows = []
    next_id = max_id + 1
    
    for row in bakery_rows:
        if len(row) > 0:
            # 첫 번째 컬럼(ID)을 새 ID로 변경
            new_row = row.copy()
            new_row[0] = str(next_id)
            new_rows.append(new_row)
            next_id += 1
    
    print(f"\n추가할 항목: {len(new_rows)}개 (ID: {max_id+1} ~ {next_id-1})")
    
    # 병합
    merged_rows = location_rows + new_rows
    
    # 백업 생성
    import shutil
    backup_file = 'assets/data/locations_backup.csv'
    shutil.copy('assets/data/locations.csv', backup_file)
    print(f"\n✓ 백업 생성: {backup_file}")
    
    # 저장 (UTF-8-SIG to preserve BOM)
    with open('assets/data/locations.csv', 'w', encoding='utf-8-sig', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(loc_header)
        writer.writerows(merged_rows)
    
    print(f"✓ 병합 완료: {len(merged_rows)}개 항목 (기존 {len(location_rows)} + 신규 {len(new_rows)})")
    print(f"✓ 저장: assets/data/locations.csv")
    
    # 검증
    with open('assets/data/locations.csv', 'r', encoding='utf-8-sig') as f:
        reader = csv.reader(f)
        next(reader)
        final_count = sum(1 for _ in reader)
    
    print(f"\n검증: 최종 {final_count}개 항목")

if __name__ == "__main__":
    merge_csv_files()
