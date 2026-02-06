
import csv

bw_titles = set()

with open('assets/data/locations.csv', 'r', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    for row in reader:
        if row['media_type'] == 'blackwhite':
            bw_titles.add(row['title'])

print("B&W Titles:", bw_titles)
