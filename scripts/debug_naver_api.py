import csv
import requests
import time
import os
from dotenv import load_dotenv

load_dotenv()

NAVER_SEARCH_CLIENT_ID = os.getenv('NAVER_SEARCH_CLIENT_ID')
NAVER_SEARCH_CLIENT_SECRET = os.getenv('NAVER_SEARCH_CLIENT_SECRET')

def search_place(query):
    url = "https://openapi.naver.com/v1/search/local.json"
    headers = {
        "X-Naver-Client-Id": NAVER_SEARCH_CLIENT_ID,
        "X-Naver-Client-Secret": NAVER_SEARCH_CLIENT_SECRET
    }
    params = {"query": query, "display": 1}
    try:
        response = requests.get(url, headers=headers, params=params)
        if response.status_code == 200:
            return response.json()
    except Exception:
        pass
    return None

def search_web(query):
    url = "https://openapi.naver.com/v1/search/webkr.json"
    headers = {
        "X-Naver-Client-Id": NAVER_SEARCH_CLIENT_ID,
        "X-Naver-Client-Secret": NAVER_SEARCH_CLIENT_SECRET
    }
    params = {"query": query, "display": 3}
    try:
        response = requests.get(url, headers=headers, params=params)
        if response.status_code == 200:
            return response.json()
    except Exception:
        pass
    return None

def main():
    # Test with one place that has '정보없음' for phone
    # 부흥식육식당
    query = "상주 부흥식육식당"
    res_local = search_place(query)
    print("Local Response for 부흥식육식당:")
    import json
    print(json.dumps(res_local, indent=2, ensure_ascii=False))

    res_web = search_web(query + " 영업시간 전화번호")
    print("\nWeb Response for 부흥식육식당:")
    print(json.dumps(res_web, indent=2, ensure_ascii=False))

if __name__ == "__main__":
    main()
