
import csv

titles = set()
media_types = set()
tiers = set()

with open('assets/data/locations.csv', 'r', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    for row in reader:
        titles.add(row['title'])
        media_types.add(row['media_type'])
        if row.get('michelin_tier'):
            tiers.add(row['michelin_tier'])

print("Titles:", titles)
print("Media Types:", media_types)
print("Michelin Tiers:", tiers)
