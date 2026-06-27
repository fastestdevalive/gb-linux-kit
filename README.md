# gb-linux-kit

Personal terminal and desktop bootstrap for Debian-based Linux systems.

## What this sets up

- Zsh as default shell with Powerlevel10k prompt
- Zsh autosuggestions (history + completion strategy) and syntax highlighting
- Vim with Code Dark theme (VS Code inspired)
- i3 window manager — separate configs for laptop and workstation
- GNOME Terminal profile launching `zsh -l`

## Repo layout

```
scripts/bootstrap.sh       — idempotent setup script (auto-detects laptop vs workstation)
zsh/.zshrc                 — Zsh config
zsh/.p10k.zsh              — Powerlevel10k prompt config (wizard output)
zsh/aliases.zsh            — shell aliases and functions
vim/.vimrc                 — Vim config
i3/config.laptop           — i3 config: Mod1 (Alt), touchpad, brightness keys
i3/config.workstation      — i3 config: Mod4 (Super), no touchpad
```

## Usage on a new machine

```bash
git clone https://github.com/fastestdevalive/gb-linux-kit.git ~/code/gb-linux-kit
bash ~/code/gb-linux-kit/scripts/bootstrap.sh
```

Machine type is auto-detected (battery presence = laptop). Override with:

```bash
bash ~/code/gb-linux-kit/scripts/bootstrap.sh --machine workstation
```

After bootstrap finishes:

- Close and reopen terminal, or run `exec zsh`
- Set a Nerd Font in your terminal for Powerlevel10k icons (MesloLGS NF recommended)
