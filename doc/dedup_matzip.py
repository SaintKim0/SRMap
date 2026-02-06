
import pandas as pd
import os

def dedup_csv():
    file_path = r"d:\00_projects\02_TasteMap\doc\data\matzip.csv"
    
    if not os.path.exists(file_path):
        print(f"File not found: {file_path}")
        return

    try:
        df = pd.read_csv(file_path)
        original_count = len(df)
        
        # Deduplicate based on title and name, keeping the first occurrence
        df_deduplicated = df.drop_duplicates(subset=['title', 'name'], keep='first')
        
        new_count = len(df_deduplicated)
        removed_count = original_count - new_count
        
        df_deduplicated.to_csv(file_path, index=False)
        
        print(f"Deduplication complete.")
        print(f"Original rows: {original_count}")
        print(f"New rows: {new_count}")
        print(f"Removed rows: {removed_count}")
        
    except Exception as e:
        print(f"Error processing file: {e}")

if __name__ == "__main__":
    dedup_csv()
