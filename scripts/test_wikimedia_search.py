"""Wikimedia Commons search test (real place keywords)."""
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from download_images import search_wikimedia_images

keywords = [
    ('Gyeongbokgung Seoul', 'famous'),
    ('Byeonsan Peninsula', 'tourist'),
    ('Lotte World Tower', 'famous'),
    ('Bukchon Hanok', 'tourist'),
    ('Naedang Hanwoo', 'restaurant'),
    ('Jjinhan Sikdang', 'restaurant'),
]
print('=== Wikimedia Commons search test ===\n')
for kw, label in keywords:
    urls = search_wikimedia_images(kw, max_results=3)
    print('[%s] %s -> %d results' % (label, kw, len(urls)))
    if urls:
        for i, u in enumerate(urls[:2], 1):
            print('  %d. %s...' % (i, u[:65]))
    else:
        print('  (no results)')
    print()
