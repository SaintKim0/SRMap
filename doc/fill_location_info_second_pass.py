
import pandas as pd
import os
import requests
import json
import numpy as np
from concurrent.futures import ThreadPoolExecutor, as_completed

# Naver API Keys (Legacy Search Keys)
CLIENT_ID = "bUpmGhUz3eqK9pXC5NGR"
CLIENT_SECRET = "wwlhTbb_g4"

def get_location_info(query):
    url = "https://openapi.naver.com/v1/search/local.json"
    headers = {
        "X-Naver-Client-Id": CLIENT_ID,
        "X-Naver-Client-Secret": CLIENT_SECRET
    }
    params = {"query": query, "display": 1}
    
    try:
        resp = requests.get(url, headers=headers, params=params, timeout=5)
        if resp.status_code == 200:
            data = resp.json()
            if data['items']:
                item = data['items'][0]
                return item
    except Exception:
        pass
    return None

def process_row_second_pass(row, index):
    # Check if address is missing or invalid coords
    addr_missing = pd.isna(row['address']) or str(row['address']).strip() == ""
    lat = row.get('latitude', '')
    coords_invalid = False
    try:
        if pd.isna(lat) or lat == "" or str(lat) == 'inf' or float(lat) == float('inf'):
            coords_invalid = True
    except:
         coords_invalid = True
         
    if not (addr_missing or coords_invalid):
        return None # Already has valid info
        
    place_name = str(row['place_name'])
    title = str(row['title']) # Program name
    
    # Strategy 1: Just place_name
    # Strategy 2: Title + place_name
    queries = [place_name, f"{title} {place_name}"]
    
    info = None
    used_query = ""
    
    for q in queries:
        info = get_location_info(q)
        if info:
            used_query = q
            break
            
    result = {'index': index, 'found': False}
    
    if info:
        clean_address = info.get('address', '').replace('<b>', '').replace('</b>', '')
        road_address = info.get('roadAddress', '').replace('<b>', '').replace('</b>', '')
        phone = info.get('telephone', '')
        mapx = info.get('mapx')
        mapy = info.get('mapy')
        
        final_addr = road_address if road_address else clean_address
        
        lat, lon = None, None
        try:
             # Naver Search API returns WGS84 * 1e7
            if mapx and mapy:
                lon = float(mapx) / 10000000.0
                lat = float(mapy) / 10000000.0
        except:
            pass
            
        result['address'] = final_addr
        result['phone'] = phone
        result['latitude'] = lat
        result['longitude'] = lon
        result['found'] = True
        result['query'] = used_query
    
    return result

def fill_csv_second_pass():
    file_path = r"d:\00_projects\02_TasteMap\doc\data\matzip.csv"
    
    if not os.path.exists(file_path):
        print(f"File not found: {file_path}")
        return

    df = pd.read_csv(file_path)
    
    # Treat 'inf' as NaN for processing
    df.replace([np.inf, -np.inf, "inf", "-inf"], np.nan, inplace=True)

    rows_to_process = []
    for index, row in df.iterrows():
        addr_missing = pd.isna(row['address']) or str(row['address']).strip() == ""
        # Also include rows where we have address but coordinates are missing/nan
        lat = row.get('latitude')
        coords_missing = pd.isna(lat) or lat == ""
        
        if addr_missing or coords_missing:
            rows_to_process.append((index, row))
            
    print(f"Task: Second Pass. Targeting {len(rows_to_process)} rows.")
    
    updated_count = 0
    with ThreadPoolExecutor(max_workers=50) as executor:
        futures = {executor.submit(process_row_second_pass, row, index): index for index, row in rows_to_process}
        
        for i, future in enumerate(as_completed(futures)):
            res = future.result()
            if res and res['found']:
                idx = res['index']
                df.at[idx, 'address'] = res['address']
                df.at[idx, 'phone'] = res['phone']
                if res['latitude']: df.at[idx, 'latitude'] = res['latitude']
                if res['longitude']: df.at[idx, 'longitude'] = res['longitude']
                updated_count += 1
            
            if (i + 1) % 50 == 0:
                print(f"Progress: {i + 1}/{len(rows_to_process)} completed. (Found: {updated_count})")
                
    df.to_csv(file_path, index=False)
    print(f"Second Pass Done. Updated {updated_count} rows.")

if __name__ == "__main__":
    fill_csv_second_pass()
