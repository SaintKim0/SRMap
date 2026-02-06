#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
식객허영만의백반기행 경남 식당 데이터 추출
"""

from bs4 import BeautifulSoup
import csv
from datetime import datetime
import re
import os

def extract_from_html_cards(html_file):
    """HTML 카드 요소에서 직접 식당 데이터 추출"""
    
    print(f"Reading HTML file: {html_file}")
    
    if not os.path.exists(html_file):
        print(f"Error: File not found: {html_file}")
        return []

    try:
        with open(html_file, 'r', encoding='utf-8') as f:
            html_content = f.read()
    except Exception as e:
        print(f"Error reading file: {e}")
        return []
    
    soup = BeautifulSoup(html_content, 'html.parser')
    
    # 식당 카드 찾기
    poi_blocks = soup.find_all('a', class_='PoiBlock')
    
    print(f"Found {len(poi_blocks)} restaurant cards")
    
    restaurants = []
    
    for idx, block in enumerate(poi_blocks, 1):
        try:
            # 식당명  
            title_elem = block.find('h2')
            if title_elem:
                # number-prefix 제거
                prefix = title_elem.find('span', class_='number-prefix')
                if prefix:
                    prefix.extract()
                
                # Info__Title__Place에서 이름 추출
                place_span = title_elem.find('span', class_='Info__Title__Place')
                if place_span:
                    # 지역명 분리
                    area_span = place_span.find('span')
                    area = area_span.text.strip() if area_span else ''
                    
                    # area_span 제거 후 이름 추출
                    if area_span:
                        area_span.extract()
                    
                    name = place_span.text.strip()
                else:
                    name = title_elem.text.strip()
                    area = ''
            else:
                name = ''
                area = ''
            
            # 카테고리
            category_container = block.find('div', class_='CategoryContainer')
            categories = []
            if category_container:
                cat_spans = category_container.find_all('span', class_='Category')
                for cat in cat_spans:
                    categories.append(cat.text.strip())
            category = ', '.join(categories) if categories else ''
            
            # 평점
            score_elem = block.find('p', class_='Score')
            score = score_elem.find('span').text.strip() if score_elem and score_elem.find('span') else ''
            
            # 사용자 평점
            user_score_elem = block.find('p', class_='UserScore')
            user_score = ''
            review_cnt = ''
            if user_score_elem:
                score_text = user_score_elem.find('span', class_='score-text')
                count_text = user_score_elem.find('span', class_='count-text')
                
                if score_text:
                    user_score = score_text.text.strip()
                
                if count_text:
                    # "(4명)" 형식에서 숫자만 추출
                    count_match = re.search(r'(\d+)', count_text.text)
                    if count_match:
                        review_cnt = count_match.group(1)
            
            restaurants.append({
                'name': name,
                'area': area,
                'category': category,
                'score': score,
                'user_score': user_score,
                'review_cnt': review_cnt
            })
            
        except Exception as e:
            print(f"Error parsing restaurant {idx}: {e}")
            continue
    
    return restaurants

def save_to_csv(restaurants, output_file='허영만_경남.csv'):
    """식당 데이터를 CSV 파일로 저장"""
    
    if not restaurants:
        print("\nNo restaurants to save")
        return
    
    print(f"\nSaving {len(restaurants)} restaurants to {output_file}")
    
    csv_data = []
    current_date = datetime.now().strftime('%Y-%m-%d')
    
    for idx, restaurant in enumerate(restaurants, 1):
        csv_data.append({
            'id': idx,
            'sector': '식객허영만의백반기행',
            'title': '식객허영만의백반기행',
            'name': restaurant['name'],
            'type': restaurant['category'],
            'chef': '',
            'address': '',
            'lat': '',
            'lng': '',
            'date': current_date,
            'area': restaurant['area'],
            'user_score': restaurant['user_score'],
            'review_cnt': restaurant['review_cnt']
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
        print(f"  {i}. {rest['name']} - {rest['type']} ({rest['area']})")
    
    if len(csv_data) > 5:
        print(f"\nLast 5 restaurants:")
        for i, rest in enumerate(csv_data[-5:], len(csv_data)-4):
            print(f"  {i}. {rest['name']} - {rest['type']} ({rest['area']})")

if __name__ == '__main__':
    html_file = '경남 식객허영만의백반기행 맛집 Top78 - 다이닝코드.html'
    
    print("="*60)
    print("Extracting 식객허영만의백반기행 경남 Restaurant Data")
    print("="*60)
    
    restaurants = extract_from_html_cards(html_file)
    
    if restaurants:
        save_to_csv(restaurants)
    else:
        print("\n❌ Failed to extract restaurant data")
