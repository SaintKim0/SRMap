#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Extract restaurant data from saved HTML file
"""

import json
import csv
import re
from datetime import datetime

def extract_from_html(html_file):
    """Extract restaurant data from saved HTML file"""
    
    print(f"Reading HTML file: {html_file}")
    
    try:
        with open(html_file, 'r', encoding='utf-8') as f:
            html_content = f.read()
    except Exception as e:
        print(f"Error reading file: {e}")
        return []
    
    # Find the localStorage.setItem line
    pattern = r"localStorage\.setItem\('listData',\s*'(.+?)'\);"
    match = re.search(pattern, html_content, re.DOTALL)
    
    if not match:
        print("Could not find listData in HTML")
        return []
    
    json_str = match.group(1)
    print(f"Found JSON string (length: {len(json_str)})")
    
    # Decode unicode escapes
    try:
        # Replace escaped quotes
        json_str = json_str.replace(r'\"', '"')
        
        # Decode unicode escapes like \uacbd\uae30\ub3c4
        json_str = json_str.encode('utf-8').decode('unicode_escape')
        
        # Parse JSON
        data = json.loads(json_str)
        
        # Extract restaurant list
        if 'poi_section' in data and 'list' in data['poi_section']:
            restaurants = data['poi_section']['list']
            total_count = data['poi_section'].get('total_cnt', 0)
            
            print(f"Total restaurants in data: {total_count}")
            print(f"Restaurants extracted: {len(restaurants)}")
            
            return restaurants
        else:
            print("Could not find poi_section.list in data")
            return []
            
    except Exception as e:
        print(f"Error parsing JSON: {e}")
        print(f"First 500 chars of JSON string: {json_str[:500]}")
        return []

def save_to_csv(restaurants, output_file='tasty_boys.csv'):
    """Save restaurant data to CSV file"""
    
    if not restaurants:
        print("No restaurants to save")
        return
    
    print(f"\nSaving {len(restaurants)} restaurants to {output_file}")
    
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
    
    print(f"✓ Successfully saved {len(csv_data)} restaurants to {output_file}")
    
    # Print summary
    print(f"\n=== Summary ===")
    print(f"Total restaurants: {len(csv_data)}")
    print(f"\nFirst 5 restaurants:")
    for i, rest in enumerate(csv_data[:5], 1):
        print(f"{i}. {rest['name']} - {rest['type']} ({rest['area']})")
    
    if len(csv_data) > 5:
        print(f"\n... and {len(csv_data) - 5} more restaurants")

if __name__ == '__main__':
    html_file = '경기도 맛있는녀석들 맛집 Top100 - 다이닝코드.html'
    
    print("=" * 60)
    print("Extracting Tasty Boys Restaurant Data from HTML")
    print("=" * 60)
    
    restaurants = extract_from_html(html_file)
    
    if restaurants:
        save_to_csv(restaurants)
    else:
        print("\n❌ Failed to extract restaurant data")
        print("Please check the HTML file and try again")
