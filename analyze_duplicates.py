import csv
import os

def analyze_duplicates(file_path):
    print(f"Loading {file_path}...")
    if not os.path.exists(file_path):
        print(f"File not found: {file_path}")
        return

    rows = []
    try:
        with open(file_path, 'r', encoding='utf-8-sig') as f:
            reader = csv.DictReader(f)
            fieldnames = reader.fieldnames
            print(f"Columns: {fieldnames}")
            for row in reader:
                rows.append(row)
    except Exception as e:
        print(f"Error reading CSV: {e}")
        return

    print(f"Total rows: {len(rows)}")

    # 1. Exact Duplicates (Name, Address, ContentTitle (Program))
    # content_title might be 'contentTitle' or 'content_title' based on previous context.
    # Looking at SearchScreen.dart, it uses `location.contentTitle`. In CSV it's likely `content_title` or similar.
    # Let's inspect columns from output first, but for now assume standard keys.
    
    # We'll normalize keys to lowercase just in case for the script logic if needed, but DictReader uses exact header.
    # Let's use the first row to guess key names if they exist.
    if not rows:
        return

    keys = rows[0].keys()
    name_key = next((k for k in keys if 'name' in k.lower() or '상호' in k), None)
    addr_key = next((k for k in keys if 'address' in k.lower() or '주소' in k), None)
    prog_key = next((k for k in keys if 'content' in k.lower() or 'title' in k.lower() or '방송' in k), None)

    print(f"Using keys: Name='{name_key}', Address='{addr_key}', Program='{prog_key}'")

    if not (name_key and addr_key and prog_key):
        print("Could not identify necessary columns.")
        return

    # Helper to normalize
    def norm(s):
        return str(s).strip() if s else ""
    def norm_addr(s):
        return str(s).strip().replace(' ', '') if s else ""

    # Check Exact Duplicates
    seen = {}
    duplicates = []
    
    # Check Address+Program duplicates (Potential Name variations)
    addr_prog_seen = {}
    addr_prog_duplicates = []

    for i, row in enumerate(rows):
        name = row.get(name_key, '')
        addr = row.get(addr_key, '')
        prog = row.get(prog_key, '')
        
        # 1. Exact Key
        exact_key = (norm(name), norm_addr(addr), norm(prog))
        if exact_key in seen:
            duplicates.append((i, row))
        else:
            seen[exact_key] = i
            
        # 2. Addr+Prog Key
        ap_key = (norm_addr(addr), norm(prog))
        if ap_key in addr_prog_seen:
            # We found a row with same address and program.
            # Check if name is different.
            prev_idx = addr_prog_seen[ap_key]
            prev_row = rows[prev_idx]
            prev_name = prev_row.get(name_key, '')
            
            if norm(name) != norm(prev_name):
                # This is a "Same Address, Same Program, Different Name" case
                addr_prog_duplicates.append({
                    'index': i, 
                    'row': row, 
                    'prev_index': prev_idx, 
                    'prev_row': prev_row
                })
        else:
            addr_prog_seen[ap_key] = i

    print(f"\n[Exact Duplicates] Found {len(duplicates)} rows that are identical in Name, Address, Program.")
    for i, row in duplicates[:5]:
        print(f"Row {i}: {row[name_key]} | {row[prog_key]} | {row[addr_key]}")

    print(f"\n[Similar Duplicates] Found {len(addr_prog_duplicates)} rows with Same Address & Program but Different Name.")
    for item in addr_prog_duplicates[:10]:
        r1 = item['prev_row']
        r2 = item['row']
        print(f"Compare: '{r1[name_key]}' vs '{r2[name_key]}' | Prog: {r1[prog_key]} | Addr: {r1[addr_key]}")

if __name__ == "__main__":
    analyze_duplicates("assets/data/locations.csv")
