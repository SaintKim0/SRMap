
import pandas as pd
import os

def remove_chef_column():
    file_path = r"d:\00_projects\02_TasteMap\doc\data\matzip.csv"
    
    if not os.path.exists(file_path):
        print(f"File not found: {file_path}")
        return

    try:
        df = pd.read_csv(file_path)
        print("Original columns:", df.columns.tolist())
        
        if 'chef' in df.columns:
            df.drop(columns=['chef'], inplace=True)
            print("Dropped 'chef' column.")
        else:
            print("'chef' column not found.")
            
        df.to_csv(file_path, index=False)
        
        print("Process complete.")
        print("New columns:", df.columns.tolist())
        
    except Exception as e:
        print(f"Error processing file: {e}")

if __name__ == "__main__":
    remove_chef_column()
