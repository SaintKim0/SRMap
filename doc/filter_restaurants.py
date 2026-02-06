
import pandas as pd
import os
import shutil

def filter_restaurants():
    file_path = r"d:\00_projects\02_TasteMap\doc\data - 복사본\locations.csv"
    
    if not os.path.exists(file_path):
        print(f"File not found: {file_path}")
        return

    # Backup
    backup_path = file_path.replace(".csv", "_backup_before_filter.csv")
    try:
        shutil.copy2(file_path, backup_path)
        print(f"Backed up to {backup_path}")
    except Exception as e:
        print(f"Backup failed: {e}")

    try:
        df = pd.read_csv(file_path)
        print(f"Original rows: {len(df)}")
        
        # Filter
        # User said "restaurant" (spelled restraunt in prompt, but data has restaurant)
        # I'll check for 'restaurant' ignoring case just to be safe
        df_filtered = df[df['place_type'].str.lower() == 'restaurant'].copy()
        
        print(f"Filtered rows (restaurant only): {len(df_filtered)}")
        
        # Re-index
        df_filtered['no'] = range(1, len(df_filtered) + 1)
        
        # Save
        df_filtered.to_csv(file_path, index=False)
        print("File updated and re-indexed.")
        
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    filter_restaurants()
