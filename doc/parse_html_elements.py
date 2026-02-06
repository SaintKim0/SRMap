#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
HTML 요소에서 직접 식당 데이터 추출
localStorage 대신 실제 HTML 카드를 파싱
"""

from bs4 import BeautifulSoup
import csv
import re
from datetime import datetime

def extract_from_html_elements(html_file):
    """HTML 요소에서 직접 식당 데이터 추출"""
    
    print(f"Reading HTML file: {html_file}")
    
    try:
        with open(html_file, 'r', encoding='utf-8') as f:
            html_content = f.read()
    except Exception as e:
        print(f"Error reading file: {e}")
        return []
    
    soup = BeautifulSoup(html_content, 'html.parser')
    
    # 식당 카드 찾기 (다양한 클래스명 시도)
    restaurant_cards = []
    
    # 시도 1: PoiBlock 클래스
    cards = soup.find_all(class_=re.compile(r'PoiBlock|poi-block|restaurant-card', re.I))
    if cards:
        restaurant_cards = cards
        print(f"Found {len(cards)} restaurant cards (PoiBlock)")
    
    # 시도 2: 데이터 속성으로 찾기
    if not restaurant_cards:
        cards = soup.find_all(attrs={'data-rid': True})
        if cards:
            restaurant_cards = cards
            print(f"Found {len(cards)} restaurant cards (data-rid)")
    
    # 시도 3: 링크에서 찾기
    if not restaurant_cards:
        links = soup.find_all('a', href=re.compile(r'profile\.php\?rid='))
        print(f"Found {len(links)} restaurant links")
        
        # 링크에서 부모 요소 찾기
        seen_rids = set()
        for link in links:
            rid_match = re.search(r'rid=([^&]+)', link['href'])
            if rid_match:
                rid = rid_match.group(1)
                if rid not in seen_rids:
                    seen_rids.add(rid)
                    restaurant_cards.append(link.find_parent())
    
    print(f"\nTotal cards found: {len(restaurant_cards)}")
    
    if not restaurant_cards:
        print("\n❌ No restaurant cards found!")
        print("Trying to find any elements with restaurant data...")
        
        # HTML 구조 샘플 출력
        body = soup.find('body')
        if body:
            print("\nHTML structure sample:")
            print(str(body)[:1000])
    
    return []

if __name__ == '__main__':
    html_file = '경기도 맛있는녀석들 맛집 Top100(40) - 다이닝코드.html'
    
    print("=" * 60)
    print("Extracting Restaurant Data from HTML Elements")
    print("=" * 60)
    
    restaurants = extract_from_html_elements(html_file)
