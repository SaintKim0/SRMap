import csv
import os

def main():
    base_data_path = 'd:/00_projects/02_TasteMap/doc/data/'
    new_data_file = base_data_path + '전현무계획 3_geocoded.csv'
    main_locations_file = 'd:/00_projects/02_TasteMap/assets/data/locations.csv'
    
    # 1. Read main locations to find the last ID
    with open(main_locations_file, 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        main_header = next(reader)
        main_rows = list(reader)
        
    last_id = 0
    if main_rows:
        try:
            # Try to find the maximum ID in the 'no' column
            last_id = max(int(row[0]) for row in main_rows if row[0].isdigit())
        except ValueError:
            # Fallback to the last line's ID if max fails
            last_id = int(main_rows[-1][0]) if main_rows[-1][0].isdigit() else 0

    print(f"Current last ID in locations.csv: {last_id}")
    
    # 2. Read new data
    with open(new_data_file, 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        new_header = next(reader)
        new_rows = list(reader)
        
    # 3. Check for duplicates (Optional but safe)
    # Simple duplicate check by (place_name, address)
    existing_keys = set((row[3], row[9]) for row in main_rows)
    
    to_append = []
    current_id = last_id + 1
    
    for row in new_rows:
        key = (row[3], row[9])
        if key not in existing_keys:
            # Update ID
            row[0] = str(current_id)
            to_append.append(row)
            current_id += 1
        else:
            print(f"Skipping duplicate: {row[3]} at {row[9]}")
            
    # 4. Append to main file
    if to_append:
        with open(main_locations_file, 'a', encoding='utf-8', newline='') as f:
            writer = csv.writer(f)
            writer.writerows(to_append)
        print(f"Successfully appended {len(to_append)} new rows to {main_locations_file}.")
    else:
        print("No new rows to append.")

if __name__ == "__main__":
    main()
