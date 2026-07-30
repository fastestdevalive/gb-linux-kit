# gb-linux-kit

Personal terminal and desktop bootstrap for Linux (Debian-based) and macOS.

## What this sets up

- **Shell & Prompt**: Zsh with Oh My Zsh, Powerlevel10k prompt, history-prefix search, and smart completion
- **Zsh Plugins**: Autosuggestions (history + completion strategy), syntax highlighting, and interactive ADB device picker (`adb-device-select`)
- **Tiling Window Manager**:
  - **macOS**: [AeroSpace](https://github.com/nikitabobko/AeroSpace) — i3-like tree tiling window manager with Alt-based keybindings
  - **Linux**: [i3](https://i3wm.org/) — separate configs for laptop (Mod1/Alt) and workstation (Mod4/Super)
- **Editor**: Vim with Code Dark theme (VS Code inspired) and unified clipboard support
- **Terminal Emulator**: Alacritty solarized dark theme and keybindings
- **Nerd Fonts**: Automatically installs `MesloLGS NF` for Powerlevel10k icons

## Repo layout

```
scripts/bootstrap.sh       — idempotent setup script (auto-detects macOS vs Linux laptop/workstation)
zsh/.zshrc                 — Zsh config (supports Oh My Zsh, portable across Linux and macOS)
zsh/.p10k.zsh              — Powerlevel10k prompt config (with adb-device segment)
zsh/aliases.zsh            — shell aliases and functions
zsh/plugins/               — bundled plugins (e.g. adb-device-select)
aerospace/aerospace.toml   — AeroSpace config for macOS (i3-like bindings, gaps, tiling)
i3/config.laptop           — i3 config for Linux laptops: Mod1 (Alt), touchpad, brightness keys
i3/config.workstation      — i3 config for Linux workstations: Mod4 (Super), no touchpad
vim/.vimrc                 — Vim config (portable clipboard, code-dark theme)
alacritty/alacritty.toml   — Alacritty terminal configuration
```

## Usage on a new machine

```bash
git clone https://github.com/fastestdevalive/gb-linux-kit.git ~/code/gb-linux-kit
bash ~/code/gb-linux-kit/scripts/bootstrap.sh
```

### Auto-Detection & Overrides

- **macOS**: Automatically detected (`Darwin`). Installs Zsh, Oh My Zsh, Alacritty, AeroSpace, Powerlevel10k, plugins, and Nerd Fonts. Configures `~/.config/aerospace/aerospace.toml` and skips Linux-only i3/X11 tools.
- **Linux**: Automatically detected. Installs base apt packages, i3 window manager, GNOME Terminal profile, Zsh, Vim, and Alacritty. Machine type (`laptop` vs `workstation`) is detected by battery presence.

To manually override OS or machine type:

```bash
# Force macOS setup
bash ~/code/gb-linux-kit/scripts/bootstrap.sh --os mac

# Force Linux workstation setup
bash ~/code/gb-linux-kit/scripts/bootstrap.sh --os linux --machine workstation

# Force Linux laptop setup
bash ~/code/gb-linux-kit/scripts/bootstrap.sh --os linux --machine laptop
```

## Window Management (i3 & AeroSpace Shortcuts)

Both i3 (Linux) and AeroSpace (macOS) share consistent keybindings:

| Action | Shortcut |
|---|---|
| Launch Terminal | `Alt + Enter` |
| Focus Window | `Alt + h / j / k / l` (or arrow keys) |
| Move Window | `Alt + Shift + h / j / k / l` |
| Switch Workspace | `Alt + 1` .. `Alt + 9` |
| Move Window to Workspace | `Alt + Shift + 1` .. `Alt + Shift + 9` |
| Toggle Fullscreen | `Alt + f` |
| Toggle Floating | `Alt + Shift + Space` |
| Reload Config | `Alt + Shift + c` / `Alt + Shift + r` |

## After bootstrap finishes

1. **Terminal**:
   - Restart terminal or run:
     ```bash
     exec zsh
     ```
   - Make sure your terminal font is set to **MesloLGS NF** (automatically installed into `~/Library/Fonts/` on macOS).
2. **AeroSpace (macOS)**:
   - Launch `AeroSpace.app` from `/Applications/` (or run `open -a AeroSpace`).
   - Grant Accessibility and Screen Recording permissions when prompted by macOS in **System Settings > Privacy & Security**.
