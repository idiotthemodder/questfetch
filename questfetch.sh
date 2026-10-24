#!/system/bin/sh
# questfetch 1.1 - fastfetch style system info for rooted Quest headsets
# based on qfetch from QuestRootResearch/Quest-Root-Research (GPL-3.0)

VERSION="1.1"

usage() {
  echo "questfetch $VERSION"
  echo "usage: questfetch [options]"
  echo "  -m, --meta         force the meta logo"
  echo "  -o, --oculus       force the oculus logo"
  echo "  -n, --nologo       no logo"
  echo "  -r, --random       random logo"
  echo "  -c, --color NAME   blue purple rainbow sunset white mint fire"
  echo "  -l, --list         show all color themes"
  echo "  -w, --watch        live mode, refreshes every 2s (ctrl+c to stop)"
  echo "  -h, --help         this help"
}

ESC="$(printf '\033')"
B="${ESC}[1m"
R="${ESC}[0m"
DIM="${ESC}[2m"

# ---------- themes (256 color codes, top to bottom) ----------
palette() {
  case "$1" in
    purple)  PAL="54 91 128 165 201" ;;
    rainbow) PAL="196 208 226 46 51 21 129" ;;
    sunset)  PAL="197 203 209 215 221" ;;
    white)   PAL="255 253 251 249 247" ;;
    mint)    PAL="29 35 41 48 85" ;;
    fire)    PAL="124 160 196 208 220" ;;
    *)       PAL="27 33 39 45 51" ;;
  esac
}

# ---------- arguments ----------
MODE=""
THEME=""
WATCH=0
PASS=""
while [ $# -gt 0 ]; do
  case "$1" in
    -o|--oculus) MODE=oculus; PASS="$PASS -o" ;;
    -m|--meta) MODE=meta; PASS="$PASS -m" ;;
    -n|--nologo) MODE=none; PASS="$PASS -n" ;;
    -r|--random)
      if [ $(( $(date +%s) % 2 )) -eq 0 ]; then MODE=meta; else MODE=oculus; fi
      PASS="$PASS -r" ;;
    -c|--color) shift; THEME="$1"; PASS="$PASS -c $1" ;;
    -w|--watch) WATCH=1 ;;
    -l|--list)
      for t in blue purple rainbow sunset white mint fire; do
        palette "$t"
        printf '%-9s' "$t"
        for c in $PAL; do printf '%s' "${ESC}[48;5;${c}m    ${R}"; done
        printf '\n'
      done
      exit 0 ;;
    -h|--help) usage; exit 0 ;;
  esac
  shift
done

if [ "$WATCH" = "1" ]; then
  while :; do
    printf '\033[H\033[2J'
    sh "$0" $PASS
    sleep 2
  done
  exit 0
fi

# ---------- auto detect: old (oculus era) vs new (meta era) ----------
DEV="$(getprop ro.product.device)"
MAKER="$(getprop ro.product.manufacturer) $(getprop ro.product.brand)"
GEN=new
case "$DEV" in
  monterey|pacific) GEN=old ;;
  hollywood)
    case "$MAKER" in
      *[Oo]culus*) GEN=old ;;
    esac ;;
esac

if [ -z "$MODE" ]; then
  if [ "$GEN" = "old" ]; then MODE=oculus; else MODE=meta; fi
fi

if [ -z "$THEME" ]; then
  case "$MODE" in
    oculus) THEME=white ;;
    meta) THEME=blue ;;
    *)
      if [ "$GEN" = "old" ]; then THEME=white; else THEME=blue; fi ;;
  esac
fi

palette "$THEME"

# pick color for row $1 of $2 from the palette
gradcolor() {
  r=$1; t=$2
  set -- $PAL
  cnt=$#
  idx=$(( (r - 1) * cnt / t + 1 ))
  eval "echo \${$idx}"
}

# accent color = middle of the palette
set -- $PAL
mid=$(( ($# + 1) / 2 ))
eval "ACCN=\${$mid}"
ACC="${ESC}[1;38;5;${ACCN}m"

GOOD="${ESC}[1;38;5;78m"
BAD="${ESC}[1;38;5;203m"
WARN="${ESC}[1;38;5;220m"

# colored 10 segment bar: bar PERCENT [1 = low is bad]
bar() {
  pct=$1; inv=$2
  [ -z "$pct" ] && pct=0
  [ "$pct" -gt 100 ] && pct=100
  [ "$pct" -lt 0 ] && pct=0
  filled=$(( pct / 10 ))
  if [ "$inv" = "1" ]; then lvl=$(( 100 - pct )); else lvl=$pct; fi
  if [ "$lvl" -ge 80 ]; then c=203; elif [ "$lvl" -ge 55 ]; then c=220; else c=78; fi
  s="${ESC}[38;5;${c}m"
  i=0
  while [ "$i" -lt "$filled" ]; do s="${s}━"; i=$((i + 1)); done
  s="${s}${ESC}[38;5;240m"
  while [ "$i" -lt 10 ]; do s="${s}─"; i=$((i + 1)); done
  echo "${s}${R}"
}

# string of N box line characters
rule() {
  out=""
  k=0
  while [ "$k" -lt "$1" ]; do out="${out}─"; k=$((k + 1)); done
  echo "$out"
}

p() { getprop "$1" 2>/dev/null; }

# ---------- gather info ----------
MODEL="$(p ro.product.model)"
CODENAME="$(p ro.product.device)"
HOSTN="${CODENAME:-quest}"
USER_N="$(id -un 2>/dev/null)"
[ -z "$USER_N" ] && USER_N="uid$(id -u)"

HOS="$(p ro.vros.build.version)"
ANDROID="$(p ro.build.version.release)"
PATCH="$(p ro.build.version.security_patch)"
BUILD="$(p ro.build.display.id)"
KERNEL="$(uname -r)"
ARCH="$(uname -m)"

CPU="$(p ro.soc.model)"
[ -z "$CPU" ] && CPU="$(p ro.hardware)"
[ -z "$CPU" ] && CPU="Unknown"
CORES="$(grep -c '^processor' /proc/cpuinfo 2>/dev/null)"
[ -n "$CORES" ] && CPU="$CPU ($CORES cores)"

GPU="$(cat /sys/class/kgsl/kgsl-3d0/gpu_model 2>/dev/null)"
[ -z "$GPU" ] && GPU="$(p ro.hardware.egl)"
[ -z "$GPU" ] && GPU="$(p ro.gfx.driver.0)"
[ -z "$GPU" ] && GPU="Unknown"

GPUBUSY="$(cat /sys/class/kgsl/kgsl-3d0/gpu_busy_percentage 2>/dev/null | tr -dc '0-9')"
GPULOAD=""
[ -n "$GPUBUSY" ] && GPULOAD="$(bar "$GPUBUSY") ${GPUBUSY}%"

CPUT=""
for z in /sys/class/thermal/thermal_zone*; do
  t="$(cat "$z/type" 2>/dev/null)"
  case "$t" in
    *cpu*|*CPU*|*cluster*)
      v="$(cat "$z/temp" 2>/dev/null)"
      if [ -n "$v" ] && [ "$v" -gt 0 ] 2>/dev/null; then
        [ "$v" -gt 1000 ] && v=$(( v / 1000 ))
        if [ -z "$CPUT" ] || [ "$v" -gt "$CPUT" ]; then CPUT=$v; fi
      fi ;;
  esac
done
CPUTEMP=""
[ -n "$CPUT" ] && CPUTEMP="${CPUT}C"

MT="$(grep MemTotal /proc/meminfo 2>/dev/null | tr -s ' ' | cut -d' ' -f2)"
MA="$(grep MemAvailable /proc/meminfo 2>/dev/null | tr -s ' ' | cut -d' ' -f2)"
if [ -n "$MT" ] && [ -n "$MA" ]; then
  USED=$(( (MT - MA) / 1024 ))
  TOTAL=$(( MT / 1024 ))
  RPCT=$(( USED * 100 / TOTAL ))
  RAM="$(bar $RPCT) ${USED} / ${TOTAL} MiB (${RPCT}%)"
else
  RAM="Unknown"
fi

STORAGE="Unknown"
set -- $(df -h /data 2>/dev/null | tail -n 1)
if [ -n "$3" ]; then
  SPCT="$(echo "$5" | tr -d '%')"
  STORAGE="$(bar "$SPCT") $3 / $2 (${SPCT}%)"
fi

UPTIME="Unknown"
UP="$(cut -d. -f1 /proc/uptime 2>/dev/null)"
if [ -n "$UP" ]; then
  d=$((UP / 86400)); h=$(((UP % 86400) / 3600)); m=$(((UP % 3600) / 60))
  UPTIME="${h}h ${m}m"
  [ "$d" -gt 0 ] && UPTIME="${d}d $UPTIME"
fi

BAT="$(cat /sys/class/power_supply/battery/capacity 2>/dev/null)"
BST="$(cat /sys/class/power_supply/battery/status 2>/dev/null)"
BTMP="$(cat /sys/class/power_supply/battery/temp 2>/dev/null)"
BATTERY="$(bar "${BAT:-0}" 1) ${BAT:-?}% (${BST:-?})"
[ -n "$BTMP" ] && BATTERY="$BATTERY ${DIM}$((BTMP / 10)).$((BTMP % 10))C${R}"

HOME_PROCESS="$(
  cmd package resolve-activity \
    -c android.intent.category.HOME \
    -a android.intent.action.MAIN 2>/dev/null |
    grep 'processName=' | head -n 1 |
    sed 's/.*processName=//' | sed 's/ .*//'
)"
[ -z "$HOME_PROCESS" ] && HOME_PROCESS="Unknown"

if [ "$(id -u)" = "0" ]; then ROOT="${GOOD}yes${R}"; else ROOT="${BAD}no${R}"; fi

SLOT="$(p ro.boot.slot_suffix)"
[ -z "$SLOT" ] && SLOT="Unknown"

RES="$(wm size 2>/dev/null | head -n 1 | sed 's/.*: //')"
[ -z "$RES" ] && RES="Unknown"

PKGS="$(pm list packages 2>/dev/null | wc -l)"

SEL="$(getenforce 2>/dev/null)"
[ -z "$SEL" ] && SEL="Unknown"

MAGISK="$(magisk -v 2>/dev/null)"
[ -z "$MAGISK" ] && MAGISK="Unknown"

if pidof frida-server >/dev/null 2>&1; then
  FRIDA="${GOOD}running${R}"
else
  FRIDA="${DIM}stopped${R}"
fi

IP="$(ip -4 addr show wlan0 2>/dev/null | sed -n 's/.*inet \([0-9.]*\).*/\1/p' | head -n 1)"
[ -z "$IP" ] && IP="Unknown"

# ---------- logos ----------
logo_meta() {
  LROWS=12
  L1='      .####=.       .****-.'
  L2='    #########*=   +*********.'
  L3='  -####=:.:*****:***-.   .***+.'
  L4=' -###+.     .#****+.       ****.'
  L5='.***+.        ****#.        ***-'
  L6='****:        *******.       .***.'
  L7='***+.       ***-.****:      .***:'
  L8='***-      -***-  .#***:      ***-'
  L9='***=     ****-.   .#***=     ***-'
  L10='****.  :****:       +****.  +***:'
  L11='.*********=.         .*********-'
  L12='  .+****=.             :*****=.'
}

logo_oculus() {
  LROWS=11
  L1='      -@@@@@@@@@@@@@@@@@%:'
  L2='   +@@@@@@@@@@@@@@@@@@@@@@@@='
  L3=' .@@@@@@@@@@@@@@@@@@@@@@@@@@@@'
  L4='.@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.'
  L5='@@@@@@@                 .@@@@@@@'
  L6='@@@@@@#                  %@@@@@@'
  L7='@@@@@@@                 .@@@@@@@'
  L8='.@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@'
  L9=' .@@@@@@@@@@@@@@@@@@@@@@@@@@@@.'
  L10='   =@@@@@@@@@@@@@@@@@@@@@@@@-'
  L11='      :%@@@@@@@@@@@@@@@@%.'
}

case "$MODE" in
  oculus) logo_oculus ;;
  none) LROWS=0 ;;
  *) logo_meta ;;
esac

# ---------- info rows ----------
n=0
add() { n=$((n + 1)); eval "I$n=\"\$1\""; }
kv() { add "${ACC}$(printf '%-12s' "$1")${R}$2"; }
kvo() { [ -n "$2" ] && kv "$1" "$2"; }
sec() {
  len=$(( 38 - ${#1} ))
  add "${ACC}▌${R}${B}$1${R} ${DIM}$(rule $len)${R}"
}

add "${ACC}${USER_N}${R}${DIM}@${R}${ACC}${HOSTN}${R}"
add "${DIM}$(rule 40)${R}"

sec "System"
kv "Device" "$MODEL"
kv "Codename" "$CODENAME"
kv "Horizon OS" "${HOS:-Unknown}"
kv "Android" "$ANDROID"
kv "Patch" "$PATCH"
kv "Build" "$BUILD"
kv "Kernel" "$KERNEL"
kv "Arch" "$ARCH"
kv "Uptime" "$UPTIME"

sec "Hardware"
kv "CPU" "$CPU"
kvo "CPU temp" "$CPUTEMP"
kv "GPU" "$GPU"
kvo "GPU load" "$GPULOAD"
kv "RAM" "$RAM"
kv "Storage" "$STORAGE"
kv "Display" "$RES"
kv "Battery" "$BATTERY"

sec "Software"
kv "Shell" "$HOME_PROCESS"
kv "Packages" "$PKGS"
kv "Slot" "$SLOT"
kv "IP" "$IP"

sec "Root"
kv "SELinux" "$SEL"
kv "Magisk" "$MAGISK"
kv "Frida" "$FRIDA"
kv "Root" "$ROOT"

add ""
BLK=""
for c in 0 1 2 3 4 5 6 7; do BLK="${BLK}${ESC}[4${c}m   "; done
BLK="${BLK}${R}"
add "$BLK"
BLK=""
for c in 0 1 2 3 4 5 6 7; do BLK="${BLK}${ESC}[10${c}m   "; done
BLK="${BLK}${R}"
add "$BLK"
add "${DIM}questfetch ${VERSION}${R}"

# ---------- print side by side ----------
total=$n
[ "$LROWS" -gt "$total" ] && total=$LROWS

printf '\n'
i=1
while [ "$i" -le "$total" ]; do
  if [ "$MODE" != "none" ]; then
    l=""
    gc="$ACCN"
    if [ "$i" -le "$LROWS" ]; then
      eval "l=\$L$i"
      gc="$(gradcolor "$i" "$LROWS")"
    fi
    printf '%s%-36s%s  ' "${ESC}[1;38;5;${gc}m" "$l" "$R"
  fi
  r=""
  eval "r=\$I$i"
  printf '%s\n' "$r"
  i=$((i + 1))
done
printf '\n'
