# ThinkPad X1 Carbon Setup (i3wm, Debian)

Display: 3840x2400 on ~14" panel (~323 DPI), running i3wm on X11.

## The Problem

X11 has no unified HiDPI scaling. Setting `Xft.dpi: 192` alongside `GDK_SCALE=2` causes
double-scaling — apps that respond to both end up at 4x. The fix is to keep `Xft.dpi: 96`
(standard) and let `GDK_SCALE=2` be the single source of truth.

## ~/.Xresources

```
Xft.dpi: 96
Xcursor.size: 48
```

## ~/.xprofile

Loaded at login by GDM — sets scaling env vars before any app starts.

```sh
export GDK_SCALE=2
export GDK_DPI_SCALE=1
export QT_SCALE_FACTOR=2
export QT_AUTO_SCREEN_SCALE_FACTOR=0
export XCURSOR_SIZE=48
```

## ~/.config/i3/config

```
# Font — double the default size for HiDPI
font pango:monospace 24

# Apply DPI and Xresources on startup
exec --no-startup-id xrdb -merge ~/.Xresources
exec_always --no-startup-id xrandr --dpi 96

# dmenu — pass font size explicitly since it ignores GDK_SCALE
bindsym $mod+d exec --no-startup-id dmenu_run -fn 'monospace:size=20'

# Touchpad
exec xinput set-prop "SYNA8008:00 06CB:CE58 Touchpad" "libinput Tapping Enabled" 1
exec xinput set-prop "SYNA8008:00 06CB:CE58 Touchpad" "libinput Natural Scrolling Enabled" 1
exec xinput set-prop "SYNA8008:00 06CB:CE58 Touchpad" "libinput Accel Speed" 0.4
```

## GDM Login Screen

GDM3 runs its own Wayland session and needs a separate monitor config.
Create `/var/lib/gdm3/.config/monitors.xml`:

```xml
<monitors version="2">
  <configuration>
    <logicalmonitor>
      <x>0</x>
      <y>0</y>
      <scale>2</scale>
      <primary>true</primary>
      <monitor>
        <monitorspec>
          <connector>eDP-1</connector>
          <vendor>unknown</vendor>
          <product>unknown</product>
          <serial>unknown</serial>
        </monitorspec>
        <mode>
          <width>3840</width>
          <height>2400</height>
          <rate>60.000</rate>
        </mode>
      </monitor>
    </logicalmonitor>
  </configuration>
</monitors>
```

Then fix ownership (Debian uses `Debian-gdm`, not `gdm`):

```sh
sudo chown -R Debian-gdm:Debian-gdm /var/lib/gdm3/.config
```

## What Doesn't Work Automatically

i3bar and dmenu are pure X11 and ignore `GDK_SCALE` — font sizes must be set manually
(see i3 config above).

## Function Keys

Debian with i3 uses PipeWire (not PulseAudio) — the default i3 config uses `pactl` which
won't be installed. Use `wpctl` instead. Also requires `brightnessctl` for brightness keys:

```sh
sudo apt-get install brightnessctl
```

Bindings in `~/.config/i3/config`:

```
bindsym XF86AudioRaiseVolume exec --no-startup-id wpctl set-volume @DEFAULT_AUDIO_SINK@ 10%+ && $refresh_i3status
bindsym XF86AudioLowerVolume exec --no-startup-id wpctl set-volume @DEFAULT_AUDIO_SINK@ 10%- && $refresh_i3status
bindsym XF86AudioMute exec --no-startup-id wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && $refresh_i3status
bindsym XF86AudioMicMute exec --no-startup-id wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle && $refresh_i3status
bindsym XF86MonBrightnessUp exec --no-startup-id brightnessctl set 10%+
bindsym XF86MonBrightnessDown exec --no-startup-id brightnessctl set 10%-
```

Note: if brightness keys don't work, run `xev` to confirm they send `XF86MonBrightnessUp/Down`
and not plain `F5`/`F6` — depends on Fn lock state.

## Applying Changes

Requires a full logout/reboot since `.xprofile` only loads at login.
