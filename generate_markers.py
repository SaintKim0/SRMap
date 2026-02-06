from PIL import Image, ImageDraw

def create_marker(filename, color, text_char):
    # Size 80x80 to match previous widget size
    size = (80, 80)
    image = Image.new('RGBA', size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    
    # Draw Circle
    # Padding 4px
    draw.ellipse((4, 4, 76, 76), fill=color, outline='white', width=4)
    
    # Draw simple "icon" representation (circle or letter)
    # Since we can't easily rely on fonts being present, we'll draw a simple white shape
    # center: 40, 40
    
    if text_char == 'star': # Michelin
        # Draw a simple star-like shape (diamond)
        draw.polygon([(40, 20), (55, 40), (40, 60), (25, 40)], fill='white')
    elif text_char == 'tv': # Entertainment
        # Draw a rectangle
        draw.rectangle((25, 30, 55, 50), fill='white')
        draw.line((30, 50, 25, 60), fill='white', width=2)
        draw.line((50, 50, 55, 60), fill='white', width=2)
    elif text_char == 'bw': # Black/White
        # Draw a split circle or just a circle
        draw.ellipse((30, 30, 50, 50), fill='white')
    else: # Default
        # Draw a pin point
        draw.ellipse((35, 35, 45, 45), fill='white')

    image.save(f'assets/images/markers/{filename}')

import os
os.makedirs('assets/images/markers', exist_ok=True)

create_marker('marker_black_white.png', (0, 0, 0, 255), 'bw') # Black
create_marker('marker_michelin.png', (189, 35, 51, 255), 'star') # Red (Michelin approx)
create_marker('marker_entertainment.png', (0, 150, 136, 255), 'tv') # Teal
create_marker('marker_default.png', (63, 81, 181, 255), 'default') # Indigo
