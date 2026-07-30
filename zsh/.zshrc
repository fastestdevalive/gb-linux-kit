# Ensure ~/.local/bin and common Homebrew paths are on PATH if they exist.
# zsh does not read ~/.bashrc or ~/.profile by default, so we ensure standard paths here.
for _p in "$HOME/.local/bin" "/opt/homebrew/bin" "/opt/homebrew/sbin" "/usr/local/bin" "/usr/local/sbin"; do
  if [[ -d "$_p" ]]; then
    case ":$PATH:" in
      *":$_p:"*) ;;
      *) export PATH="$_p:$PATH" ;;
    esac
  fi
done
unset _p

# Source adb-device-select plugin before the Powerlevel10k instant prompt block
# below. It defines instant_prompt_adb_device, and p10k only picks up
# instant-prompt-capable segments that exist by the time it captures the
# instant prompt cache; sourcing it later left the adb_device segment out of
# the instant (pre-init) prompt and made it pop in only after full init.
ZSH_KIT_DIR="${${(%):-%x}:a:h}"
if [[ -f "$ZSH_KIT_DIR/plugins/adb-device-select/adb-device-select.plugin.zsh" ]]; then
  source "$ZSH_KIT_DIR/plugins/adb-device-select/adb-device-select.plugin.zsh"
fi

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Oh My Zsh integration (if installed)
export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
if [[ -d "$ZSH" && -f "$ZSH/oh-my-zsh.sh" ]]; then
  ZSH_THEME="" # Prompt theme handled by Powerlevel10k
  DISABLE_AUTO_UPDATE="true"
  zstyle ':omz:update' mode disabled
  plugins=(git)
  source "$ZSH/oh-my-zsh.sh"
fi

# Set up the prompt
autoload -Uz promptinit
promptinit

# Find and load Powerlevel10k theme across Linux and macOS locations
for _p10k_theme in \
  "$HOME/.powerlevel10k/powerlevel10k.zsh-theme" \
  /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme \
  /usr/local/share/powerlevel10k/powerlevel10k.zsh-theme \
  /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme; do
  if [[ -r "$_p10k_theme" ]]; then
    source "$_p10k_theme"
    break
  fi
done
unset _p10k_theme

setopt histignorealldups sharehistory

# Use emacs keybindings even if our EDITOR is set to vi
bindkey -e

# Prefix-matching history search on Up/Down: type the start of a command,
# then Up/Down cycles only through history entries starting with it. This is
# NOT zsh's default Up/Down behavior (which is unfiltered linear recall via
# up-line-or-history/down-line-or-history) -- it only appeared to "just work"
# on some machines because of incidental leftover config (e.g. an old
# oh-my-zsh install or a stale ~/.zshrc from before this repo existed), which
# is why a fresh bootstrap on another Debian box didn't have it. Bind it
# explicitly so behavior is consistent everywhere.
#
# zsh's own default emacs keymap binds BOTH the normal-cursor-mode sequences
# (^[[A / ^[[B) AND the application/SS3-mode sequences (^[OA / ^[OB) to
# up/down-line-or-history, since different terminals (and even the same
# terminal in different modes) send either one. Rebinding only whichever
# single sequence terminfo's kcuu1/kcud1 happens to resolve to leaves the
# other variant still pointing at plain history recall, so on a terminal that
# sends the other variant, Up/Down silently falls back to non-prefix search.
# Bind both variants (plus terminfo's, in case a terminal uses something
# else entirely) so it's correct regardless of which mode is active.
zmodload -i zsh/terminfo 2>/dev/null
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
bindkey '^[OA' up-line-or-beginning-search
bindkey '^[OB' down-line-or-beginning-search
if [[ -n ${terminfo[kcuu1]:-} && -n ${terminfo[kcud1]:-} ]]; then
  bindkey "${terminfo[kcuu1]}" up-line-or-beginning-search
  bindkey "${terminfo[kcud1]}" down-line-or-beginning-search
fi

# Keep 1000 lines of history within the shell and save it to ~/.zsh_history:
HISTSIZE=1000
SAVEHIST=1000
HISTFILE=~/.zsh_history

# Use modern completion system
autoload -Uz compinit
compinit

zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _expand _complete _history _correct _approximate
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' menu select=2

# Colors for completions and directory listings (Linux dircolors / macOS BSD ls)
if command -v dircolors >/dev/null 2>&1; then
  eval "$(dircolors -b)"
elif command -v gdircolors >/dev/null 2>&1; then
  eval "$(gdircolors -b)"
fi

export CLICOLOR=1
if [[ -n "${LS_COLORS:-}" ]]; then
  zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
fi
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
zstyle ':completion:*' menu select=long
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' use-compctl false
zstyle ':completion:*' verbose true

zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Autosuggestions can use command history and completion results.
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#586e75"

for _zsh_autosuggest in \
  /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
  /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
  /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
  "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh" \
  "$HOME/.zsh-autosuggestions/zsh-autosuggestions.zsh"; do
  if [[ -r "$_zsh_autosuggest" ]]; then
    source "$_zsh_autosuggest"
    break
  fi
done
unset _zsh_autosuggest

[[ -f ~/.zsh_aliases ]] && source ~/.zsh_aliases

# Keep syntax highlighting last in zsh startup.
for _zsh_syntax_hl in \
  /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
  /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
  /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
  "$HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" \
  "$HOME/.zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"; do
  if [[ -r "$_zsh_syntax_hl" ]]; then
    source "$_zsh_syntax_hl"
    break
  fi
done
unset _zsh_syntax_hl
