import csv
import os
import shutil

INPUT_FILE = "assets/data/locations.csv"
OUTPUT_FILE = "assets/data/locations_deduped.csv"
BACKUP_FILE = "assets/data/locations_backup.csv"

def norm(s):
    return str(s).strip().replace(' ', '')

def norm_addr(s):
    return str(s).strip().replace(' ', '')

def deduplicate():
    if not os.path.exists(INPUT_FILE):
        print(f"File not found: {INPUT_FILE}")
        return

    print(f"Reading {INPUT_FILE}...")
    rows = []
    try:
        with open(INPUT_FILE, 'r', encoding='utf-8-sig') as f:
            reader = csv.DictReader(f)
            fieldnames = reader.fieldnames
            for row in reader:
                rows.append(row)
    except Exception as e:
        print(f"Error reading CSV: {e}")
        return

    print(f"Total rows read: {len(rows)}")

    # 1. Group by (Address, Title)
    # Key: (address_norm, title_norm) -> List of rows
    grouped = {}
    
    for row in rows:
        addr = row.get('address', '')
        title = row.get('title', '')
        place_name = row.get('place_name', '')
        
        key = (norm_addr(addr), norm(title))
        if key not in grouped:
            grouped[key] = []
        grouped[key].append(row)

    print(f"Unique (Address, Program) groups: {len(grouped)}")

    deduped_rows = []
    removed_count = 0
    
    for key, group in grouped.items():
        # Debug for specific items
        if any('목마식당' in r.get('place_name', '') or '황장군' in r.get('place_name', '') for r in group):
            if len(group) > 1:
                print(f"[Debug] Group with {len(group)} items for key {key}:")
                for r in group:
                    print(f" - {r.get('place_name')} | {r.get('title')} | {r.get('address')}")

        if len(group) == 1:
            deduped_rows.append(group[0])
        else:
            # Sort by name length (descending) to prioritize longer names (e.g. Branch included)
            group.sort(key=lambda x: len(x.get('place_name', '')), reverse=True)
            
            best_row = group[0]
            deduped_rows.append(best_row)
            removed_count += (len(group) - 1)


    print(f"Deduplication complete.")
    print(f"Original: {len(rows)}")
    print(f"Deduped:  {len(deduped_rows)}")
    print(f"Removed:  {removed_count}")

    # Write output
    try:
        with open(OUTPUT_FILE, 'w', encoding='utf-8-sig', newline='') as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            
            # Clean rows to ensure only valid fieldnames are written
            clean_rows = []
            for row in deduped_rows:
                clean_row = {k: row[k] for k in fieldnames if k in row}
                clean_rows.append(clean_row)
                
            writer.writerows(clean_rows)
        print(f"Written to {OUTPUT_FILE}")
        
    except Exception as e:
        print(f"Error writing CSV: {e}")

if __name__ == "__main__":
    deduplicate()
