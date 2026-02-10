import csv
from collections import Counter

def check_true_duplicates(file_path):
    print(f"Checking {file_path} for exact duplicates (excluding 'no' column)...")
    try:
        with open(file_path, 'r', encoding='utf-8-sig') as f:
            reader = csv.DictReader(f)
            rows = list(reader)
        
        # Define what constitutes a duplicate
        # We exclude the 'no' column because it's often just a row index
        def get_key(row):
            return tuple(row[k] for k in reader.fieldnames if k != 'no')

        keys = [get_key(r) for r in rows]
        counts = Counter(keys)
        
        duplicates = [k for k, v in counts.items() if v > 1]
        
        if not duplicates:
            print("No exact duplicates found (excluding 'no' column).")
        else:
            print(f"Found {len(duplicates)} duplicate sets.")
            for k in duplicates[:5]:
                print(f"Duplicate key: {k}")
                
        # Check for Name + Address + Title duplicates
        def get_nat_key(row):
            return (row.get('place_name', '').strip(), row.get('address', '').strip(), row.get('title', '').strip())
            
        nat_keys = [get_nat_key(r) for r in rows]
        nat_counts = Counter(nat_keys)
        nat_duplicates = [k for k, v in nat_counts.items() if v > 1]
        
        if not nat_duplicates:
            print("No Name+Address+Title duplicates found.")
        else:
            print(f"Found {len(nat_duplicates)} Name+Address+Title duplicate sets.")
            for k in nat_duplicates[:10]:
                print(f"Duplicate (Name, Addr, Title): {k}")

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    check_true_duplicates("assets/data/locations.csv")
