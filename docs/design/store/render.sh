#!/bin/sh
# Renders every frame in frames.html to out/ as 24-bit PNG with no alpha (Play rejects alpha).
# Usage: sh docs/design/store/render.sh [frame ...]   e.g. sh render.sh p1 t3
set -e
cd "$(dirname "$0")"
EDGE="${EDGE:-/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe}"
mkdir -p out
FRAMES="${*:-p1 p2 p3 p4 p5 p6 p7 p8 s1 s2 s3 s4 s5 t1 t2 t3 t4 t5 t6}"
URL="file:///$(pwd -W 2>/dev/null || pwd)/frames.html"
for f in $FRAMES; do
  case $f in
    p*) size=1080,1920; name="phone-${f#p}" ;;
    s*) size=1920,1080; name="tablet7-${f#s}" ;;
    t*) size=2560,1440; name="tablet10-${f#t}" ;;
  esac
  "$EDGE" --headless --disable-gpu --hide-scrollbars --force-device-scale-factor=1 \
    --allow-file-access-from-files --virtual-time-budget=4000 \
    --window-size=$size --screenshot="$(pwd -W 2>/dev/null || pwd)/out/$name.png" "$URL#$f" >/dev/null 2>&1
  python -c "
from PIL import Image
im = Image.open('out/$name.png').convert('RGB')
w, h = map(int, '$size'.split(','))
assert im.size == (w, h), im.size
im.save('out/$name.png', optimize=True)
print('out/$name.png', im.size, im.mode)"
done
