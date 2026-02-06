
import pandas as pd
import os

def refine_csv():
    file_path = r"d:\00_projects\02_TasteMap\doc\data\matzip.csv"
    
    if not os.path.exists(file_path):
        print(f"File not found: {file_path}")
        return

    try:
        df = pd.read_csv(file_path)
        print("Original columns:", df.columns.tolist())
        
        # Ensure we work with string types for combination
        df['place_type'] = df['place_type'].fillna('')
        df['area'] = df['area'].fillna('')
        
        # Create description from area and original place_type
        # user requested: area data to description front, and original place_type to description
        # Format: "{area} {original_place_type}"
        df['description'] = df.apply(lambda row: f"{row['area']} {row['place_type']}".strip(), axis=1)
        
        # Set place_type to 'restaurant' (correcting user's typo 'restraunt')
        df['place_type'] = 'restaurant'
        
        # Drop area column
        if 'area' in df.columns:
            df.drop(columns=['area'], inplace=True)
            print("Dropped 'area' column.")
            
        # Reorder columns to put description in a logical place (usually after place_type)
        # Check current columns and arrange
        # Expected standard: no,media_type,title,place_name,place_type,description,chef,address,latitude,longitude,date
        cols = df.columns.tolist()
        desired_order = ['no', 'media_type', 'title', 'place_name', 'place_type', 'description']
        remaining_cols = [c for c in cols if c not in desired_order]
        new_order = desired_order + remaining_cols
        
        # Only use columns that actually exist
        final_order = [c for c in new_order if c in df.columns]
        df = df[final_order]
        
        df.to_csv(file_path, index=False)
        
        print("Refinement complete.")
        print("New columns:", df.columns.tolist())
        print("Sample description:", df['description'].iloc[0] if not df.empty else "No data")
        
    except Exception as e:
        print(f"Error processing file: {e}")

if __name__ == "__main__":
    refine_csv()
