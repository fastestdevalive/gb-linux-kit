#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

info() { printf '[INFO] %s\n' "$*"; }

detect_machine() {
  ls /sys/class/power_supply/BAT* &>/dev/null && echo "laptop" || echo "workstation"
}

MACHINE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --machine) MACHINE="$2"; shift 2 ;;
    --machine=*) MACHINE="${1#*=}"; shift ;;
    *) shift ;;
  esac
done
[[ -z "$MACHINE" ]] && MACHINE="$(detect_machine)"
info "Machine type: $MACHINE"

install_packages() {
  info "Updating apt metadata"
  sudo apt-get update

  info "Installing base packages"
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
    zsh-autosuggestions \
    zsh-syntax-highlighting \
    fonts-powerline

  if [[ "$MACHINE" == "laptop" ]]; then
    info "Installing laptop-only packages"
    sudo apt-get install -y brightnessctl light
  fi
}

install_powerlevel10k() {
  if [[ -d "$HOME/.powerlevel10k/.git" ]]; then
    info "Powerlevel10k already installed; updating"
    git -C "$HOME/.powerlevel10k" pull --ff-only
  else
    info "Installing Powerlevel10k"
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/.powerlevel10k"
  fi
}

install_vim_theme() {
  local target="$HOME/.vim/pack/themes/start/vim-code-dark"
  if [[ -d "$target/.git" ]]; then
    info "vim-code-dark already installed; updating"
    git -C "$target" pull --ff-only
  else
    info "Installing vim-code-dark"
    mkdir -p "$(dirname "$target")"
    git clone --depth=1 https://github.com/tomasiser/vim-code-dark.git "$target"
  fi
}

link_configs() {
  info "Linking shell/editor config files"

  ln -sfn "$REPO_ROOT/zsh/.zshrc"    "$HOME/.zshrc"
  ln -sfn "$REPO_ROOT/zsh/.p10k.zsh" "$HOME/.p10k.zsh"
  ln -sfn "$REPO_ROOT/vim/.vimrc"    "$HOME/.vimrc"
  ln -sfn "$REPO_ROOT/zsh/aliases.zsh" "$HOME/.zsh_aliases"

  info "Linking i3 config ($MACHINE)"
  mkdir -p "$HOME/.config/i3"
  ln -sfn "$REPO_ROOT/i3/config.$MACHINE" "$HOME/.config/i3/config"
}

configure_gnome_terminal() {
  if command -v gsettings >/dev/null 2>&1; then
    local profile base
    profile="$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'")"
    base="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${profile}/"
    info "Configuring GNOME Terminal profile to run zsh login shell"
    gsettings set "$base" use-custom-command true
    gsettings set "$base" custom-command 'zsh -l'
    gsettings set "$base" login-shell false
  else
    info "gsettings not found; skipping GNOME Terminal configuration"
  fi
}

set_default_shell() {
  local zsh_path
  zsh_path="$(command -v zsh)"
  if [[ "${SHELL:-}" != "$zsh_path" ]]; then
    info "Setting default shell to $zsh_path (may prompt for password)"
    chsh -s "$zsh_path"
  else
    info "Default shell already set to zsh"
  fi
}

main() {
  install_packages
  install_powerlevel10k
  install_vim_theme
  link_configs
  configure_gnome_terminal
  set_default_shell
  info "Bootstrap complete. Restart terminal or run: exec zsh"
}

main "$@"
