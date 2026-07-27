# adb-device-select

Interactive ADB device picker for zsh. Run `select_device` to choose from connected Android devices — all subsequent `adb` commands in that terminal session automatically target the selected device via `ANDROID_SERIAL`, no `-s` flag needed.

```
Current: (none)

  ↑↓ navigate  ·  Enter select  ·  Esc/q cancel
  ● 100.71.50.80:41445  Pixel 7 Pro
  ○ 100.72.14.68:44663  Odin2 Portal
```

## Requirements

- zsh
- [Android SDK Platform Tools](https://developer.android.com/studio/releases/platform-tools) (`adb` in `PATH`)
- Optional: [fzf](https://github.com/junegunn/fzf) — enables fuzzy search instead of the arrow-key menu

## Installation

### oh-my-zsh

```zsh
git clone https://github.com/yourname/adb-device-select \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/adb-device-select
```

Add `adb-device-select` to the plugins list in `~/.zshrc`:

```zsh
plugins=(... adb-device-select)
```

Reload:

```zsh
source ~/.zshrc
```

### Manual (any zsh setup)

```zsh
git clone https://github.com/yourname/adb-device-select ~/adb-device-select
echo 'source ~/adb-device-select/adb-device-select.plugin.zsh' >> ~/.zshrc
source ~/.zshrc
```

## Usage

| Command | Description |
|---|---|
| `select_device` | Open the device picker and export `ANDROID_SERIAL` |
| `clear_device` | Unset the active device |

**Controls inside the picker:**

| Key | Action |
|---|---|
| `↑` / `↓` | Move selection |
| `Enter` | Confirm |
| `Esc` / `q` | Cancel |

Once a device is selected, all `adb` commands in that session go to it automatically:

```zsh
select_device        # pick a device
adb shell            # opens shell on the selected device — no -s flag needed
adb install app.apk  # installs to the selected device
adb logcat           # streams logs from the selected device
```

The selection only applies to the current terminal session. Open a new terminal tab and you start fresh.

## Prompt integration

### Powerlevel10k

The plugin defines an `adb_device` prompt segment. You need to opt in by adding it to `POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS` in your `~/.p10k.zsh`:

```zsh
typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
  # ... your existing elements ...
  adb_device    # ← add this line
  newline
  # ...
)
```

When a device is active, your right prompt shows:

```
📱 100.71.50.80:41445 · Pixel 7 Pro
```

It disappears automatically when no device is selected.

**Optional — customize colors** (also in `~/.p10k.zsh`):

```zsh
typeset -g POWERLEVEL9K_ADB_DEVICE_FOREGROUND=6   # 6 = cyan
typeset -g POWERLEVEL9K_ADB_DEVICE_BACKGROUND=0   # 0 = black (transparent-ish)
```

### Other zsh themes

Add this to your `~/.zshrc` after your theme is loaded. It uses a `precmd` hook to update `RPROMPT` dynamically:

```zsh
autoload -Uz add-zsh-hook
_adb_rprompt_hook() {
  if [[ -n $ANDROID_SERIAL ]]; then
    RPROMPT="%F{cyan}[📱 ${_ADB_MODEL:-$ANDROID_SERIAL}]%f"
  else
    RPROMPT=""
  fi
}
add-zsh-hook precmd _adb_rprompt_hook
```

> This may conflict with themes that manage `RPROMPT` themselves (e.g. via their own `precmd` hook). If the device name doesn't appear, check whether your theme overrides `RPROMPT` after the hook runs.

## How it works

`select_device` exports `ANDROID_SERIAL` — the standard environment variable that `adb` reads to target a specific device. No aliases or wrappers are involved; every `adb` subcommand honours it natively.

The interactive menu uses raw terminal mode (`stty -icanon`) to read single keypresses without requiring Enter. Terminal state is always restored on exit, including on `Ctrl-C`.
