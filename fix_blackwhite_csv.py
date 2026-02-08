import csv
import re

# Read the CSV file
input_file = r'd:\00_projects\02_TasteMap\assets\data\locations.csv'
output_file = r'd:\00_projects\02_TasteMap\assets\data\locations_fixed.csv'

rows = []
fixed_count = 0

with open(input_file, 'r', encoding='utf-8') as f:
    reader = csv.reader(f)
    for row in reader:
        if len(row) > 5 and row[1] == 'blackwhite':
            # Column 5 is description (index 5)
            desc = row[5]
            # Extract chef name from description like "흑백요리사 시즌1 참가. 셰프: 황금삽" or "흑백요리사 시즌1 참가. 쉐프: 황금삽"
            # Try both 셰프 and 쉐프
            match = re.search(r'[셰쉐]프:\s*(.+?)(?:\s*$)', desc)
            if match:
                chef_name = match.group(1).strip()
                row[5] = chef_name
                fixed_count += 1
                if fixed_count <= 5:  # Print first 5 for verification
                    print(f"Fixed: {row[3]} - Chef: {chef_name}")
        rows.append(row)

# Write fixed CSV
with open(output_file, 'w', encoding='utf-8', newline='') as f:
    writer = csv.writer(f)
    writer.writerows(rows)

print(f"\nTotal fixed: {fixed_count} entries")
print(f"Fixed CSV written to: {output_file}")
