#!/usr/bin/env bash
# Downloads Google Fonts TTFs used by the app into assets/fonts/ for offline bundling.
set -u
UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120 Safari/537.36"
OUT="assets/fonts"
mkdir -p "$OUT"

# family_query "Family Name|css-family-with-plus|wght-spec"
# For each, we fetch css2, extract (weight,style,url) and save Family-<weight>[-Italic].ttf
fetch() {
  disp="$1"; q="$2"; spec="$3"
  url="https://fonts.googleapis.com/css2?family=${q}:${spec}&display=swap"
  css="$(curl -sSL --max-time 40 -A "$UA" "$url")"
  if [ -z "$css" ]; then echo "  !! no css for $disp"; return; fi
  # Split into @font-face blocks, pull style, weight, ttf url -> temp file
  printf '%s' "$css" | awk 'BEGIN{RS="@font-face";FS="\n"}
    { style="normal"; weight=""; u=""
      for(i=1;i<=NF;i++){
        if($i ~ /font-style:/){ if($i ~ /italic/) style="italic" }
        if($i ~ /font-weight:/){ w=$i; gsub(/[^0-9]/,"",w); weight=w }
        if($i ~ /\.ttf/){ match($i,/https:[^) ]+\.ttf/); u=substr($i,RSTART,RLENGTH) }
      }
      if(u!="" && weight!="") print weight"\t"style"\t"u
    }' > /tmp/_ff.txt
  safe="${disp// /}"
  while IFS=$'\t' read -r w s u; do
    [ -z "$u" ] && continue
    name="$OUT/${safe}-${w}"
    [ "$s" = "italic" ] && name="${name}-Italic"
    name="${name}.ttf"
    curl -sSL --max-time 40 -A "$UA" "$u" -o "$name"
    echo "  + $(basename "$name") ($(wc -c < "$name" 2>/dev/null) bytes)"
  done < /tmp/_ff.txt
}

echo "== Latin UI families =="
fetch "DM Sans"            "DM+Sans"            "ital,wght@0,400;0,500;0,600;0,700;0,800;1,400;1,600"
fetch "Outfit"             "Outfit"             "wght@400;500;600;700;800"
fetch "Playfair Display"   "Playfair+Display"   "ital,wght@0,400;0,600;0,700;1,600"
fetch "Plus Jakarta Sans"  "Plus+Jakarta+Sans"  "wght@400;500;600;700;800"
fetch "Comfortaa"          "Comfortaa"          "wght@400;600;700"
fetch "Caveat"             "Caveat"             "wght@600;700"
fetch "Nunito"             "Nunito"             "wght@400;600;700;800"

echo "== Indic script families =="
fetch "Hind"               "Hind"               "wght@400;500;600;700"
fetch "Hind Siliguri"      "Hind+Siliguri"      "wght@400;500;600;700"
fetch "Noto Sans Tamil"    "Noto+Sans+Tamil"    "wght@400;500;600;700"
fetch "Noto Sans Telugu"   "Noto+Sans+Telugu"   "wght@400;500;600;700"
fetch "Noto Sans Kannada"  "Noto+Sans+Kannada"  "wght@400;500;600;700"
fetch "Noto Sans Malayalam" "Noto+Sans+Malayalam" "wght@400;500;600;700"
fetch "Noto Sans Gujarati" "Noto+Sans+Gujarati" "wght@400;500;600;700"
fetch "Noto Sans Gurmukhi" "Noto+Sans+Gurmukhi" "wght@400;500;600;700"
fetch "Noto Sans Oriya"    "Noto+Sans+Oriya"    "wght@400;500;600;700"

echo "== done =="
ls -1 "$OUT" | wc -l
