import csv
from io import StringIO

# 파일 경로
source_file = 'd:/00_projects/02_TasteMap/doc/data/전현무계획.csv'
target_file = 'd:/00_projects/02_TasteMap/assets/data/locations.csv'
output_file = 'd:/00_projects/02_TasteMap/assets/data/locations_merged.csv'

# 전현무계획.csv 읽기
with open(source_file, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# 헤더 라인 찾기 (```csv 다음 라인)
header_line_idx = None
for idx, line in enumerate(lines):
    if line.startswith('no,media_type,title'):
        header_line_idx = idx
        break

if header_line_idx is None:
    print("[X] CSV 헤더를 찾을 수 없습니다.")
    exit(1)

# CSV 데이터 추출
csv_content = lines[header_line_idx:]
reader = csv.reader(StringIO(''.join(csv_content)))
source_header = next(reader)
source_rows = list(reader)

print(f"[전현무계획.csv]")
print(f"  - 총 {len(source_rows)}개 레스토랑")

# locations.csv 읽기
with open(target_file, 'r', encoding='utf-8') as f:
    reader = csv.reader(f)
    target_header = next(reader)
    target_rows = list(reader)

# 마지막 번호 찾기
last_no = 0
for row in target_rows:
    if row and row[0].isdigit():
        last_no = max(last_no, int(row[0]))

print(f"\n[locations.csv]")
print(f"  - 총 {len(target_rows)}개 레스토랑")
print(f"  - 마지막 번호: {last_no}")

# 새로운 번호로 시작
next_no = last_no + 1

print(f"\n[병합]")
print(f"  - 시작 번호: {next_no}")

# 전현무계획 데이터에 새 번호 부여
updated_source_rows = []
for row in source_rows:
    if len(row) > 0:
        # 첫 번째 칼럼(no)을 새 번호로 교체
        new_row = [str(next_no)] + row[1:]
        updated_source_rows.append(new_row)
        next_no += 1

print(f"  - 종료 번호: {next_no - 1}")
print(f"  - 추가된 레스토랑: {len(updated_source_rows)}개")

# 병합된 파일 저장
with open(output_file, 'w', encoding='utf-8', newline='') as f:
    writer = csv.writer(f)
    writer.writerow(target_header)  # 헤더
    writer.writerows(target_rows)    # 기존 데이터
    writer.writerows(updated_source_rows)  # 새 데이터

print(f"\n[완료]")
print(f"  - 출력 파일: {output_file}")
print(f"  - 기존 레스토랑: {len(target_rows)}개")
print(f"  - 추가 레스토랑: {len(updated_source_rows)}개")
print(f"  - 총 레스토랑 수: {len(target_rows) + len(updated_source_rows)}개")
