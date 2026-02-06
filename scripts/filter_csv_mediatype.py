# -*- coding: utf-8 -*-
"""locations.csv에서 media_type이 movie, drama, artist인 행 제거 (맛집지도용)"""
import csv
import os

CSV_PATH = os.path.join(os.path.dirname(__file__), '..', 'assets', 'data', 'locations.csv')
REMOVE_TYPES = {'movie', 'drama', 'artist'}

def main():
    with open(CSV_PATH, 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        rows = list(reader)
    if not rows:
        print('CSV is empty')
        return
    header = rows[0]
    # media_type 컬럼 인덱스 (no, media_type, ...)
    col_media_type = 1
    kept = [header]
    removed = 0
    for row in rows[1:]:
        if len(row) <= col_media_type:
            removed += 1
            continue
        mt = row[col_media_type].strip().lower()
        if mt in REMOVE_TYPES:
            removed += 1
            continue
        kept.append(row)
    with open(CSV_PATH, 'w', encoding='utf-8', newline='') as f:
        writer = csv.writer(f)
        writer.writerows(kept)
    print(f'Removed {removed} rows (movie/drama/artist). Kept {len(kept)-1} rows.')

if __name__ == '__main__':
    main()
