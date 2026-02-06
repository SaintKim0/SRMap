
import os
import requests
from dotenv import load_dotenv

# Load .env
load_dotenv(r"D:\00_projects\02_TasteMap\.env")

client_id = os.getenv("NAVER_MAP_CLIENT_ID")
client_secret = os.getenv("NAVER_MAP_CLIENT_SECRET")

print(f"ID: {client_id}")
print(f"Secret: {client_secret[:4]}...")

def test_search_api():
    print("\nTotal Testing Search API (Local)...")
    url = "https://openapi.naver.com/v1/search/local.json"
    headers = {
        "X-Naver-Client-Id": client_id,
        "X-Naver-Client-Secret": client_secret
    }
    params = {"query": "버거인", "display": 1}
    try:
        resp = requests.get(url, headers=headers, params=params)
        print(f"Status: {resp.status_code}")
        if resp.status_code == 200:
            print("Success!")
            print(resp.json())
        else:
            print("Fail:")
            print(resp.text)
    except Exception as e:
        print(f"Error: {e}")

def test_geocoding_api():
    print("\nTesting Geocoding API...")
    url = "https://naveropenapi.apigw.ntruss.com/map-geocode/v2/geocode"
    headers = {
        "X-NCP-APIGW-API-KEY-ID": client_id,
        "X-NCP-APIGW-API-KEY": client_secret
    }
    # Use a knwon address
    params = {"query": "경기도 성남시 분당구 불정로 6"} 
    try:
        resp = requests.get(url, headers=headers, params=params)
        print(f"Status: {resp.status_code}")
        if resp.status_code == 200:
            print("Success!")
            print(resp.json())
        else:
            print("Fail:")
            print(resp.text)
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    test_search_api()
    test_geocoding_api()
