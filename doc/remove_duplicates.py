import csv
from datetime import datetime

def remove_duplicates_from_csv(input_file, output_file):
    """CSV 파일에서 중복 제거"""
    
    seen = set()
    unique_rows = []
    
    with open(input_file, 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        
        for row in reader:
            if len(row) >= 10:
                # 식당명과 주소로 고유성 판단
                name = row[3]
                address = row[9]
                key = (name, address)
                
                if key not in seen:
                    seen.add(key)
                    unique_rows.append(row)
    
    # 중복 제거된 데이터 저장
    with open(output_file, 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f, quoting=csv.QUOTE_ALL)
        writer.writerows(unique_rows)
    
    return len(unique_rows)


def main():
    input_file = 'd:/00_projects/02_TasteMap/doc/tasty_boys.csv'
    output_file = 'd:/00_projects/02_TasteMap/doc/tasty_boys.csv'
    
    print("=" * 60)
    print("CSV 파일 중복 제거 중...")
    print("=" * 60)
    
    unique_count = remove_duplicates_from_csv(input_file, output_file)
    
    print(f"\n✅ 중복 제거 완료!")
    print(f"   최종 식당 수: {unique_count}개")
    print(f"   저장 위치: {output_file}")


if __name__ == "__main__":
    main()
