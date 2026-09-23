#!/usr/bin/env python3
"""
Downloads Google Fonts TTF files used by Smriti Saathi into assets/fonts/
for complete offline bundling.

Ensures fonts are named with Google Fonts canonical names:
  <Family>-<Variant>.ttf  (e.g., Comfortaa-Regular.ttf, Comfortaa-Bold.ttf, DMSans-SemiBold.ttf)
so the flutter `google_fonts` package can load them directly from local assets
with zero network latency and 100% offline reliability.
"""

import os
import re
import urllib.request
import gzip

UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
OUT_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "assets", "fonts")

FAMILIES = [
    # Latin UI families
    ("DM Sans", "DM+Sans", "ital,wght@0,400;0,500;0,600;0,700;0,800;0,900;1,400;1,600"),
    ("Outfit", "Outfit", "wght@400;500;600;700;800;900"),
    ("Playfair Display", "Playfair+Display", "ital,wght@0,400;0,600;0,700;0,900;1,600"),
    ("Plus Jakarta Sans", "Plus+Jakarta+Sans", "wght@400;500;600;700;800"),
    ("Comfortaa", "Comfortaa", "wght@400;600;700"),
    ("Caveat", "Caveat", "wght@600;700"),
    ("Nunito", "Nunito", "wght@400;600;700;800;900"),

    # Indic script families
    ("Hind", "Hind", "wght@400;500;600;700"),
    ("Hind Siliguri", "Hind+Siliguri", "wght@400;500;600;700"),
    ("Noto Sans Tamil", "Noto+Sans+Tamil", "wght@400;500;600;700"),
    ("Noto Sans Telugu", "Noto+Sans+Telugu", "wght@400;500;600;700"),
    ("Noto Sans Kannada", "Noto+Sans+Kannada", "wght@400;500;600;700"),
    ("Noto Sans Malayalam", "Noto+Sans+Malayalam", "wght@400;500;600;700"),
    ("Noto Sans Gujarati", "Noto+Sans+Gujarati", "wght@400;500;600;700"),
    ("Noto Sans Gurmukhi", "Noto+Sans+Gurmukhi", "wght@400;500;600;700"),
    ("Noto Sans Oriya", "Noto+Sans+Oriya", "wght@400;500;600;700"),
]

WEIGHT_NAME_MAP = {
    "100": "Thin",
    "200": "ExtraLight",
    "300": "Light",
    "400": "Regular",
    "500": "Medium",
    "600": "SemiBold",
    "700": "Bold",
    "800": "ExtraBold",
    "900": "Black",
}

def get_variant_name(weight_str, style_str):
    weight_name = WEIGHT_NAME_MAP.get(weight_str, weight_str)
    if style_str == "italic":
        if weight_name == "Regular":
            return "Italic"
        return f"{weight_name}Italic"
    return weight_name

def download_family(disp, query, spec):
    url = f"https://fonts.googleapis.com/css2?family={query}:{spec}&display=swap"
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            css = resp.read().decode("utf-8")
    except Exception as e:
        print(f"  [ERROR] Failed to fetch CSS for {disp}: {e}")
        return []

    safe_family = disp.replace(" ", "")
    blocks = css.split("@font-face")
    downloaded = []

    for block in blocks[1:]:
        style = "italic" if "font-style: italic" in block else "normal"
        w_match = re.search(r"font-weight:\s*(\d+)", block)
        u_match = re.search(r"url\((https:[^)]+\.ttf)\)", block)

        if not (w_match and u_match):
            continue

        weight = w_match.group(1)
        ttf_url = u_match.group(1)
        variant = get_variant_name(weight, style)
        filename = f"{safe_family}-{variant}.ttf"
        filepath = os.path.join(OUT_DIR, filename)

        try:
            ttf_req = urllib.request.Request(ttf_url, headers={"User-Agent": UA})
            with urllib.request.urlopen(ttf_req, timeout=40) as ttf_resp:
                data = ttf_resp.read()
            with open(filepath, "wb") as f:
                f.write(data)
            size_kb = len(data) / 1024.0
            gz_kb = len(gzip.compress(data)) / 1024.0
            print(f"  + {filename:35s} {size_kb:6.1f} KB (compressed: {gz_kb:5.1f} KB)")
            downloaded.append((filename, len(data), len(gzip.compress(data))))
        except Exception as e:
            print(f"  [ERROR] Failed to download {filename}: {e}")

    return downloaded

def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    print("=" * 65)
    print(f"Downloading Google Fonts into: {OUT_DIR}")
    print("=" * 65)

    all_downloads = []
    for disp, query, spec in FAMILIES:
        print(f"\n>> Family: {disp}")
        results = download_family(disp, query, spec)
        all_downloads.extend(results)

    total_raw = sum(raw for _, raw, _ in all_downloads)
    total_gz = sum(gz for _, _, gz in all_downloads)

    print("\n" + "=" * 65)
    print("DOWNLOAD COMPLETE SUMMARY")
    print("=" * 65)
    print(f"Total Font Files Downloaded : {len(all_downloads)}")
    print(f"Total Uncompressed Size     : {total_raw / (1024 * 1024):.2f} MB ({total_raw / 1024:,.1f} KB)")
    print(f"Total APK/Bundle Size Impact: {total_gz / (1024 * 1024):.2f} MB ({total_gz / 1024:,.1f} KB compressed)")
    print("=" * 65)

if __name__ == "__main__":
    main()
