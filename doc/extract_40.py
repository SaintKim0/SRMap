#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
40개 스크롤 데이터 추출
"""

import json
import csv
import re
from datetime import datetime

def extract_from_html(html_file):
    """HTML 파일에서 식당 데이터 추출"""
    
    print(f"Reading HTML file: {html_file}")
    
    try:
        with open(html_file, 'r', encoding='utf-8') as f:
            html_content = f.read()
    except Exception as e:
        print(f"Error reading file: {e}")
        return []
    
    # localStorage 데이터 찾기
    pattern = r"localStorage\.setItem\('listData',\s*'(.+?)'\);"
    match = re.search(pattern, html_content, re.DOTALL)
    
    if not match:
        print("Could not find listData in HTML")
        return []
    
    json_str = match.group(1)
    print(f"Found JSON string (length: {len(json_str)})")
    
    try:
        # 이스케이프 처리
        json_str = json_str.replace(r'\"', '"')
        json_str = json_str.encode('utf-8').decode('unicode_escape')
        
        # JSON 파싱
        data = json.loads(json_str)
        
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
        return []

def save_to_csv(restaurants, output_file='tasty_boys.csv'):
    """CSV 파일로 저장"""
    
    if not restaurants:
        print("\nNo restaurants to save")
        return
    
    print(f"\nSaving {len(restaurants)} restaurants to {output_file}")
    
    csv_data = []
    current_date = datetime.now().strftime('%Y-%m-%d')
    
    for idx, restaurant in enumerate(restaurants, 1):
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
    
    fieldnames = ['id', 'sector', 'title', 'name', 'type', 'chef', 'address', 'lat', 'lng', 'date', 'area', 'user_score', 'review_cnt']
    
    with open(output_file, 'w', encoding='utf-8-sig', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(csv_data)
    
    print(f"✓ Successfully saved {len(csv_data)} restaurants to {output_file}")
    
    # 요약 출력
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
    html_file = '경기도 맛있는녀석들 맛집 Top100(40) - 다이닝코드.html'
    
    print("=" * 60)
    print("Extracting 40 Restaurant Data from HTML")
    print("=" * 60)
    
    restaurants = extract_from_html(html_file)
    
    if restaurants:
        save_to_csv(restaurants)
    else:
        print("\n❌ Failed to extract restaurant data")
