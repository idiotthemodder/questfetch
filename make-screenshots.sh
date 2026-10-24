#!/usr/bin/env bash
# regenerates all README screenshots (needs freeze + a connected headset)
set -e

OUT="$(cd "$(dirname "$0")" && pwd)/screenshots"
mkdir -p "$OUT"

shot() {
  name="$1"; shift
  questfetch "$@" | tr -d '\r' | freeze \
    --language ansi \
    --window \
    --padding 24 \
    --margin 0 \
    --background "#1a1b26" \
    --font.size 14 \
    -o "$OUT/$name.png"
  echo "made $name.png"
}

shot default
shot oculus -o
shot purple -c purple
shot rainbow -c rainbow
shot sunset -c sunset
shot mint -c mint
shot fire -c fire
shot white -c white
shot nologo -n
