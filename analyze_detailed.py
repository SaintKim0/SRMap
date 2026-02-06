import csv
import json

print("=" * 60)
print("상세 데이터 분석")
print("=" * 60)

# 파일 읽기
data = []
with open('assets/data/locations.csv', 'r', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    data = list(reader)

total_records = len(data)

# 좌표 범위 분석
print("\n10. 좌표 범위 분석")
latitudes = []
longitudes = []
for row in data:
    try:
        lat = float(row['latitude']) if row['latitude'] and row['latitude'].strip() else None
        lng = float(row['longitude']) if row['longitude'] and row['longitude'].strip() else None
        if lat and lng:
            latitudes.append(lat)
            longitudes.append(lng)
    except:
        pass

if latitudes and longitudes:
    print(f"   위도 범위: {min(latitudes):.6f} ~ {max(latitudes):.6f}")
    print(f"   경도 범위: {min(longitudes):.6f} ~ {max(longitudes):.6f}")
    print(f"   유효한 좌표 수: {len(latitudes):,}개")

# 장소명 중복 체크
print("\n11. 장소명 중복 분석")
place_names = {}
for row in data:
    name = row['place_name']
    if name not in place_names:
        place_names[name] = []
    place_names[name].append({
        'no': row['no'],
        'title': row['title'],
        'address': row['address']
    })

duplicates = {k: v for k, v in place_names.items() if len(v) > 1}
print(f"   고유 장소명 수: {len(place_names):,}개")
print(f"   중복된 장소명 수: {len(duplicates):,}개")
if duplicates:
    # 가장 많이 중복된 장소명 상위 10개
    sorted_dups = sorted(duplicates.items(), key=lambda x: len(x[1]), reverse=True)[:10]
    print(f"\n   중복 빈도 상위 10개:")
    for name, occurrences in sorted_dups:
        print(f"     {name}: {len(occurrences)}회")
        # 서로 다른 작품에 나온 경우
        titles = set(occ['title'] for occ in occurrences)
        if len(titles) > 1:
            print(f"       -> {len(titles)}개 작품에 등장")

# 데이터 구조 요약
print("\n12. 데이터 구조 요약")
structure = {
    'total_records': total_records,
    'columns': list(data[0].keys()) if data else [],
    'media_types': list(set(row['media_type'] for row in data)),
    'place_types': list(set(row['place_type'] for row in data)),
    'date_range': {
        'start': min(row['last_updated'] for row in data if row['last_updated']),
        'end': max(row['last_updated'] for row in data if row['last_updated'])
    },
    'coordinate_coverage': {
        'total': total_records,
        'with_coords': len(latitudes),
        'coverage_percent': (len(latitudes) / total_records * 100) if total_records > 0 else 0
    }
}

print(f"   총 레코드: {structure['total_records']:,}개")
print(f"   미디어타입: {len(structure['media_types'])}종류 - {', '.join(structure['media_types'])}")
print(f"   장소타입: {len(structure['place_types'])}종류")
print(f"   좌표 커버리지: {structure['coordinate_coverage']['coverage_percent']:.2f}%")

# JSON으로 구조 저장
with open('data_structure.json', 'w', encoding='utf-8') as f:
    json.dump(structure, f, ensure_ascii=False, indent=2)

print("\n   데이터 구조가 'data_structure.json' 파일로 저장되었습니다.")

print("\n" + "=" * 60)
print("상세 분석 완료")
print("=" * 60)
