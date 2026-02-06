
import pandas as pd
import os
import numpy as np
import shutil

def merge_files():
    matzip_path = r"d:\00_projects\02_TasteMap\doc\data\matzip.csv"
    locations_path = r"d:\00_projects\02_TasteMap\doc\data - 복사본\locations.csv"
    
    # OUTPUT PATH: Overwrite locations.csv?
    # User said "merge into locations.csv".
    output_path = locations_path
    
    if not os.path.exists(matzip_path):
        print(f"Error: {matzip_path} not found.")
        return
        
    if not os.path.exists(locations_path):
        print(f"Error: {locations_path} not found.")
        return
    
    # Backup locations.csv
    backup_path = locations_path.replace(".csv", "_backup_before_merge.csv")
    try:
         shutil.copy2(locations_path, backup_path)
         print(f"Backed up locations.csv to {backup_path}")
    except Exception as e:
        print(f"Warning: Could not backup locations.csv: {e}")
            
    try:
        df_matzip = pd.read_csv(matzip_path)
        df_locations = pd.read_csv(locations_path)
        
        print(f"Loaded matzip: {len(df_matzip)} rows")
        print(f"Loaded locations: {len(df_locations)} rows")
        
        # 1. Clean matzip inf values and handle missing coords
        # Replace 'inf', '-inf' with NaN
        df_matzip.replace([np.inf, -np.inf], np.nan, inplace=True)
        df_matzip.replace(['inf', '-inf'], np.nan, inplace=True)
        
        # Convert lat/lon to numeric
        df_matzip['latitude'] = pd.to_numeric(df_matzip['latitude'], errors='coerce')
        df_matzip['longitude'] = pd.to_numeric(df_matzip['longitude'], errors='coerce')
        
        # Filter: Drop rows where lat or lon is NaN
        original_count = len(df_matzip)
        df_matzip_filtered = df_matzip.dropna(subset=['latitude', 'longitude'])
        
        dropped_count = original_count - len(df_matzip_filtered)
        print(f"Filtered out {dropped_count} rows with missing/invalid coordinates.")
        print(f"Valid rows to merge: {len(df_matzip_filtered)}")

        if len(df_matzip_filtered) == 0:
            print("No valid data to merge.")
            return
            
        # 2. Re-index 'no'
        # Ensure locations 'no' is int
        df_locations['no'] = pd.to_numeric(df_locations['no'], errors='coerce').fillna(0).astype(int)
        max_no = df_locations['no'].max()
        print(f"Max ID in current locations: {max_no}")
        
        # Reset index of filtered matzip to ensure clean range assignment
        df_matzip_filtered = df_matzip_filtered.reset_index(drop=True)
        
        # Create new IDs
        start_id = max_no + 1
        new_ids = range(start_id, start_id + len(df_matzip_filtered))
        df_matzip_filtered['no'] = new_ids
        print(f"Assigned new IDs: {new_ids[0]} ~ {new_ids[-1]}")
        
        # 3. Align Columns
        # Ensure column order matches locations.csv
        # If columns missing in matzip, add them as empty
        for col in df_locations.columns:
            if col not in df_matzip_filtered.columns:
                df_matzip_filtered[col] = "" # e.g. if any specific col missing
        
        # Select only columns present in locations.csv to match structure (ignore extras in matzip if any, though we aligned them)
        # Or better: keep columns from locations.csv
        df_matzip_final = df_matzip_filtered[df_locations.columns]
        
        # 4. Append
        df_merged = pd.concat([df_locations, df_matzip_final], ignore_index=True)
        
        # 5. Save
        df_merged.to_csv(output_path, index=False)
        print(f"Merge Complete. Total rows: {len(df_merged)}")
        print(f"Saved to: {output_path}")
        
    except Exception as e:
        print(f"Error merging files: {e}")

if __name__ == "__main__":
    merge_files()
