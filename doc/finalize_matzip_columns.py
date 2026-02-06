
import pandas as pd
import os

def finalize_columns():
    file_path = r"d:\00_projects\02_TasteMap\doc\data\matzip.csv"
    
    if not os.path.exists(file_path):
        print(f"File not found: {file_path}")
        return

    try:
        df = pd.read_csv(file_path)
        print("Original columns:", df.columns.tolist())
        
        # 1. Rename date -> last_updated
        if 'date' in df.columns:
            df.rename(columns={'date': 'last_updated'}, inplace=True)
            print("Renamed 'date' to 'last_updated'.")
            
        # 2. Add 'phone' and 'michelin_tier'
        for col in ['phone', 'michelin_tier']:
            if col not in df.columns:
                df[col] = ""
                print(f"Added column '{col}'.")
                
        # 3. Reorder columns
        # Desired order: ..., longitude, phone, last_updated, michelin_tier
        
        # We want to insert 'phone' after 'longitude'
        # And ensure 'last_updated' is after 'phone'
        # And 'michelin_tier' is at the very end.
        
        # Let's define the full expected order based on previous steps + user request
        expected_order = [
            'no',
            'media_type',
            'title',
            'place_name',
            'place_type',
            'description',
            'opening_hours',
            'break_time',
            'closed_days',
            'chef',
            'address',
            'latitude',
            'longitude',
            'phone',
            'last_updated',
            'michelin_tier'
        ]
        
        # Check if we have additional columns not in expected_order (unlikely but safe to keep)
        current_cols = df.columns.tolist()
        remaining_cols = [c for c in current_cols if c not in expected_order]
        
        # Final combine
        final_order = expected_order + remaining_cols
        
        # Filter strictly to columns that actually exist in the dataframe
        final_order = [c for c in final_order if c in df.columns]
        
        df = df[final_order]
        
        df.to_csv(file_path, index=False)
        
        print("Finalization complete.")
        print("New columns:", df.columns.tolist())
        
    except Exception as e:
        print(f"Error processing file: {e}")

if __name__ == "__main__":
    finalize_columns()
