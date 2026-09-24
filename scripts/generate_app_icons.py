import os
from PIL import Image, ImageDraw

def generate_icons():
    src_path = 'assets/images/logo_1024.png'
    if not os.path.exists(src_path):
        src_path = 'assets/images/logo.png'
    
    src = Image.open(src_path).convert('RGBA')
    
    # Crop to content bbox to normalize padding
    bbox = src.getchannel('A').getbbox()
    if bbox:
        content = src.crop(bbox)
    else:
        content = src
    
    # Densities and sizes
    # Adaptive foreground sizes (108dp canvas)
    adaptive_sizes = {
        'mipmap-mdpi': 108,
        'mipmap-hdpi': 162,
        'mipmap-xhdpi': 216,
        'mipmap-xxhdpi': 324,
        'mipmap-xxxhdpi': 432
    }
    
    # Legacy icon sizes (48dp canvas)
    legacy_sizes = {
        'mipmap-mdpi': 48,
        'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192
    }
    
    res_base = 'android/app/src/main/res'
    
    # 1. Generate Adaptive Foreground Icons (ic_launcher_foreground.png)
    # The logo should occupy ~66% of the 108dp canvas (safe zone is 66dp / 108dp = 0.61 - 0.68)
    for folder, size in adaptive_sizes.items():
        folder_path = os.path.join(res_base, folder)
        os.makedirs(folder_path, exist_ok=True)
        
        fg_canvas = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        target_content_size = int(size * 0.64)
        
        # Maintain aspect ratio
        w, h = content.size
        ratio = min(target_content_size / w, target_content_size / h)
        new_w, new_h = int(w * ratio), int(h * ratio)
        
        resized_content = content.resize((new_w, new_h), Image.Resampling.LANCZOS)
        offset_x = (size - new_w) // 2
        offset_y = (size - new_h) // 2
        
        fg_canvas.paste(resized_content, (offset_x, offset_y), resized_content)
        fg_path = os.path.join(folder_path, 'ic_launcher_foreground.png')
        fg_canvas.save(fg_path, 'PNG')
        print(f"Generated {fg_path} ({size}x{size})")

    # 2. Generate Legacy Square/Masked Icons (ic_launcher.png)
    # White background with squircle / circle or crisp white card
    for folder, size in legacy_sizes.items():
        folder_path = os.path.join(res_base, folder)
        os.makedirs(folder_path, exist_ok=True)
        
        # Legacy square / smooth rounded rect
        bg = Image.new('RGBA', (size, size), (255, 255, 255, 255))
        # Draw rounded rect mask
        mask = Image.new('L', (size, size), 0)
        draw = ImageDraw.Draw(mask)
        radius = int(size * 0.22)
        draw.rounded_rectangle([(0, 0), (size - 1, size - 1)], radius=radius, fill=255)
        
        # Fit content inside with padding (~72% of size)
        target_content_size = int(size * 0.72)
        w, h = content.size
        ratio = min(target_content_size / w, target_content_size / h)
        new_w, new_h = int(w * ratio), int(h * ratio)
        resized_content = content.resize((new_w, new_h), Image.Resampling.LANCZOS)
        
        offset_x = (size - new_w) // 2
        offset_y = (size - new_h) // 2
        bg.paste(resized_content, (offset_x, offset_y), resized_content)
        
        # Apply mask
        icon = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        icon.paste(bg, (0, 0), mask)
        
        out_path = os.path.join(folder_path, 'ic_launcher.png')
        icon.save(out_path, 'PNG')
        print(f"Generated {out_path} ({size}x{size})")

    # 3. Generate Legacy Round Icons (ic_launcher_round.png)
    for folder, size in legacy_sizes.items():
        folder_path = os.path.join(res_base, folder)
        
        bg = Image.new('RGBA', (size, size), (255, 255, 255, 255))
        mask = Image.new('L', (size, size), 0)
        draw = ImageDraw.Draw(mask)
        draw.ellipse([(0, 0), (size - 1, size - 1)], fill=255)
        
        target_content_size = int(size * 0.70)
        w, h = content.size
        ratio = min(target_content_size / w, target_content_size / h)
        new_w, new_h = int(w * ratio), int(h * ratio)
        resized_content = content.resize((new_w, new_h), Image.Resampling.LANCZOS)
        
        offset_x = (size - new_w) // 2
        offset_y = (size - new_h) // 2
        bg.paste(resized_content, (offset_x, offset_y), resized_content)
        
        icon = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        icon.paste(bg, (0, 0), mask)
        
        out_path = os.path.join(folder_path, 'ic_launcher_round.png')
        icon.save(out_path, 'PNG')
        print(f"Generated {out_path} ({size}x{size})")

    # 4. Create colors.xml with ic_launcher_background
    values_dir = os.path.join(res_base, 'values')
    os.makedirs(values_dir, exist_ok=True)
    colors_xml_path = os.path.join(values_dir, 'colors.xml')
    
    # Check if colors.xml exists
    colors_content = '<?xml version="1.0" encoding="utf-8"?>\n<resources>\n    <color name="ic_launcher_background">#FFFFFF</color>\n</resources>\n'
    if os.path.exists(colors_xml_path):
        with open(colors_xml_path, 'r', encoding='utf-8') as f:
            existing = f.read()
        if 'ic_launcher_background' not in existing:
            # Insert before </resources>
            existing = existing.replace('</resources>', '    <color name="ic_launcher_background">#FFFFFF</color>\n</resources>')
            with open(colors_xml_path, 'w', encoding='utf-8') as f:
                f.write(existing)
            print(f"Updated {colors_xml_path}")
        else:
            print(f"colors.xml already contains ic_launcher_background")
    else:
        with open(colors_xml_path, 'w', encoding='utf-8') as f:
            f.write(colors_content)
        print(f"Created {colors_xml_path}")

    # 5. Create mipmap-anydpi-v26/ic_launcher.xml and ic_launcher_round.xml
    v26_dir = os.path.join(res_base, 'mipmap-anydpi-v26')
    os.makedirs(v26_dir, exist_ok=True)
    
    adaptive_xml = '''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
'''
    with open(os.path.join(v26_dir, 'ic_launcher.xml'), 'w', encoding='utf-8') as f:
        f.write(adaptive_xml)
    print(f"Created {v26_dir}/ic_launcher.xml")
    
    with open(os.path.join(v26_dir, 'ic_launcher_round.xml'), 'w', encoding='utf-8') as f:
        f.write(adaptive_xml)
    print(f"Created {v26_dir}/ic_launcher_round.xml")

if __name__ == '__main__':
    generate_icons()
