#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
다이닝코드 페이지에서 전체 데이터 추출
방법: 페이지 소스에서 JavaScript 변수 또는 지도 데이터 추출
"""

import requests
from bs4 import BeautifulSoup
import json
import csv
import re
from datetime import datetime

def extract_all_restaurants():
    """페이지 소스에서 모든 식당 데이터 추출"""
    
    url = "https://www.diningcode.com/list.dc?query=경기도+맛있는녀석들"
    
    print("페이지 다운로드 중...")
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    }
    
    try:
        response = requests.get(url, headers=headers, timeout=15)
        response.encoding = 'utf-8'
        
        if response.status_code != 200:
            print(f"❌ HTTP 오류: {response.status_code}")
            return []
        
        html_content = response.text
        print(f"✓ 페이지 다운로드 완료 ({len(html_content)} bytes)")
        
        # 방법 1: localStorage 데이터 추출
        print("\n방법 1: localStorage 데이터 검색 중...")
        pattern = r"localStorage\.setItem\('listData',\s*'(.+?)'\);"
        match = re.search(pattern, html_content, re.DOTALL)
        
        if match:
            json_str = match.group(1)
            print(f"  ✓ localStorage 데이터 발견 (길이: {len(json_str)})")
            
            # JSON 디코딩
            try:
                # 이스케이프 처리
                json_str = json_str.replace(r'\"', '"')
                json_str = json_str.encode('utf-8').decode('unicode_escape')
                
                data = json.loads(json_str)
                
                if 'poi_section' in data and 'list' in data['poi_section']:
                    restaurants = data['poi_section']['list']
                    total_cnt = data['poi_section'].get('total_cnt', 0)
                    
                    print(f"  ✓ 전체 개수: {total_cnt}")
                    print(f"  ✓ 추출된 개수: {len(restaurants)}")
                    
                    return restaurants
                    
            except Exception as e:
                print(f"  ❌ JSON 파싱 오류: {e}")
        
        # 방법 2: script 태그에서 데이터 검색
        print("\n방법 2: script 태그 검색 중...")
        soup = BeautifulSoup(html_content, 'html.parser')
        scripts = soup.find_all('script')
        
        for script in scripts:
            if script.string and 'poi_section' in script.string:
                print(f"  ✓ poi_section 발견")
                # 추가 처리 가능
        
        # 방법 3: JSON-LD 구조화 데이터
        print("\n방법 3: JSON-LD 구조화 데이터 검색 중...")
        json_ld_scripts = soup.find_all('script', type='application/ld+json')
        
        for script in json_ld_scripts:
            try:
                data = json.loads(script.string)
                if data.get('@type') == 'ItemList':
                    items = data.get('itemListElement', [])
                    print(f"  ✓ JSON-LD에서 {len(items)}개 발견")
                    # 하지만 이것은 20개만 포함
            except:
                pass
        
        print("\n❌ 모든 방법 실패")
        return []
        
    except Exception as e:
        print(f"❌ 오류 발생: {e}")
        return []

def save_to_csv(restaurants, output_file='tasty_boys.csv'):
    """식당 데이터를 CSV 파일로 저장"""
    
    if not restaurants:
        print("\n❌ 저장할 데이터가 없습니다")
        return
    
    print(f"\n{'='*60}")
    print(f"{len(restaurants)}개의 식당 데이터를 {output_file}에 저장합니다...")
    
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
    
    print(f"✓ 저장 완료!")
    print(f"\n처음 5개:")
    for i, rest in enumerate(csv_data[:5], 1):
        print(f"  {i}. {rest['name']} - {rest['type']} ({rest['area']})")
    
    if len(csv_data) > 5:
        print(f"\n마지막 5개:")
        for i, rest in enumerate(csv_data[-5:], len(csv_data)-4):
            print(f"  {i}. {rest['name']} - {rest['type']} ({rest['area']})")

if __name__ == '__main__':
    print("="*60)
    print("다이닝코드 맛있는녀석들 전체 데이터 추출")
    print("="*60)
    
    restaurants = extract_all_restaurants()
    
    if restaurants:
        save_to_csv(restaurants)
        print(f"\n✅ 성공! {len(restaurants)}개의 식당 데이터를 수집했습니다.")
    else:
        print("\n⚠️ 데이터 추출 실패")
        print("\n대안: 브라우저에서 페이지를 끝까지 스크롤한 후")
        print("HTML 파일을 저장하고 extract_from_saved_html.py를 실행하세요.")
