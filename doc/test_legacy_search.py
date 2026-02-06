
import requests

client_id = "bUpmGhUz3eqK9pXC5NGR"
client_secret = "wwlhTbb_g4"

print(f"Testing Legacy Keys ID: {client_id}")

def test_search_api():
    url = "https://openapi.naver.com/v1/search/local.json"
    headers = {
        "X-Naver-Client-Id": client_id,
        "X-Naver-Client-Secret": client_secret
    }
    params = {"query": "비트코인", "display": 1} # Generic query
    try:
        resp = requests.get(url, headers=headers, params=params)
        print(f"Status: {resp.status_code}")
        if resp.status_code == 200:
            print("Success!")
            # print(resp.json()) 
        else:
            print("Fail:")
            print(resp.text)
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    test_search_api()
