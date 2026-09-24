import os
import math
from PIL import Image, ImageDraw

def generate_all():
    src_path = 'assets/images/logo_1024.png'
    src = Image.open(src_path).convert('RGBA')
    
    # 1. Precise content crop
    bbox = src.getchannel('A').getbbox()
    content = src.crop(bbox)
    cw, ch = content.size
    cx, cy = cw / 2.0, ch / 2.0
    
    # Find exact maximum radius of non-transparent pixel from center
    max_radius = 0
    for y in range(ch):
        for x in range(cw):
            if content.getpixel((x, y))[3] > 15:
                r = math.sqrt((x - cx)**2 + (y - cy)**2)
                if r > max_radius:
                    max_radius = r
                    
    print(f"Content size: {cw}x{ch}, center: ({cx}, {cy}), max_radius: {max_radius:.2f}px")
    
    res_base = 'android/app/src/main/res'
    
    # ==========================================
    # A. ANDROID 12+ SPLASH SCREEN (android12splash.png)
    # Android 12 mask is a circle of diameter 160dp on a 288dp grid.
    # Radius = (80 / 288) * canvas_size = ~0.2777 * canvas_size.
    # We target max_radius = 0.88 * (80 / 288) * canvas_size = 0.2444 * canvas_size
    # ==========================================
    splash_sizes = {
        'mdpi': 256,
        'hdpi': 384,
        'xhdpi': 512,
        'xxhdpi': 768,
        'xxxhdpi': 1024
    }
    
    splash_folders = [
        'drawable-mdpi', 'drawable-hdpi', 'drawable-xhdpi', 'drawable-xxhdpi', 'drawable-xxxhdpi',
        'drawable-night-mdpi', 'drawable-night-hdpi', 'drawable-night-xhdpi', 'drawable-night-xxhdpi', 'drawable-night-xxxhdpi'
    ]
    
    for folder in splash_folders:
        density = folder.split('-')[-1]
        canvas_size = splash_sizes[density]
        folder_path = os.path.join(res_base, folder)
        os.makedirs(folder_path, exist_ok=True)
        
        target_r = 0.88 * (80.0 / 288.0) * canvas_size
        scale = target_r / max_radius
        new_w = int(cw * scale)
        new_h = int(ch * scale)
        scaled_content = content.resize((new_w, new_h), Image.Resampling.LANCZOS)
        
        canvas = Image.new('RGBA', (canvas_size, canvas_size), (0, 0, 0, 0))
        ox = (canvas_size - new_w) // 2
        oy = (canvas_size - new_h) // 2
        canvas.paste(scaled_content, (ox, oy), scaled_content)
        
        out_path = os.path.join(folder_path, 'android12splash.png')
        canvas.save(out_path, 'PNG')
        print(f"Generated {out_path} ({canvas_size}x{canvas_size}, logo: {new_w}x{new_h})")

    # ==========================================
    # B. LEGACY SPLASH SCREEN (splash.png) for Android < 12
    # Fits comfortably in center of screen
    # ==========================================
    legacy_splash_sizes = {
        'drawable-mdpi': 128,
        'drawable-hdpi': 192,
        'drawable-xhdpi': 256,
        'drawable-xxhdpi': 384,
        'drawable-xxxhdpi': 512
    }
    for folder, canvas_size in legacy_splash_sizes.items():
        folder_path = os.path.join(res_base, folder)
        os.makedirs(folder_path, exist_ok=True)
        
        target_content_size = int(canvas_size * 0.75)
        scale = target_content_size / max(cw, ch)
        new_w = int(cw * scale)
        new_h = int(ch * scale)
        scaled_content = content.resize((new_w, new_h), Image.Resampling.LANCZOS)
        
        canvas = Image.new('RGBA', (canvas_size, canvas_size), (0, 0, 0, 0))
        ox = (canvas_size - new_w) // 2
        oy = (canvas_size - new_h) // 2
        canvas.paste(scaled_content, (ox, oy), scaled_content)
        
        out_path = os.path.join(folder_path, 'splash.png')
        canvas.save(out_path, 'PNG')
        print(f"Generated {out_path} ({canvas_size}x{canvas_size}, logo: {new_w}x{new_h})")

    # ==========================================
    # C. ADAPTIVE LAUNCHER FOREGROUND (ic_launcher_foreground.png)
    # Android adaptive icon mask is a circle of diameter 72dp on 108dp canvas (r = 36dp).
    # Radius = (36 / 108) * canvas_size = 0.333 * canvas_size.
    # We target max_radius = 0.86 * (36 / 108) * canvas_size = 0.2866 * canvas_size
    # This guarantees 0% clipping on all Android adaptive masks!
    # ==========================================
    adaptive_sizes = {
        'mipmap-mdpi': 108,
        'mipmap-hdpi': 162,
        'mipmap-xhdpi': 216,
        'mipmap-xxhdpi': 324,
        'mipmap-xxxhdpi': 432
    }
    
    for folder, canvas_size in adaptive_sizes.items():
        folder_path = os.path.join(res_base, folder)
        os.makedirs(folder_path, exist_ok=True)
        
        target_r = 0.86 * (36.0 / 108.0) * canvas_size
        scale = target_r / max_radius
        new_w = int(cw * scale)
        new_h = int(ch * scale)
        scaled_content = content.resize((new_w, new_h), Image.Resampling.LANCZOS)
        
        canvas = Image.new('RGBA', (canvas_size, canvas_size), (0, 0, 0, 0))
        ox = (canvas_size - new_w) // 2
        oy = (canvas_size - new_h) // 2
        canvas.paste(scaled_content, (ox, oy), scaled_content)
        
        out_path = os.path.join(folder_path, 'ic_launcher_foreground.png')
        canvas.save(out_path, 'PNG')
        print(f"Generated {out_path} ({canvas_size}x{canvas_size}, logo: {new_w}x{new_h})")

    # ==========================================
    # D. LEGACY SQUARE & ROUND ICONS (ic_launcher.png & ic_launcher_round.png)
    # ==========================================
    legacy_icon_sizes = {
        'mipmap-mdpi': 48,
        'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192
    }
    
    for folder, canvas_size in legacy_icon_sizes.items():
        folder_path = os.path.join(res_base, folder)
        os.makedirs(folder_path, exist_ok=True)
        
        target_r = 0.82 * (canvas_size / 2.0)
        scale = target_r / max_radius
        new_w = int(cw * scale)
        new_h = int(ch * scale)
        scaled_content = content.resize((new_w, new_h), Image.Resampling.LANCZOS)
        
        # 1) Square / Rounded Rect
        bg_sq = Image.new('RGBA', (canvas_size, canvas_size), (255, 255, 255, 255))
        mask_sq = Image.new('L', (canvas_size, canvas_size), 0)
        draw_sq = ImageDraw.Draw(mask_sq)
        draw_sq.rounded_rectangle([(0, 0), (canvas_size - 1, canvas_size - 1)], radius=int(canvas_size * 0.22), fill=255)
        
        ox = (canvas_size - new_w) // 2
        oy = (canvas_size - new_h) // 2
        bg_sq.paste(scaled_content, (ox, oy), scaled_content)
        icon_sq = Image.new('RGBA', (canvas_size, canvas_size), (0, 0, 0, 0))
        icon_sq.paste(bg_sq, (0, 0), mask_sq)
        
        out_sq = os.path.join(folder_path, 'ic_launcher.png')
        icon_sq.save(out_sq, 'PNG')
        
        # 2) Round
        bg_rd = Image.new('RGBA', (canvas_size, canvas_size), (255, 255, 255, 255))
        mask_rd = Image.new('L', (canvas_size, canvas_size), 0)
        draw_rd = ImageDraw.Draw(mask_rd)
        draw_rd.ellipse([(0, 0), (canvas_size - 1, canvas_size - 1)], fill=255)
        
        bg_rd.paste(scaled_content, (ox, oy), scaled_content)
        icon_rd = Image.new('RGBA', (canvas_size, canvas_size), (0, 0, 0, 0))
        icon_rd.paste(bg_rd, (0, 0), mask_rd)
        
        out_rd = os.path.join(folder_path, 'ic_launcher_round.png')
        icon_rd.save(out_rd, 'PNG')
        print(f"Generated {out_sq} and {out_rd} ({canvas_size}x{canvas_size})")

    print("\n>>> ALL ANDROID ASSETS SUCCESSFULLY REGENERATED WITH ZERO CLIPPING! <<<")

if __name__ == '__main__':
    generate_all()
