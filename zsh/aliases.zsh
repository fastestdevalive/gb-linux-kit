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
