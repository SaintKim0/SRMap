
import pandas as pd
import os
import requests
import time
import json
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
        resp = requests.get(url, headers=headers, params=params)
        if resp.status_code == 200:
            data = resp.json()
            if data['items']:
                item = data['items'][0]
                return item
    except Exception as e:
        print(f"Error fetching data for {query}: {e}")
    return None

def convert_katech_to_wgs84(mapx, mapy):
    if not PYPROJ_AVAILABLE or not mapx or not mapy:
        return None, None
    
    try:
        # Naver KATECH (TM128) assumption
        # Proj string for KATECH (often approximated)
        # Using standard KATECH/TM128 definition
        # mapx, mapy from Naver are usually integers (multiplied by 10 or similar? No, usually generic KATECH)
        # However, older Naver API returned integers. Let's inspect raw values.
        # If they are integers like 309999, 552000, they are TM128.
        # Note: Using explicit proj strings is safer.
        
        # Define projections
        # TM128 System (KATECH)
        proj_katech = Proj('+proj=tmerc +lat_0=38 +lon_0=128 +k=0.9999 +x_0=400000 +y_0=600000 +ellps=bessel +units=m +no_defs +towgs84=-115.80,474.99,674.11,1.16,-2.31,-1.63,6.43')
        # WGS84
        proj_wgs84 = Proj(proj='latlong', datum='WGS84')
        
        transformer = Transformer.from_proj(proj_katech, proj_wgs84)
        
        # Naver Search API usually returns coordinates as integer strings?
        # Let's ensure they are floats
        mx = float(mapx)
        my = float(mapy)
        
        lon, lat = transformer.transform(mx, my)
        return lat, lon
    except Exception as e:
        print(f"Conversion error: {e}")
        return None, None

def fill_csv():
    file_path = r"d:\00_projects\02_TasteMap\doc\data\matzip.csv"
    
    if not os.path.exists(file_path):
        print(f"File not found: {file_path}")
        return

    df = pd.read_csv(file_path)
    
    # Check if necessary columns exist, if not create them
    for col in ['address', 'latitude', 'longitude', 'phone']:
        if col not in df.columns:
            df[col] = "" # Should already exist from previous steps

    if not PYPROJ_AVAILABLE:
        print("CRITICAL: pyproj is missing. Coordinate conversion will be skipped/mocked.")

    updated_count = 0
    
    for index, row in df.iterrows():
        # Check if address is missing. If header exists but currently empty string or nan
        if pd.isna(row['address']) or str(row['address']).strip() == "":
            
            # Construct Query: e.g. "숙대입구 버거인"
            # Description often has "{area} {place_type}" e.g., "숙대입구 수제버거"
            # Place name is "버거인"
            # Best query: "{place_name}" or "{area} {place_name}"?
            # description might be "숙대입구 수제버거". 
            # Place Name "버거인".
            # Query "숙대입구 버거인" is likely good.
            
            # Parse area from description if possible, or just use description keywords?
            # Let's try combining description(area part) + place_name if possible.
            # But the user said description holds "area + place_type".
            # Ex: "숙대입구 수제버거". 
            # We can extract "숙대입구" (first word) + "버거인".
            
            desc = str(row['description'])
            place_name = str(row['place_name'])
            
            query = place_name
            if desc:
                parts = desc.split()
                if len(parts) > 0:
                     # Heuristic: First word of description is often the area
                    area_guess = parts[0]
                    query = f"{area_guess} {place_name}"
            
            print(f"Processing ({index+1}/{len(df)}): {query}")
            
            info = get_location_info(query)
            
            if info:
                # Naver API returns html tags in title/address sometimes.
                clean_address = info.get('address', '').replace('<b>', '').replace('</b>', '')
                road_address = info.get('roadAddress', '').replace('<b>', '').replace('</b>', '')
                phone = info.get('telephone', '')
                mapx = info.get('mapx')
                mapy = info.get('mapy')
                
                # Prefer road address
                final_addr = road_address if road_address else clean_address
                
                # Convert coords
                lat, lon = None, None
                if mapx and mapy and PYPROJ_AVAILABLE:
                    lat, lon = convert_katech_to_wgs84(mapx, mapy)
                
                # Update DataFrame
                df.at[index, 'address'] = final_addr
                df.at[index, 'phone'] = phone
                if lat: df.at[index, 'latitude'] = lat
                if lon: df.at[index, 'longitude'] = lon
                
                updated_count += 1
            
            # Rate limiting (conservative)
            time.sleep(0.1)
            
            # Save incrementally every 100 rows
            if updated_count % 100 == 0:
                print(f"Saving progress... ({updated_count} updated)")
                df.to_csv(file_path, index=False)

    # Final save
    df.to_csv(file_path, index=False)
    print(f"Done. Updated {updated_count} rows.")

if __name__ == "__main__":
    fill_csv()
