import csv

# Read first 3 rows of CSV
with open('assets/data/locations.csv', 'r', encoding='utf-8') as f:
    reader = csv.reader(f)
    
    # Print header with indices
    header = next(reader)
    print("CSV Header (column indices):")
    for i, col in enumerate(header):
        print(f"{i}: {col}")
    
    print("\n" + "="*80 + "\n")
    
    # Print first 2 data rows
    print("First 2 data rows:")
    for row_num, row in enumerate(reader, start=1):
        if row_num > 2:
            break
        print(f"\nRow {row_num}:")
        print(f"  Name (col 3): {row[3] if len(row) > 3 else 'N/A'}")
        print(f"  Food Category (col 15): {row[15] if len(row) > 15 else 'N/A'}")
        print(f"  Representative Menu (col 16): {row[16] if len(row) > 16 else 'N/A'}")
