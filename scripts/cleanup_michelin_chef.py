import csv
import os
import re

def main():
    csv_path = 'assets/data/locations.csv'
    
    with open(csv_path, 'r', encoding='utf-8-sig') as f:
        reader = csv.reader(f)
        header = next(reader)
        rows = list(reader)

    # Common false positives seen in logs
    black_list = {
        "오너", "현장", "경우", "모습", "한식을", "덕분에", "됩니다", "부부", 
        "청와대", "핵심은", "스타", "유명", "명의", "지닌", "수련한", 
        "어우러져", "앉아서", "명장", "출신", "위한", "키토리는", "리보다는",
        "되어", "있는", "곳으로", "대해", "주목", "한층", "함께", "나온",
        "들어", "통해", "정보없음", "null", "레스토랑", "신라호텔", "서현민",
        "오마카세", "마카세는", "벽면에는", "들어선", "들어서면", "요리마다",
        "트렌디", "렌디함과", "쌓은", "이블에서", "베이스는", "꼽으라면", 
        "총괄", "세계적인", "아마도", "대표적", "위치한", "주방장", "헤드",
        "이상의", "제공하", "경력을", "선보이", "하나인", "요리를", "공간",
        "셰프가", "셰프의", "셰프는", "셰프를", "셰프와",
        "프렌치", "젊은", "근무하던", "좌석이", "최고", "매진하는", "이름난", 
        "추구하는", "이다보니", "모색하는", "있던데요", "저분이", "바라보면", 
        "메인", "꼬기", "세리님의", "알고보니", "일식", "보니", "개방되어", 
        "두분", "풍미와", "손질하는", "쓰는", "한식에서", "있어", "공간에서", 
        "앞에", "미국인", "보유한", "젋은",
        "김이안은", "양조주를", "손내향미", "더라구요", "천재", "이자", "전문", "식당은",
        "해운대점", "집의", "막카이푸", "가진", "제이드의", "홍루몽은", "했는데", "께서",
        "철학과", "꿈이던", "운영하는", "서교고메", "셀럽", "들의", "딤섬", "리뷰에",
        "한국인", "나하나에", "선합니다", "전문적인", "여기", "가지", "호주출신", "여경래가",
        "조리기술", "호텔의", "근무한", "아울러", "푸드테크", "그동안", "굽는", "앞에서",
        "운영", "도쿄의", "이끄는", "스토랑은", "님이", "아내려는", "졸업한", "쿠킹톡",
        "곳에서는", "일본인", "대한", "숙련", "셀렙", "오너와", "노력하는", "마이",
        "특히", "당경력의", "운영되어", "셰프님이", "통한", "유유안", "이준은", "있어",
        "쌓은", "이블에서", "베이스는", "꼽으라면", "이자", "전문", "식당은"
    }

    cleaned_count = 0
    for row in rows:
        if len(row) < 15: continue
        media_type = row[1].strip()
        title = row[2].strip()
        place_name = row[3].strip()
        chef_name = row[5].strip()
        
        if media_type == 'guide' and '2025' in title:
            # Check for false positives
            is_bad = chef_name in black_list or len(chef_name) < 2 or len(chef_name) > 6
            
            # If chef name is same as or part of restaurant name (e.g. 유유안 at 유유안)
            if not is_bad and (chef_name in place_name or place_name in chef_name):
                is_bad = True
                
            # Logic: if it contains common suffixes like '은', '는', '이', '가', '의' at the end of a 4+ letter word
            if not is_bad and len(chef_name) >= 3:
                if chef_name.endswith(('은', '는', '이', '가', '의', '를', '을', '한', '된', '하는')):
                    is_bad = True

            # Additional logic: if it doesn't look like a name
            if not is_bad and not re.match(r'^[가-힣]+$', chef_name):
                is_bad = True

            if is_bad:
                # Revert to generic description
                tier_key = row[14].strip()
                tier_map = {"3star": "3스타", "2star": "2스타", "1star": "1스타", "bib": "빕 구르망", "michelin": "셀렉티드"}
                label = tier_map.get(tier_key, "미슐랭")
                new_val = f"미슐랭 {label} 레스토랑."
                if row[5] != new_val:
                    row[5] = new_val
                    cleaned_count += 1

    with open(csv_path, 'w', encoding='utf-8-sig', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(header)
        writer.writerows(rows)
        
    print(f"Cleaned up {cleaned_count} false positive chef names.")

if __name__ == "__main__":
    main()
