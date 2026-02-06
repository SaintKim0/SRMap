
import csv

types = set()
descriptions = []

with open('assets/data/locations.csv', 'r', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    for row in reader:
        types.add(row['place_type'])
        if len(descriptions) < 20: 
             descriptions.append(row['description'])

print("Unique Types:", types)
print("Sample Descriptions:", descriptions)
