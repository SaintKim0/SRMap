import csv
import shutil
from collections import defaultdict

def is_detailed(description):
    if not description: return False
    # Assume detailed descriptions contain '회' (Episode) or are longer
    return '회' in description or len(description) > 30

def dedup_csv(filename):
    shutil.copy(filename, filename + '.bak')
    
    with open(filename, 'r', encoding='utf-8') as f:
        reader = list(csv.DictReader(f))
        
    print(f"Total rows before: {len(reader)}")
    
    # Key: (Show, Name) -> List of rows
    # We use a loose match for address if needed, but let's strict match Show+Name first
    # checking for same show duplicates.
    groups = defaultdict(list)
    
    for row in reader:
        # Normalize
        name = row['place_name'].strip()
        show = row['title'].strip()
        key = (show, name)
        groups[key].append(row)
        
    cleaned_rows = []
    removed_count = 0
    
    fieldnames = reader[0].keys()
    
    for key, rows in groups.items():
        if len(rows) == 1:
            cleaned_rows.append(rows[0])
        else:
            # Duplicate found
            # Prioritize: 
            # 1. Description contains '회'
            # 2. Description length
            # 3. Address length (shorter might be cleaner, or longer might have detail? 
            #    Actually user hated 'Address + Name', so shorter address is better if it excludes name)
            
            # Sort by priority
            def sort_key(r):
                desc = r.get('description', '')
                addr = r.get('address', '')
                
                has_ep = 1 if '회' in desc else 0
                desc_len = len(desc)
                # Penalize address if it contains name (heuristic)
                addr_penalty = 1 if r['place_name'] in addr else 0
                
                return (has_ep, desc_len, -addr_penalty)

            # Sort descending
            rows.sort(key=sort_key, reverse=True)
            
            # Keep top 1
            best = rows[0]
            cleaned_rows.append(best)
            removed_count += (len(rows) - 1)
            
            # Debug prin
            # if len(rows) > 1:
            #    print(f"Deduped {key}: Kept {best['id']}")

    print(f"Removed {removed_count} duplicates.")
    print(f"Total rows after: {len(cleaned_rows)}")
    
    with open(filename, 'w', encoding='utf-8', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(cleaned_rows)

if __name__ == "__main__":
    dedup_csv('assets/data/locations.csv')
