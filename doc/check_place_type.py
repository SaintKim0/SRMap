
import pandas as pd

def check_place_types():
    file_path = r"d:\00_projects\02_TasteMap\doc\data - 복사본\locations.csv"
    try:
        df = pd.read_csv(file_path)
        print("Unique place_types:", df['place_type'].unique())
        print("\nCounts:")
        print(df['place_type'].value_counts())
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    check_place_types()
