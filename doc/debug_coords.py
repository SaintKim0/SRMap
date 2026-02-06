
import requests
from pyproj import Proj, Transformer

CLIENT_ID = "bUpmGhUz3eqK9pXC5NGR"
CLIENT_SECRET = "wwlhTbb_g4"

def debug_coords():
    url = "https://openapi.naver.com/v1/search/local.json"
    headers = {
        "X-Naver-Client-Id": CLIENT_ID,
        "X-Naver-Client-Secret": CLIENT_SECRET
    }
    query = "숙대입구 버거인"
    params = {"query": query, "display": 1}
    
    resp = requests.get(url, headers=headers, params=params)
    data = resp.json()
    item = data['items'][0]
    
    print("Raw Item:", item)
    mapx = item['mapx']
    mapy = item['mapy']
    print(f"MapX: {mapx} (Type: {type(mapx)})")
    print(f"MapY: {mapy} (Type: {type(mapy)})")
    
    # Try Conversion
    try:
        proj_katech = Proj('+proj=tmerc +lat_0=38 +lon_0=128 +k=0.9999 +x_0=400000 +y_0=600000 +ellps=bessel +units=m +no_defs +towgs84=-115.80,474.99,674.11,1.16,-2.31,-1.63,6.43')
        proj_wgs84 = Proj(proj='latlong', datum='WGS84')
        transformer = Transformer.from_proj(proj_katech, proj_wgs84)
        
        mx = float(mapx)
        my = float(mapy)
        lon, lat = transformer.transform(mx, my)
        print(f"Converted Lat: {lat}, Lon: {lon}")
    except Exception as e:
        print(f"Conversion Error: {e}")

if __name__ == "__main__":
    debug_coords()
