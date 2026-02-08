import csv
from io import StringIO

# 좌표 및 주소 업데이트 정보
updates = {
    "제주등대아구찜": {
        "correct_address": "제주 제주시 한림읍 한림해안로 145-2",
        "lat": "33.4159355",
        "lng": "126.2619060"
    },
    "아지트": {
        "correct_address": "강원 속초시 영랑해안길 133-7",
        "lat": "38.2156365",
        "lng": "128.5961626"
    }
}

input_file = 'd:/00_projects/02_TasteMap/doc/data/전현무계획.csv'
output_file = 'd:/00_projects/02_TasteMap/doc/data/전현무계획_fixed.csv'

# CSV 읽기
with open(input_file, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# 헤더 라인 찾기
header_line_idx = None
for idx, line in enumerate(lines):
    if line.startswith('no,media_type,title'):
        header_line_idx = idx
        break

if header_line_idx is None:
    print("[X] CSV 헤더를 찾을 수 없습니다.")
    exit(1)

# 헤더와 데이터 분리
preamble = lines[:header_line_idx]
csv_content = lines[header_line_idx:]

# CSV 파싱
csv_text = ''.join(csv_content)
reader = csv.reader(StringIO(csv_text))
header = next(reader)
rows = list(reader)

print(f"총 {len(rows)}개 레스토랑")
print("\n업데이트 중...")

updated_count = 0

for idx, row in enumerate(rows):
    place_name = row[3] if len(row) > 3 else ''
    
    if place_name in updates:
        update_info = updates[place_name]
        
        # 행 길이 확인 및 확장
        while len(row) < 15:
            row.append('')
        
        # 주소와 좌표 모두 업데이트
        row[10] = update_info["correct_address"]  # 주소
        row[11] = update_info["lat"]              # 위도
        row[12] = update_info["lng"]              # 경도
        
        print(f"✅ {place_name}")
        print(f"   주소: {update_info['correct_address']}")
        print(f"   좌표: ({update_info['lat']}, {update_info['lng']})")
        updated_count += 1

# 결과 저장
with open(output_file, 'w', encoding='utf-8', newline='') as f:
    # 원본 preamble 유지
    for line in preamble:
        f.write(line)
    
    # CSV 데이터 작성
    writer = csv.writer(f)
    writer.writerow(header)
    writer.writerows(rows)

print(f"\n완료! {updated_count}개 레스토랑 업데이트")
print(f"출력 파일: {output_file}")
