import requests
import os
from dotenv import load_dotenv

load_dotenv()

NAVER_MAP_CLIENT_ID = os.getenv('NAVER_MAP_CLIENT_ID') or os.getenv('NAVER_SEARCH_CLIENT_ID')
NAVER_MAP_CLIENT_SECRET = os.getenv('NAVER_MAP_CLIENT_SECRET') or os.getenv('NAVER_SEARCH_CLIENT_SECRET')

def geocode_address(address):
    """Naver Maps Geocoding API를 사용하여 주소를 위도/경도로 변환"""
    url = "https://maps.apigw.ntruss.com/map-geocode/v2/geocode"
    
    headers = {
        "x-ncp-apigw-api-key-id": NAVER_MAP_CLIENT_ID,
        "x-ncp-apigw-api-key": NAVER_MAP_CLIENT_SECRET,
        "Accept": "application/json"
    }
    
    params = {
        "query": address
    }
    
    try:
        response = requests.get(url, headers=headers, params=params)
        
        if response.status_code != 200:
            print(f"  [X] API 오류 ({response.status_code})")
            return None, None
        
        data = response.json()
        
        if data.get('status') == 'OK' and data.get('addresses'):
            result = data['addresses'][0]
            lat = result.get('y', '')
            lng = result.get('x', '')
            return lat, lng
        else:
            print(f"  [!] Geocoding 실패")
            return None, None
            
    except Exception as e:
        print(f"  [X] 예외 발생: {str(e)}")
        return None, None

# 3개 주소 geocoding
addresses = {
    "제주등대아구찜": "제주 제주시 한림읍 한림해안로 145-2",
    "아지트": "강원 속초시 영랑해안길 133-7",
    "원조가고파안면도쭈꾸미": "인천 동구 제물량로 346-1"
}

print("=" * 60)
print("3개 레스토랑 Geocoding")
print("=" * 60)

for name, address in addresses.items():
    print(f"\n[{name}]")
    print(f"  주소: {address}")
    lat, lng = geocode_address(address)
    if lat and lng:
        print(f"  ✅ 좌표: ({lat}, {lng})")
    else:
        print(f"  ❌ 실패")

print("\n" + "=" * 60)
