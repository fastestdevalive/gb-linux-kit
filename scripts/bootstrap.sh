#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

info() { printf '[INFO] %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*"; }

detect_os() {
  case "$(uname -s)" in
    Darwin) echo "mac" ;;
    Linux)  echo "linux" ;;
    *)      echo "unknown" ;;
  esac
}

detect_linux_machine() {
  ls /sys/class/power_supply/BAT* &>/dev/null && echo "laptop" || echo "workstation"
}

OS=""
MACHINE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --os) OS="$2"; shift 2 ;;
    --os=*) OS="${1#*=}"; shift ;;
    --machine) MACHINE="$2"; shift 2 ;;
    --machine=*) MACHINE="${1#*=}"; shift ;;
    -h|--help)
      cat <<EOF
Usage: bootstrap.sh [options]

Options:
  --os <mac|linux>          Override detected operating system
  --machine <type>          Linux machine type (laptop|workstation) or mac
  -h, --help                Show this help message
EOF
      exit 0
      ;;
    *) shift ;;
  esac
done

[[ -z "$OS" ]] && OS="$(detect_os)"

if [[ "$OS" == "mac" ]]; then
  [[ -z "$MACHINE" ]] && MACHINE="mac"
  info "Target OS: macOS (machine: $MACHINE)"
elif [[ "$OS" == "linux" ]]; then
  [[ -z "$MACHINE" ]] && MACHINE="$(detect_linux_machine)"
  info "Target OS: Linux (machine: $MACHINE)"
else
  warn "Unrecognized OS: $OS; defaulting to linux"
  OS="linux"
  [[ -z "$MACHINE" ]] && MACHINE="workstation"
fi

install_linux_packages() {
  info "Updating apt metadata"
  sudo apt-get update

  info "Installing Linux base packages (including i3, X11 tools, and shell packages)"
  sudo apt-get install -y \
    zsh \
    git \
    vim \
    i3 \
    i3status \
    dmenu \
    xss-lock \
    dex \
    feh \
    alacritty \
    maim \
    xclip \
    flameshot \
    zsh-autosuggestions \
    zsh-syntax-highlighting \
    fonts-powerline

  if [[ "$MACHINE" == "laptop" ]]; then
    info "Installing Linux laptop-only packages"
    sudo apt-get install -y brightnessctl light
  fi

  # Install MesloLGS NF fonts for Powerlevel10k
  install_fonts
}

install_mac_packages() {
  info "Setting up macOS dependencies"
  info "Note: i3 window manager and X11 utilities are Linux-only; installing AeroSpace and Alacritty for macOS."

  if command -v brew >/dev/null 2>&1; then
    info "Homebrew detected; installing plugins via brew"
    brew install zsh-autosuggestions zsh-syntax-highlighting 2>/dev/null || true
  else
    info "Homebrew not found or not in PATH; setting up standalone zsh plugins"
    mkdir -p "$HOME/.zsh"
    
    local autosuggest_dir="$HOME/.zsh/zsh-autosuggestions"
    if [[ -d "$autosuggest_dir/.git" ]]; then
      info "zsh-autosuggestions already installed; updating"
      git -C "$autosuggest_dir" pull --ff-only || true
    else
      info "Cloning zsh-autosuggestions"
      git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$autosuggest_dir"
    fi

    local syntax_hl_dir="$HOME/.zsh/zsh-syntax-highlighting"
    if [[ -d "$syntax_hl_dir/.git" ]]; then
      info "zsh-syntax-highlighting already installed; updating"
      git -C "$syntax_hl_dir" pull --ff-only || true
    else
      info "Cloning zsh-syntax-highlighting"
      git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "$syntax_hl_dir"
    fi
  fi

  # Install Alacritty terminal emulator
  install_mac_alacritty

  # Install AeroSpace (i3-like tiling window manager for macOS)
  install_mac_aerospace

  # Install MesloLGS NF font for Powerlevel10k if not already installed
  install_fonts
}

install_mac_alacritty() {
  if [[ -d "/Applications/Alacritty.app" || -d "$HOME/Applications/Alacritty.app" ]]; then
    info "Alacritty.app already installed"
    local app_bin=""
    [[ -d "/Applications/Alacritty.app" ]] && app_bin="/Applications/Alacritty.app/Contents/MacOS/alacritty"
    [[ -d "$HOME/Applications/Alacritty.app" ]] && app_bin="$HOME/Applications/Alacritty.app/Contents/MacOS/alacritty"
    if [[ -n "$app_bin" ]]; then
      mkdir -p "$HOME/.local/bin"
      ln -sfn "$app_bin" "$HOME/.local/bin/alacritty"
    fi
    return 0
  fi

  if command -v brew >/dev/null 2>&1; then
    info "Installing Alacritty via Homebrew"
    brew install --cask alacritty 2>/dev/null || true
  else
    info "Downloading and installing Alacritty for macOS"
    local tmp_dmg
    tmp_dmg="$(mktemp -t alacritty_XXXXXX.dmg)"
    local target_apps="/Applications"
    [[ ! -w "/Applications" ]] && target_apps="$HOME/Applications"
    mkdir -p "$target_apps" "$HOME/.local/bin"

    if curl -fsSL "https://github.com/alacritty/alacritty/releases/download/v0.17.0/Alacritty-v0.17.0.dmg" -o "$tmp_dmg"; then
      local mount_point
      mount_point="$(mktemp -d -t alacritty_mount_XXXXXX)"
      hdiutil attach "$tmp_dmg" -nobrowse -quiet -mountpoint "$mount_point" || true
      if [[ -d "$mount_point/Alacritty.app" ]]; then
        cp -R "$mount_point/Alacritty.app" "$target_apps/"
        xattr -dr com.apple.quarantine "$target_apps/Alacritty.app" 2>/dev/null || true
        ln -sfn "$target_apps/Alacritty.app/Contents/MacOS/alacritty" "$HOME/.local/bin/alacritty"
        info "Alacritty installed to $target_apps/Alacritty.app"
      fi
      hdiutil detach "$mount_point" -quiet 2>/dev/null || true
      rm -rf "$mount_point" "$tmp_dmg"
    else
      warn "Failed to download Alacritty dmg"
      rm -f "$tmp_dmg"
    fi
  fi
}

install_mac_aerospace() {
  if [[ -d "/Applications/AeroSpace.app" || -d "$HOME/Applications/AeroSpace.app" ]]; then
    info "AeroSpace.app already installed"
    local app_dir="/Applications/AeroSpace.app"
    [[ -d "$HOME/Applications/AeroSpace.app" ]] && app_dir="$HOME/Applications/AeroSpace.app"
    mkdir -p "$HOME/.local/bin"
    if [[ -d "$app_dir" ]]; then
      xattr -dr com.apple.quarantine "$app_dir" 2>/dev/null || true
    fi
    return 0
  fi

  if command -v brew >/dev/null 2>&1; then
    info "Installing AeroSpace via Homebrew"
    brew install --cask nikitabobko/tap/aerospace 2>/dev/null || true
  else
    info "Downloading and installing AeroSpace for macOS (i3-like window manager)"
    local target_apps="/Applications"
    [[ ! -w "/Applications" ]] && target_apps="$HOME/Applications"
    mkdir -p "$target_apps" "$HOME/.local/bin"

    local tmp_zip
    tmp_zip="$(mktemp -t aerospace_XXXXXX.zip)"
    local tmp_extract
    tmp_extract="$(mktemp -d -t aerospace_ext_XXXXXX)"

    local download_url="https://github.com/nikitabobko/AeroSpace/releases/download/v0.21.3-Beta/AeroSpace-v0.21.3-Beta.zip"
    if curl -fsSL "$download_url" -o "$tmp_zip"; then
      unzip -q "$tmp_zip" -d "$tmp_extract"
      local found_app
      found_app="$(find "$tmp_extract" -name "AeroSpace.app" -type d | head -n 1)"
      local found_bin
      found_bin="$(find "$tmp_extract" -name "aerospace" -type f -perm +111 2>/dev/null | head -n 1 || true)"

      if [[ -n "$found_app" ]]; then
        cp -R "$found_app" "$target_apps/"
        xattr -dr com.apple.quarantine "$target_apps/AeroSpace.app" 2>/dev/null || true
        info "AeroSpace installed to $target_apps/AeroSpace.app"
      fi
      if [[ -n "$found_bin" ]]; then
        cp "$found_bin" "$HOME/.local/bin/aerospace"
        chmod +x "$HOME/.local/bin/aerospace"
      fi
      rm -rf "$tmp_zip" "$tmp_extract"
    else
      warn "Failed to download AeroSpace zip"
      rm -rf "$tmp_zip" "$tmp_extract"
    fi
  fi
}

install_fonts() {
  local font_dir
  if [[ "$OS" == "mac" ]]; then
    font_dir="$HOME/Library/Fonts"
  else
    font_dir="$HOME/.local/share/fonts"
  fi

  local base_url="https://github.com/romkatv/powerlevel10k-media/raw/master"
  local -a fonts=(
    "MesloLGS NF Regular.ttf"
    "MesloLGS NF Bold.ttf"
    "MesloLGS NF Italic.ttf"
    "MesloLGS NF Bold Italic.ttf"
  )

  mkdir -p "$font_dir"
  local needed=0
  for f in "${fonts[@]}"; do
    if [[ ! -f "$font_dir/$f" ]]; then
      needed=1
      break
    fi
  done

  if (( needed )) && command -v curl >/dev/null 2>&1; then
    info "Downloading MesloLGS NF fonts for Powerlevel10k into $font_dir..."
    for f in "${fonts[@]}"; do
      if [[ ! -f "$font_dir/$f" ]]; then
        curl -fsSL "$base_url/${f// /%20}" -o "$font_dir/$f" || warn "Failed to download $f"
      fi
    done
    if command -v fc-cache >/dev/null 2>&1; then
      fc-cache -f "$font_dir" >/dev/null 2>&1 || true
    fi
    info "MesloLGS NF fonts installed successfully."
  else
    info "Powerlevel10k fonts already present in $font_dir or curl unavailable."
  fi
}

install_packages() {
  if [[ "$OS" == "mac" ]]; then
    install_mac_packages
  else
    install_linux_packages
  fi
}

install_oh_my_zsh() {
  if [[ -d "$HOME/.oh-my-zsh/.git" ]]; then
    info "Oh My Zsh already installed; updating"
    git -C "$HOME/.oh-my-zsh" pull --ff-only || true
  else
    info "Installing Oh My Zsh"
    git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
  fi

  # Link adb-device-select plugin to Oh My Zsh custom plugins
  mkdir -p "$HOME/.oh-my-zsh/custom/plugins"
  if [[ -d "$REPO_ROOT/zsh/plugins/adb-device-select" ]]; then
    ln -sfn "$REPO_ROOT/zsh/plugins/adb-device-select" "$HOME/.oh-my-zsh/custom/plugins/adb-device-select"
  fi
}

install_powerlevel10k() {
  if [[ -d "$HOME/.powerlevel10k/.git" ]]; then
    info "Powerlevel10k already installed; updating"
    git -C "$HOME/.powerlevel10k" pull --ff-only || true
  else
    info "Installing Powerlevel10k"
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/.powerlevel10k"
  fi
}

install_vim_theme() {
  local target="$HOME/.vim/pack/themes/start/vim-code-dark"
  if [[ -d "$target/.git" ]]; then
    info "vim-code-dark already installed; updating"
    git -C "$target" pull --ff-only || true
  else
    info "Installing vim-code-dark"
    mkdir -p "$(dirname "$target")"
    git clone --depth=1 https://github.com/tomasiser/vim-code-dark.git "$target"
  fi
}

link_configs() {
  info "Linking shell/editor config files"

  # Instead of symlinking .zshrc, source it in the user's .zshrc
  local zshrc="$HOME/.zshrc"
  local source_line="source \"$REPO_ROOT/zsh/.zshrc\""

  if [[ -L "$zshrc" ]]; then
    info "Removing existing symbolic link at $zshrc"
    rm "$zshrc"
  fi

  if [[ -f "$zshrc" ]]; then
    if ! grep -Fxq "$source_line" "$zshrc"; then
      info "Appending source line to $zshrc"
      printf '\n%s\n' "$source_line" >> "$zshrc"
    else
      info "$zshrc already sources $REPO_ROOT/zsh/.zshrc"
    fi
  else
    info "Creating new $zshrc sourcing $REPO_ROOT/zsh/.zshrc"
    printf '%s\n' "$source_line" > "$zshrc"
  fi

  ln -sfn "$REPO_ROOT/zsh/.p10k.zsh" "$HOME/.p10k.zsh"
  ln -sfn "$REPO_ROOT/vim/.vimrc"    "$HOME/.vimrc"
  ln -sfn "$REPO_ROOT/zsh/aliases.zsh" "$HOME/.zsh_aliases"

  mkdir -p "$HOME/.config/alacritty"
  ln -sfn "$REPO_ROOT/alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"

  if [[ "$OS" == "mac" ]]; then
    info "Linking AeroSpace config (~/.config/aerospace/aerospace.toml)"
    rm -f "$HOME/.aerospace.toml"
    mkdir -p "$HOME/.config/aerospace"
    ln -sfn "$REPO_ROOT/aerospace/aerospace.toml" "$HOME/.config/aerospace/aerospace.toml"
  elif [[ "$OS" == "linux" ]]; then
    info "Linking i3 config ($MACHINE)"
    mkdir -p "$HOME/.config/i3"
    ln -sfn "$REPO_ROOT/i3/config.$MACHINE" "$HOME/.config/i3/config"
  fi
}

configure_gnome_terminal() {
  if [[ "$OS" == "mac" ]]; then
    return 0
  fi

  if command -v gsettings >/dev/null 2>&1; then
    local profile base
    profile="$(gsettings get org.gnome.Terminal.ProfilesList default 2>/dev/null | tr -d "'" || true)"
    if [[ -n "$profile" ]]; then
      base="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${profile}/"
      info "Configuring GNOME Terminal profile to run zsh login shell"
      gsettings set "$base" use-custom-command true
      gsettings set "$base" custom-command 'zsh -l'
      gsettings set "$base" login-shell false
    fi
  else
    info "gsettings not found; skipping GNOME Terminal configuration"
  fi
}

set_default_shell() {
  local current_shell=""
  if [[ "$OS" == "mac" ]] && command -v dscl >/dev/null 2>&1; then
    current_shell="$(dscl . -read /Users/"$USER" UserShell 2>/dev/null | awk '{print $2}' || true)"
  fi
  [[ -z "$current_shell" ]] && current_shell="${SHELL:-}"

  local zsh_path
  zsh_path="$(command -v zsh || echo "/bin/zsh")"

  if [[ "$current_shell" != *zsh* ]]; then
    info "Default shell is currently $current_shell"
    if [[ -t 0 ]]; then
      info "Changing default shell to $zsh_path (may prompt for password)..."
      chsh -s "$zsh_path" || warn "Could not change default shell automatically; please run: chsh -s $zsh_path"
    else
      info "To set zsh as your default shell, run: chsh -s $zsh_path"
    fi
  else
    info "Default shell is already zsh ($current_shell)"
  fi
}

main() {
  install_packages
  install_oh_my_zsh
  install_powerlevel10k
  install_vim_theme
  link_configs
  configure_gnome_terminal
  set_default_shell
  info "Bootstrap complete. Restart terminal or run: exec zsh"
}

main "$@"
