
# ============================================================
# Powerlevel10k Instant Prompt
# MUST remain near the top of ~/.zshrc
# ============================================================

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi


# ============================================================
# Homebrew (macOS)
# ============================================================

if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi


# ============================================================
# PATH Configuration
# ============================================================

export PATH="$HOME/.local/bin:$PATH"

# Kilo CLI
if [[ -d "$HOME/.kilo/bin" ]]; then
  export PATH="$HOME/.kilo/bin:$PATH"
fi


# ============================================================
# Zinit Plugin Manager
# ============================================================

export ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"

# Install Zinit if missing
if [[ ! -d "$ZINIT_HOME" ]]; then
  mkdir -p "${ZINIT_HOME:h}"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Load Zinit
source "$ZINIT_HOME/zinit.zsh"


# ============================================================
# Zinit Plugins
# ============================================================

# Powerlevel10k
zinit ice depth=1
zinit light romkatv/powerlevel10k

# Zsh completions
zinit light zsh-users/zsh-completions

# Autosuggestions
zinit light zsh-users/zsh-autosuggestions

# FZF Tab completion
zinit light Aloxaf/fzf-tab


# ============================================================
# Oh My Zsh Snippets
# ============================================================

zinit snippet OMZL::git.zsh

zinit snippet OMZP::git
zinit snippet OMZP::sudo

# Linux-specific snippets
if [[ "$(uname -s)" == "Linux" ]]; then
  zinit snippet OMZP::archlinux
fi

zinit snippet OMZP::aws
zinit snippet OMZP::kubectl
zinit snippet OMZP::kubectx
zinit snippet OMZP::command-not-found


# ============================================================
# Completion System
# ============================================================

autoload -Uz compinit
compinit

# Replay Zinit completion settings
zinit cdreplay -q


# ============================================================
# Powerlevel10k Configuration
# ============================================================

[[ -f "$HOME/.p10k.zsh" ]] && source "$HOME/.p10k.zsh"


# ============================================================
# Keybindings
# ============================================================

bindkey -e

bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region


# ============================================================
# History Configuration
# ============================================================

HISTSIZE=5000
SAVEHIST=5000
HISTFILE="$HOME/.zsh_history"

setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups


# ============================================================
# Completion Styling
# ============================================================

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' menu no

# Load LS_COLORS if available
if [[ -x /usr/bin/dircolors ]]; then
  eval "$(dircolors -b)"
fi

zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# FZF Tab previews
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls $realpath'


# ============================================================
# Aliases
# ============================================================

# Cross-platform ls colors
if [[ "$(uname -s)" == "Darwin" ]]; then
  alias ls='ls -G'
else
  alias ls='ls --color=auto'
  alias grep='grep --color=auto'
  alias fgrep='fgrep --color=auto'
  alias egrep='egrep --color=auto'
fi


# ============================================================
# FZF Integration
# ============================================================

if command -v fzf >/dev/null 2>&1; then
  eval "$(fzf --zsh)"
fi


# ============================================================
# Zoxide Integration
# ============================================================

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init --cmd cd zsh)"
fi


# ============================================================
# NVM (Node Version Manager)
# ============================================================

export NVM_DIR="$HOME/.nvm"

[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"

[[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"


# ============================================================
# Composio CLI
# ============================================================

export PATH="$HOME/.local/bin:$PATH"


# ============================================================
# Atuin Shell History
# ============================================================

[[ -f "$HOME/.atuin/bin/env" ]] && source "$HOME/.atuin/bin/env"

if command -v atuin >/dev/null 2>&1; then
  eval "$(atuin init zsh)"
fi


# ============================================================
# Hermes Agent Auto-Start
# Only in an interactive terminal
# Never automatically launch recursively
# ============================================================

if [[ -o interactive && -t 1 ]] \
   && [[ -z "${HERDR_AUTOSTARTED:-}" ]] \
   && command -v herdr >/dev/null 2>&1; then

  export HERDR_AUTOSTARTED=1
  herdr
fi


# ============================================================
# Fastfetch
# ============================================================

if command -v fastfetch >/dev/null 2>&1; then
  clear
  fastfetch
fi


# ============================================================
# Syntax Highlighting
# MUST be loaded last among Zsh plugins
# ============================================================

zinit light zsh-users/zsh-syntax-highlighting
