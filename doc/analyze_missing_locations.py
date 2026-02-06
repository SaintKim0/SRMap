
import pandas as pd
import numpy as np

def analyze_missing():
    file_path = r"d:\00_projects\02_TasteMap\doc\data\matzip.csv"
    df = pd.read_csv(file_path)
    
    # Treat 'inf', empty strings as NaN
    df.replace([np.inf, -np.inf, "inf", "-inf"], np.nan, inplace=True)
    df['address'] = df['address'].replace('', np.nan)
    
    missing_df = df[df['address'].isna()]
    
    print(f"Total rows: {len(df)}")
    print(f"Rows with missing address: {len(missing_df)}")
    
    if len(missing_df) > 0:
        print("\nSample of missing rows (Top 10):")
        print(missing_df[['title', 'place_name', 'description']].head(10))
        
        print("\nDistribution by 'title' (Program):")
        print(missing_df['title'].value_counts().head())

if __name__ == "__main__":
    analyze_missing()
