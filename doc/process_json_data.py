#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Process JSON data copied from browser console
"""

import json
import csv
from datetime import datetime

def process_json_file(json_file='restaurants_data.json', output_file='tasty_boys.csv'):
    """Process JSON file and save to CSV"""
    
    print(f"Reading JSON file: {json_file}")
    
    try:
        with open(json_file, 'r', encoding='utf-8') as f:
            restaurants = json.load(f)
    except FileNotFoundError:
        print(f"❌ File not found: {json_file}")
        print("\nPlease follow these steps:")
        print("1. Open the webpage in browser")
        print("2. Scroll to load all 122 restaurants")
        print("3. Press F12 to open Developer Tools")
        print("4. Go to Console tab")
        print("5. Paste this code and press Enter:")
        print("   copy(JSON.stringify(JSON.parse(localStorage.getItem('listData')).poi_section.list, null, 2))")
        print("6. Save the clipboard content as 'restaurants_data.json'")
        print("7. Run this script again")
        return
    except Exception as e:
        print(f"❌ Error reading JSON file: {e}")
        return
    
    print(f"Found {len(restaurants)} restaurants")
    
    # Prepare CSV data
    csv_data = []
    current_date = datetime.now().strftime('%Y-%m-%d')
    
    for idx, restaurant in enumerate(restaurants, 1):
        # Extract data
        name = restaurant.get('nm', '')
        branch = restaurant.get('branch', '')
        if branch:
            full_name = f"{name} {branch}"
        else:
            full_name = name
            
        address = restaurant.get('road_addr', '') or restaurant.get('addr', '')
        category = restaurant.get('category', '')
        lat = restaurant.get('lat', '')
        lng = restaurant.get('lng', '')
        user_score = restaurant.get('user_score', '')
        review_cnt = restaurant.get('review_cnt', '')
        
        # Get area (지역)
        area_list = restaurant.get('area', [])
        area = area_list[0] if area_list else ''
        
        csv_data.append({
            'id': idx,
            'sector': '맛있는녀석들',
            'title': '맛있는녀석들',
            'name': full_name,
            'type': category,
            'chef': '',
            'address': address,
            'lat': lat,
            'lng': lng,
            'date': current_date,
            'area': area,
            'user_score': user_score,
            'review_cnt': review_cnt
        })
    
    # Write to CSV
    fieldnames = ['id', 'sector', 'title', 'name', 'type', 'chef', 'address', 'lat', 'lng', 'date', 'area', 'user_score', 'review_cnt']
    
    with open(output_file, 'w', encoding='utf-8-sig', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(csv_data)
    
    print(f"\n✓ Successfully saved {len(csv_data)} restaurants to {output_file}")
    
    # Print summary
    print(f"\n=== Summary ===")
    print(f"Total restaurants: {len(csv_data)}")
    print(f"\nFirst 5 restaurants:")
    for i, rest in enumerate(csv_data[:5], 1):
        print(f"{i}. {rest['name']} - {rest['type']} ({rest['area']})")
    
    if len(csv_data) > 5:
        print(f"\nLast 5 restaurants:")
        for i, rest in enumerate(csv_data[-5:], len(csv_data)-4):
            print(f"{i}. {rest['name']} - {rest['type']} ({rest['area']})")

if __name__ == '__main__':
    print("=" * 60)
    print("Processing Tasty Boys Restaurant Data from JSON")
    print("=" * 60)
    
    process_json_file()
