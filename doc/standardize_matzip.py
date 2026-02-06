
import pandas as pd
import os

def standardize_csv():
    file_path = r"d:\00_projects\02_TasteMap\doc\data\matzip.csv"
    
    if not os.path.exists(file_path):
        print(f"File not found: {file_path}")
        return

    try:
        df = pd.read_csv(file_path)
        print("Original columns:", df.columns.tolist())
        
        # 1. id -> no
        # 2. sector -> media_type (Using media_type to match locations.csv, assuming media_field was a typo)
        # 3. title -> title (no change)
        # 4. name -> place_name
        # 5. type -> place_type
        # 6. address -> address (no change)
        # 7. lat, lng -> latitude, longitude
        
        rename_map = {
            'id': 'no',
            'sector': 'media_type',
            'name': 'place_name',
            'type': 'place_type',
            'lat': 'latitude',
            'lng': 'longitude'
        }
        
        df.rename(columns=rename_map, inplace=True)
        
        # 2. Set all values in media_type to 'show'
        if 'media_type' in df.columns:
            df['media_type'] = 'show'
            
        # 8. Remove user_score, review_cnt
        cols_to_drop = ['user_score', 'review_cnt']
        # Check if columns exist before dropping to avoid errors if run multiple times
        cols_to_drop = [c for c in cols_to_drop if c in df.columns]
        
        if cols_to_drop:
            df.drop(columns=cols_to_drop, inplace=True)
            print(f"Dropped columns: {cols_to_drop}")
            
        df.to_csv(file_path, index=False)
        
        print("Standardization complete.")
        print("New columns:", df.columns.tolist())
        
    except Exception as e:
        print(f"Error processing file: {e}")

if __name__ == "__main__":
    standardize_csv()
