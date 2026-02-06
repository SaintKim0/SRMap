
import pandas as pd
import os
import requests
import time
import json
from concurrent.futures import ThreadPoolExecutor, as_completed
try:
    from pyproj import Proj, transform, Transformer
    PYPROJ_AVAILABLE = True
except ImportError:
    PYPROJ_AVAILABLE = False
    print("Warning: pyproj not found. Coordinates might not be converted correctly if source is TM128.")

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
    except Exception as e:
        # print(f"Error fetching data for {query}: {e}")
        pass
    return None



# Global Transformer (Not needed anymore, but keep structure simple)
TRANSFORMER = None
PYPROJ_AVAILABLE = False # Force false to skip legacy checks

def convert_katech_to_wgs84_proj(mapx, mapy):
    # Actually Naver Search API returns WGS84 * 1e7
    try:
        mx = float(mapx) / 10000000.0
        my = float(mapy) / 10000000.0
        return my, mx # Lat, Lon
    except Exception:
        return None, None

def process_row(row, index):
    # Check if address is missing or empty
    if not (pd.isna(row['address']) or str(row['address']).strip() == ""):
        return None # Already has address, skip

    desc = str(row['description'])
    place_name = str(row['place_name'])
    
    query = place_name
    if desc:
        parts = desc.split()
        if len(parts) > 0:
            area_guess = parts[0]
            query = f"{area_guess} {place_name}"
            
    info = get_location_info(query)
    
    result = {'index': index}
    
    if info:
        clean_address = info.get('address', '').replace('<b>', '').replace('</b>', '')
        road_address = info.get('roadAddress', '').replace('<b>', '').replace('</b>', '')
        phone = info.get('telephone', '')
        mapx = info.get('mapx')
        mapy = info.get('mapy')
        
        final_addr = road_address if road_address else clean_address
        
        # Use simple coordinate conversion (since transformer is global now)
        lat, lon = None, None
        if mapx and mapy:
            lat, lon = convert_katech_to_wgs84_proj(mapx, mapy)
            
        result['address'] = final_addr
        result['phone'] = phone
        result['latitude'] = lat
        result['longitude'] = lon
        result['found'] = True
    else:
        result['found'] = False
        
    return result

def fill_csv():
    file_path = r"d:\00_projects\02_TasteMap\doc\data\matzip.csv"
    
    if not os.path.exists(file_path):
        print(f"File not found: {file_path}")
        return

    df = pd.read_csv(file_path)
    
    for col in ['address', 'latitude', 'longitude', 'phone']:
        if col not in df.columns:
            df[col] = ""

    if not PYPROJ_AVAILABLE:
        print("CRITICAL: pyproj is missing.")

    rows_to_process = []
    import numpy as np
    for index, row in df.iterrows():
        # Condition: Address missing OR coords missing OR coords are inf
        addr_missing = pd.isna(row['address']) or str(row['address']).strip() == ""
        
        lat = row.get('latitude', '')
        lon = row.get('longitude', '')
        
        # Check for inf/nan/empty in coords
        coords_invalid = False
        try:
            if pd.isna(lat) or lat == "" or str(lat) == 'inf' or float(lat) == float('inf'):
                coords_invalid = True
        except:
             coords_invalid = True
             
        if addr_missing or coords_invalid:
            rows_to_process.append((index, row))
            
    print(f"Targeting {len(rows_to_process)} empty rows.")
    
    updated_count = 0
    with ThreadPoolExecutor(max_workers=50) as executor:
        futures = {executor.submit(process_row, row, index): index for index, row in rows_to_process}
        
        for i, future in enumerate(as_completed(futures)):
            res = future.result()
            if res and res['found']:
                idx = res['index']
                df.at[idx, 'address'] = res['address']
                df.at[idx, 'phone'] = res['phone']
                if res['latitude']: df.at[idx, 'latitude'] = res['latitude']
                if res['longitude']: df.at[idx, 'longitude'] = res['longitude']
                updated_count += 1
            
            if (i + 1) % 100 == 0:
                print(f"Progress: {i + 1}/{len(rows_to_process)} completed. (Found: {updated_count})")
                if (i + 1) % 500 == 0:
                    print("Saving checkpoint...")
                    df.to_csv(file_path, index=False)

    df.to_csv(file_path, index=False)
    print(f"Done. Updated {updated_count} rows.")

if __name__ == "__main__":
    fill_csv()
