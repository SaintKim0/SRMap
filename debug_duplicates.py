import csv

INPUT_FILE = "assets/data/locations.csv"

def debug_duplicates():
    print(f"Reading {INPUT_FILE}...")
    try:
        with open(INPUT_FILE, 'r', encoding='utf-8-sig') as f:
            reader = csv.DictReader(f)
            for row in reader:
                name = row.get('place_name', '')
                if '목마식당' in name or '황장군' in name:
                    print(f"Name: '{name}' | Program: '{row.get('title', '')}' | Addr: '{row.get('address', '')}'")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    debug_duplicates()
