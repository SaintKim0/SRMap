
import pandas as pd
import os

def reindex_locations():
    file_path = r"d:\00_projects\02_TasteMap\doc\data - 복사본\locations.csv"
    
    if not os.path.exists(file_path):
        print(f"File not found: {file_path}")
        return

    try:
        df = pd.read_csv(file_path)
        print(f"Loaded {len(df)} rows.")
        
        # Create sequential IDs starting from 1
        new_ids = range(1, len(df) + 1)
        df['no'] = new_ids
        
        df.to_csv(file_path, index=False)
        print(f"Re-indexing complete. IDs set from 1 to {len(df)}.")
        
        # Verify
        print("First 5 IDs:", df['no'].head(5).tolist())
        print("Last 5 IDs:", df['no'].tail(5).tolist())
        
    except Exception as e:
        print(f"Error processing file: {e}")

if __name__ == "__main__":
    reindex_locations()
