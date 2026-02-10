import csv

INPUT_FILE = "assets/data/locations_backup.csv"

def check_coords():
    print(f"Reading {INPUT_FILE}...")
    try:
        with open(INPUT_FILE, 'r', encoding='utf-8-sig') as f:
            reader = csv.DictReader(f)
            for row in reader:
                name = row.get('place_name', '')
                if '황장군' in name:
                    print(f"Name: '{name}' | Lat: {row.get('latitude')} | Lng: {row.get('longitude')} | Addr: {row.get('address')}")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    check_coords()
