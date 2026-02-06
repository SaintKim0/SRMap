import csv
from datetime import datetime

# 이전에 read_url_content로 가져온 데이터를 기반으로 직접 작성
# 실제 다이닝코드 페이지에서 확인된 식당 정보

restaurants_data = [
    {
        "name": "보림숯불갈비",
        "category": "돼지갈비",
        "address": "경기도 이천시 중리천로72번길 23",
        "phone": "0507-1400-8738",
        "lat": 37.277844,
        "lng": 127.445342,
        "user_score": 4.2,
        "area": "이천"
    },
    {
        "name": "맷돌우리콩감자탕 본점",
        "category": "감자탕, 콩비지감자탕",
        "address": "경기도 파주시 숲속노을로 330",
        "phone": "0507-1354-9445",
        "lat": 37.7287166,
        "lng": 126.7073858,
        "user_score": 4.2,
        "area": "파주"
    },
    {
        "name": "이라면",
        "category": "라면, 라볶이",
        "address": "경기도 수원시 장안구 서부로2106번길 18",
        "phone": "031-291-7611",
        "lat": 37.2970589,
        "lng": 126.9714449,
        "user_score": 3.5,
        "area": "수원"
    },
    {
        "name": "황주생고기",
        "category": "한우, 소고기",
        "address": "경기도 동두천시 생연로 142",
        "phone": "031-865-2026",
        "lat": 37.9050798,
        "lng": 127.0519517,
        "user_score": 3.7,
        "area": "동두천"
    },
    {
        "name": "해장촌",
        "category": "해장국, 선지",
        "address": "경기도 화성시 효행로 509",
        "phone": "031-223-2922",
        "lat": 37.2070929,
        "lng": 126.9892125,
        "user_score": 3.8,
        "area": "화성"
    },
    {
        "name": "빨간세상라면학교",
        "category": "라면, 매운라면",
        "address": "경기도 의정부시 시민로 83 광장타워 1층",
        "phone": "031-837-3334",
        "lat": 37.7389401,
        "lng": 127.0445675,
        "user_score": 3.9,
        "area": "의정부"
    },
    {
        "name": "오뎅식당",
        "category": "부대찌개, 부대볶음",
        "address": "경기도 의정부시 호국로1309번길 7",
        "phone": "031-842-0423",
        "lat": 37.7440927,
        "lng": 127.0494505,
        "user_score": 4.1,
        "area": "의정부"
    },
    {
        "name": "주양돈까스나라",
        "category": "돈까스",
        "address": "경기도 하남시 미사강변한강로334번길 20",
        "phone": "031-795-5393",
        "lat": 37.5605854,
        "lng": 127.1996333,
        "user_score": 4.8,
        "area": "하남미사"
    },
    {
        "name": "어랑추",
        "category": "집밥, 고등어조림",
        "address": "경기도 구리시 동구릉로 145",
        "phone": "031-568-6866",
        "lat": 37.611804,
        "lng": 127.1374732,
        "user_score": 4.4,
        "area": "구리"
    },
    {
        "name": "삼도갈비",
        "category": "돼지갈비",
        "address": "경기도 부천시 원미구 상이로85번길 32",
        "phone": "032-324-8600",
        "lat": 37.4966717,
        "lng": 126.7425175,
        "user_score": 3.8,
        "area": "부천시"
    },
    {
        "name": "참마루한식뷔페",
        "category": "한식뷔페",
        "address": "경기도 고양시 일산동구 성현로 47 1층",
        "phone": "0507-1416-7741",
        "lat": 37.7089786,
        "lng": 126.7925177,
        "user_score": 3.9,
        "area": "일산"
    },
    {
        "name": "쌍쓰리 숯불갈비 김치삼겹살",
        "category": "삼겹살, 숯불갈비삼겹살",
        "address": "경기도 고양시 일산동구 강송로73번길 7-17 1층 전부호",
        "phone": "0507-1423-8091",
        "lat": 37.6459243,
        "lng": 126.7906811,
        "user_score": 4.2,
        "area": "일산"
    },
    {
        "name": "옹기골만찬",
        "category": "쌈밥, 우렁",
        "address": "경기도 포천시 일동면 수입로 12 옹기골만찬",
        "phone": "0507-1353-4077",
        "lat": 37.969862,
        "lng": 127.3279404,
        "user_score": 4.2,
        "area": "포천"
    },
    {
        "name": "추억의연탄집",
        "category": "고추장삼겹살, 돼지갈비",
        "address": "경기도 성남시 분당구 미금일로74번길 32",
        "phone": "031-719-9133",
        "lat": 37.3485737,
        "lng": 127.1117375,
        "user_score": 2.5,
        "area": "미금역"
    },
    {
        "name": "출렁다리웰빙건강쌈밥 마장호수본점",
        "category": "쌈밥, 제육",
        "address": "경기도 파주시 광탄면 기산로186번길 8",
        "phone": "0507-1336-6271",
        "lat": 37.7754206,
        "lng": 126.9179179,
        "user_score": 4.5,
        "area": "파주"
    },
    {
        "name": "대장군집",
        "category": "돼지부속, 갈매기살",
        "address": "경기도 파주시 조리읍 통일로 311",
        "phone": "031-957-3199",
        "lat": 37.7434171,
        "lng": 126.8095684,
        "user_score": 5.0,
        "area": "파주"
    },
    {
        "name": "소풍",
        "category": "보리굴비, 보리굴비정식",
        "address": "경기도 고양시 덕양구 행주로15번길 62",
        "phone": "0507-1403-7415",
        "lat": 37.6000416,
        "lng": 126.8261265,
        "user_score": 3.8,
        "area": "행주산성"
    },
    {
        "name": "진흥관",
        "category": "짜장면, 짬뽕",
        "address": "경기도 김포시 양촌읍 석모로 57",
        "phone": "031-984-9911",
        "lat": 37.6527734,
        "lng": 126.6439681,
        "user_score": 3.5,
        "area": "김포"
    },
    {
        "name": "궁중삼계탕",
        "category": "삼계탕, 인삼주",
        "address": "경기도 안산시 상록구 석호공원로 69",
        "phone": "031-502-9090",
        "lat": 37.3015828,
        "lng": 126.8510874,
        "user_score": 4.8,
        "area": "안산"
    },
    {
        "name": "바위꽃",
        "category": "굴요리, 굴정식",
        "address": "경기도 용인시 처인구 중부대로 1180 월매밥상",
        "phone": "031-323-1535",
        "lat": 37.2379586,
        "lng": 127.1762007,
        "user_score": 2.8,
        "area": "용인시청"
    }
]


def save_to_csv(restaurants, filename='tasty_boys.csv'):
    """CSV 파일로 저장 (black_white_season1.csv 형식에 맞춤)"""
    
    current_date = datetime.now().strftime('%Y-%m-%d')
    
    with open(filename, 'w', newline='', encoding='utf-8') as csvfile:
        writer = csv.writer(csvfile, quoting=csv.QUOTE_ALL)
        
        for restaurant in restaurants:
            row = [
                "0",  # id
                "show",  # sector
                "맛있는녀석들",  # title
                restaurant['name'],  # name
                "restaurant",  # type
                "",  # chef (빈 값)
                "",  # 빈 필드
                "",  # 빈 필드
                "",  # 빈 필드
                restaurant['address'],  # address
                str(restaurant['lat']),  # latitude
                str(restaurant['lng']),  # longitude
                "",  # 빈 필드
                current_date  # date
            ]
            writer.writerow(row)
    
    print(f"✅ {len(restaurants)}개 식당 데이터를 '{filename}' 파일로 저장했습니다.")


def main():
    print("=" * 60)
    print("다이닝코드 '맛있는녀석들' 경기도 식당 데이터")
    print("=" * 60)
    
    output_file = 'd:/00_projects/02_TasteMap/doc/tasty_boys.csv'
    save_to_csv(restaurants_data, output_file)
    
    # 샘플 데이터 출력
    print(f"\n총 {len(restaurants_data)}개 식당 데이터 저장 완료!")
    print("\n[샘플 데이터]")
    for i, restaurant in enumerate(restaurants_data[:5], 1):
        print(f"{i}. {restaurant['name']}")
        print(f"   주소: {restaurant['address']}")
        print(f"   카테고리: {restaurant['category']}")
        print(f"   평점: {restaurant['user_score']}")
        print()


if __name__ == "__main__":
    main()
