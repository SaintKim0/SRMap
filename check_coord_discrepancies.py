import csv
from collections import defaultdict

def check_coordinate_discrepancies(file_path):
    print(f"Analyzing {file_path} for coordinate discrepancies...")
    address_groups = defaultdict(list)
    
    try:
        with open(file_path, 'r', encoding='utf-8-sig') as f:
            reader = csv.DictReader(f)
            for row in reader:
                addr = row.get('address', '').strip()
                if addr:
                    address_groups[addr].append(row)
        
        discrepancies = []
        for addr, group in address_groups.items():
            if len(group) > 1:
                coords = set()
                for r in group:
                    lat = r.get('latitude', '').strip()
                    lng = r.get('longitude', '').strip()
                    coords.add((lat, lng))
                
                if len(coords) > 1:
                    discrepancies.append({
                        'address': addr,
                        'entries': group,
                        'unique_coords': coords
                    })
        
        if not discrepancies:
            print("No coordinate discrepancies found for identical addresses.")
        else:
            print(f"Found {len(discrepancies)} addresses with varying coordinates.")
            for d in discrepancies[:10]:
                print(f"\nAddress: {d['address']}")
                print(f"Unique Coords: {d['unique_coords']}")
                for r in d['entries']:
                    print(f" - {r.get('place_name')} ({r.get('title')}): {r.get('latitude')}, {r.get('longitude')}")

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    check_coordinate_discrepancies("assets/data/locations.csv")
