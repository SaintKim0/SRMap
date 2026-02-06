
import pandas as pd
import os
import numpy as np

def add_columns():
    file_path = r"d:\00_projects\02_TasteMap\doc\data\matzip.csv"
    
    if not os.path.exists(file_path):
        print(f"File not found: {file_path}")
        return

    try:
        df = pd.read_csv(file_path)
        print("Original columns:", df.columns.tolist())
        
        # Define new columns
        new_cols = ['opening_hours', 'break_time', 'closed_days']
        
        # Add new columns with empty strings
        for col in new_cols:
            df[col] = "" # or np.nan if preferred, but empty string is often safer for CSV viewing
            
        # Reorder columns to insert them after 'description'
        if 'description' in df.columns:
            cols = df.columns.tolist()
            desc_index = cols.index('description')
            
            # Remove new cols from the end (where they were appended)
            existing_cols = [c for c in cols if c not in new_cols]
            
            # Construct new order
            new_order = existing_cols[:desc_index+1] + new_cols + existing_cols[desc_index+1:]
            df = df[new_order]
        else:
            print("Warning: 'description' column not found. Appending new columns at the end.")
            
        df.to_csv(file_path, index=False)
        
        print("Columns added.")
        print("New columns:", df.columns.tolist())
        
    except Exception as e:
        print(f"Error processing file: {e}")

if __name__ == "__main__":
    add_columns()
