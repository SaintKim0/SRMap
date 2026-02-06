
import os
import glob
import pandas as pd

def merge_csvs():
    data_dir = r"d:\00_projects\02_TasteMap\doc\data"
    output_file = os.path.join(data_dir, "matzip.csv")
    
    # Get all csv files
    csv_files = glob.glob(os.path.join(data_dir, "*.csv"))
    
    # Filter out matzip.csv if it exists to avoid recursive merging
    csv_files = [f for f in csv_files if os.path.basename(f) != "matzip.csv"]
    
    print(f"Found {len(csv_files)} files to merge.")
    
    dfs = []
    for f in csv_files:
        try:
            df = pd.read_csv(f)
            dfs.append(df)
            print(f"Loaded {os.path.basename(f)} with {len(df)} rows.")
        except Exception as e:
            print(f"Error reading {f}: {e}")
    
    if dfs:
        merged_df = pd.concat(dfs, ignore_index=True)
        # Drop 'id' column if it exists as it might be duplicated indices from individual files
        # But looking at content, id seems to be just an index. 
        # I'll re-assign a new global id if needed, but for now just keeping it or dropping it depends on requirement.
        # User didn't ask to re-index, but concatenation usually messes up unique IDs if they are simple counters.
        # Let's just reset the index to be safe.
        
        merged_df.to_csv(output_file, index=False)
        print(f"Successfully merged {len(dfs)} files into {output_file}. Total rows: {len(merged_df)}")
    else:
        print("No CSV files found to merge.")

if __name__ == "__main__":
    merge_csvs()
