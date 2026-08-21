# ---------------------------------------------------------------------------
# phockup — Sony camera card → 4TB archive
#
# Override defaults by setting these in .zshenv or per-session:
#   export PHOCKUP_CARD="/media/gb/<your-card>"
#   export PHOCKUP_DST="/your/archive/path"
#
# Usage:
#   phockup-copy            — copy photos + videos, skip XMLs, fast dedup
#   phockup-copy --dry-run  — preview without writing anything
# ---------------------------------------------------------------------------
: "${PHOCKUP_CARD:=/media/gb/sdc1-usb-Sony_DSC_CFEFE06}"
: "${PHOCKUP_DST:=/media/gb/4tb-samsung/backups/photos backup/immich/dslr}"

_phockup_run() {
  local src="$1"; shift
  python3 /home/gb/code/phockup/phockup.py \
    "$src" "$PHOCKUP_DST" \
    --date "YYYY/YYYY-MM-DD" \
    --original-names \
    --exclude-ext xml \
    --skip-unknown \
    --shallow-dedup \
    --progress \
    "$@"
}

phockup-copy() {
  _phockup_run "$PHOCKUP_CARD/DCIM"                 "$@"
  _phockup_run "$PHOCKUP_CARD/PRIVATE/M4ROOT/CLIP"  "$@"
}

# Only define on machines with a battery (laptops)
if ls /sys/class/power_supply/ 2>/dev/null | grep -q '^BAT'; then
  bklit() {
    case "$1" in
      on)  sudo light -s sysfs/leds/tpacpi::kbd_backlight -S 50 ;;
      off) sudo light -s sysfs/leds/tpacpi::kbd_backlight -S 0 ;;
      *)   echo "Usage: bklit on|off" ;;
    esac
  }
fi
