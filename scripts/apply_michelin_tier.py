#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
michelin_tier_mapping.csv의 (no, place-name)과 locations.csv의 (no, place_name)이
일치하는 행에 tier를 적용하여 locations.csv에 michelin_tier 컬럼을 추가합니다.
"""
import csv
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
MAPPING_PATH = PROJECT_ROOT / "doc" / "michelin_tier_mapping.csv"
LOCATIONS_PATH = PROJECT_ROOT / "assets" / "data" / "locations.csv"


def main():
    # 1. mapping 로드: (no, place_name) -> tier (영문/한글 헤더 모두 처리)
    tier_by_key = {}
    with open(MAPPING_PATH, "r", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        for row in reader:
            no = (row.get("no") or row.get("연번") or "").strip()
            place_name = (row.get("place-name") or row.get("장소명") or "").strip()
            tier = (row.get("tier") or row.get("미쉐린등급") or "").strip()
            if no and place_name:
                tier_by_key[(no, place_name)] = tier

    print(f"매핑 로드: {len(tier_by_key)}건")

    # 2. locations 읽기
    with open(LOCATIONS_PATH, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        fieldnames = list(reader.fieldnames)
        rows = list(reader)

    if "michelin_tier" not in fieldnames:
        fieldnames.append("michelin_tier")

    matched = 0
    for row in rows:
        no = row.get("no", "").strip()
        place_name = row.get("place_name", "").strip()
        key = (no, place_name)
        tier = tier_by_key.get(key, "")
        row["michelin_tier"] = tier
        if tier:
            matched += 1

    print(f"일치하여 tier 적용: {matched}건")

    # 3. 저장
    with open(LOCATIONS_PATH, "w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)

    print(f"저장 완료: {LOCATIONS_PATH}")


if __name__ == "__main__":
    main()
