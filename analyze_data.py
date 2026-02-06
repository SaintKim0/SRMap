import csv
from collections import Counter, defaultdict
from datetime import datetime

print("=" * 60)
print("데이터 파일 분석 시작")
print("=" * 60)

# 파일 읽기
data = []
with open('assets/data/locations.csv', 'r', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    data = list(reader)

total_records = len(data)
print(f"\n1. 기본 통계")
print(f"   총 레코드 수: {total_records:,}개")

# 컬럼 정보
columns = list(data[0].keys()) if data else []
print(f"   컬럼 수: {len(columns)}개")
print(f"   컬럼명: {', '.join(columns)}")

# 미디어타입별 분포
print(f"\n2. 미디어타입별 분포")
media_types = Counter(row['media_type'] for row in data)
for media_type, count in sorted(media_types.items(), key=lambda x: x[1], reverse=True):
    percentage = (count / total_records) * 100
    print(f"   {media_type:20s}: {count:6,}개 ({percentage:5.2f}%)")

# 장소타입별 분포
print(f"\n3. 장소타입별 분포")
place_types = Counter(row['place_type'] for row in data)
for place_type, count in sorted(place_types.items(), key=lambda x: x[1], reverse=True):
    percentage = (count / total_records) * 100
    print(f"   {place_type:20s}: {count:6,}개 ({percentage:5.2f}%)")

# 작품(제목)별 분포 (상위 20개)
print(f"\n4. 작품(제목)별 분포 (상위 20개)")
titles = Counter(row['title'] for row in data)
print(f"   총 고유 작품 수: {len(titles)}개")
for title, count in titles.most_common(20):
    print(f"   {count:4,}개 - {title}")

# 데이터 품질 체크
print(f"\n5. 데이터 품질 체크")

# 좌표 정보
missing_lat = sum(1 for row in data if not row['latitude'] or row['latitude'].strip() == '')
missing_lng = sum(1 for row in data if not row['longitude'] or row['longitude'].strip() == '')
missing_coords = sum(1 for row in data if (not row['latitude'] or row['latitude'].strip() == '') or 
                     (not row['longitude'] or row['longitude'].strip() == ''))
print(f"   좌표 정보 누락:")
print(f"     - 위도 누락: {missing_lat:,}개 ({missing_lat/total_records*100:.2f}%)")
print(f"     - 경도 누락: {missing_lng:,}개 ({missing_lng/total_records*100:.2f}%)")
print(f"     - 좌표 전체 누락: {missing_coords:,}개 ({missing_coords/total_records*100:.2f}%)")

# 주소 정보
missing_addr = sum(1 for row in data if not row['address'] or row['address'].strip() == '' or row['address'] == '정보없음')
print(f"   주소 정보 누락: {missing_addr:,}개 ({missing_addr/total_records*100:.2f}%)")

# 전화번호 정보
missing_phone = sum(1 for row in data if not row['phone'] or row['phone'].strip() == '' or row['phone'] == '정보없음')
print(f"   전화번호 정보 누락: {missing_phone:,}개 ({missing_phone/total_records*100:.2f}%)")

# 영업시간 정보
missing_hours = sum(1 for row in data if not row['opening_hours'] or row['opening_hours'].strip() == '' or row['opening_hours'] == '정보없음')
print(f"   영업시간 정보 누락: {missing_hours:,}개 ({missing_hours/total_records*100:.2f}%)")

# 날짜 범위
print(f"\n6. 날짜 정보")
dates = [row['last_updated'] for row in data if row['last_updated'] and row['last_updated'].strip()]
if dates:
    try:
        date_objects = []
        for d in dates:
            try:
                date_objects.append(datetime.strptime(d, '%Y-%m-%d'))
            except:
                pass
        if date_objects:
            min_date = min(date_objects)
            max_date = max(date_objects)
            print(f"   최초 작성일: {min_date.strftime('%Y-%m-%d')}")
            print(f"   최종 작성일: {max_date.strftime('%Y-%m-%d')}")
            print(f"   날짜 범위: {(max_date - min_date).days}일")
    except:
        print(f"   날짜 파싱 오류 (샘플: {dates[:3]})")

# 지역 분포 (시/도 단위)
print(f"\n7. 지역 분포 (시/도 단위)")
regions = defaultdict(int)
for row in data:
    addr = row['address'] if row['address'] else ''
    if addr and addr != '정보없음':
        # 주소에서 첫 번째 단어 추출 (시/도)
        parts = addr.split()
        if parts:
            region = parts[0]
            regions[region] += 1

print(f"   총 지역 수: {len(regions)}개")
for region, count in sorted(regions.items(), key=lambda x: x[1], reverse=True)[:15]:
    percentage = (count / total_records) * 100
    print(f"   {region:15s}: {count:6,}개 ({percentage:5.2f}%)")

# 미디어타입별 장소타입 분포
print(f"\n8. 미디어타입별 장소타입 분포 (상위 조합)")
media_place_combo = Counter((row['media_type'], row['place_type']) for row in data)
for (media, place), count in media_place_combo.most_common(15):
    print(f"   {media:15s} + {place:15s}: {count:5,}개")

# 샘플 데이터 확인
print(f"\n9. 샘플 데이터 (첫 3개 레코드)")
for i, row in enumerate(data[:3], 1):
    print(f"\n   레코드 {i}:")
    for key, value in row.items():
        if value and len(str(value)) > 100:
            print(f"     {key:15s}: {str(value)[:100]}...")
        else:
            print(f"     {key:15s}: {value}")

# 통계 요약
print(f"\n" + "=" * 60)
print("분석 완료")
print("=" * 60)
