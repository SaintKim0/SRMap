
import pandas as pd
import os

def reindex_csv():
    file_path = r"d:\00_projects\02_TasteMap\doc\data\matzip.csv"
    
    if not os.path.exists(file_path):
        print(f"File not found: {file_path}")
        return

    try:
        df = pd.read_csv(file_path)
        
        # Reset 'id' column to be sequential starting from 1
        df['id'] = range(1, len(df) + 1)
        
        df.to_csv(file_path, index=False)
        
        print(f"Re-indexing complete.")
        print(f"Total rows updated: {len(df)}")
        print(f"ID range: {df['id'].min()} to {df['id'].max()}")
        
    except Exception as e:
        print(f"Error processing file: {e}")

if __name__ == "__main__":
    reindex_csv()
