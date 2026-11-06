# Zsh Setup

Installs and configures Zsh with a modern, productive development environment.

## Quick Start

```bash
# Run as your user (not root)
./setup.sh

# Restart shell or source config
exec zsh

# Configure Powerlevel10k (runs automatically on first start)
p10k configure
```

## What Gets Installed

| Component | Description |
|-----------|-------------|
| **Zsh** | Shell (via apt) |
| **Oh My Zsh** | Framework for managing Zsh config |
| **Powerlevel10k** | Fast, customizable prompt theme |
| **zsh-autosuggestions** | Fish-like autosuggestions |
| **zsh-syntax-highlighting** | Command syntax highlighting |
| **zsh-completions** | Extended completion definitions |
| **fzf** | Fuzzy finder for history/files |
| **zoxide** | Smart `cd` replacement (learns your habits) |
| **bat** | `cat` with syntax highlighting |
| **eza** | Modern `ls` replacement |
| **ripgrep (rg)** | Fast `grep` alternative |
| **fd** | Fast `find` alternative |

## Prerequisites

```bash
# Required: install zoxide separately (not in default Ubuntu repos)
sudo apt update && sudo apt install -y zoxide
```

> **Note**: The setup script will prompt you to install zoxide if not present. Zsh installation via apt is interactive - it will ask for confirmation.

## Configuration Details

### Oh My Zsh
- Installed in unattended mode (`--unattended`)
- Theme set to `powerlevel10k/powerlevel10k`
- Plugins loaded: `git`, `docker`, `kubectl`, `terraform`, `aws`, `gcloud`, `z`, `fzf`, `zsh-autosuggestions`, `zsh-syntax-highlighting`

### Powerlevel10k
- Instant prompt enabled (fast startup)
- Config file: `~/.p10k.zsh`
- Run `p10k configure` to customize

### zoxide Integration
```bash
# Replaces cd with smart directory jumping
z <partial-path>      # Jump to most used matching directory
zi                    # Interactive selection with fzf
zq                    # List scored directories
```

### Aliases Added
```bash
# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Better defaults
alias ll='eza -la --git --icons'
alias la='eza -la --git --icons'
alias lt='eza --tree --level=2 --git --icons'
alias cat='bat --style=plain'
alias grep='rg'
alias find='fd'
alias top='btop'
alias du='dust'
alias df='duf'

# Git
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline -10'
alias gd='git diff'

# Docker
alias d='docker'
alias dc='docker compose'
alias dps='docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"'

# Kubernetes
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgn='kubectl get nodes'
```

### Functions Added
```bash
# Create and enter directory
mkcd() { mkdir -p "$1" && cd "$1"; }

# Extract any archive
extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2) tar xjf "$1" ;;
            *.tar.gz) tar xzf "$1" ;;
            *.bz2) bunzip2 "$1" ;;
            *.rar) unrar x "$1" ;;
            *.gz) gunzip "$1" ;;
            *.tar) tar xf "$1" ;;
            *.tbz2) tar xjf "$1" ;;
            *.tgz) tar xzf "$1" ;;
            *.zip) unzip "$1" ;;
            *.Z) uncompress "$1" ;;
            *.7z) 7z x "$1" ;;
            *) echo "'$1' cannot be extracted" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Port lookup
port() { lsof -i :"$1"; }

# Weather
wttr() { curl "wttr.in/${1:-}"; }
```

## File Structure

```
scripts/zsh/
├── setup.sh              # Main entry point
├── lib/
│   ├── ohmyzsh.sh        # Oh My Zsh installation
│   ├── plugins.sh        # Plugin installation
│   ├── theme.sh          # Powerlevel10k setup
│   ├── aliases.sh        # Alias definitions
│   └── functions.sh      # Custom functions
├── config/
│   ├── .zshrc.template   # Zsh config template
│   └── .p10k.zsh.template # Powerlevel10k config template
└── README.md             # This file
```

## Customization

### Skip Components

```bash
# Skip Powerlevel10k (keep default OMZ theme)
export SKIP_P10K=1

# Skip zoxide integration
export SKIP_ZOXIDE=1

# Skip fzf
export SKIP_FZF=1

# Skip all plugins except git
export MINIMAL_PLUGINS=1
```

### Custom Plugin List

Edit `config/.zshrc.template` and modify the `plugins=(...)` array.

## Verification

After setup, verify:

- [ ] `zsh --version` shows 5.9+
- [ ] `echo $SHELL` shows `/usr/bin/zsh` (after relogin)
- [ ] `omz version` shows Oh My Zsh version
- [ ] `p10k` command available
- [ ] `z --help` shows zoxide help
- [ ] `fzf --version` shows version
- [ ] Aliases work: `ll`, `cat`, `grep`

## Troubleshooting

### Zsh not default shell
```bash
chsh -s $(which zsh)
# Log out and back in
```

### Powerlevel10k not loading
```bash
# Re-run configuration
p10k configure

# Or reset config
rm ~/.p10k.zsh
exec zsh
```

### Plugins not working
```bash
# Reinstall plugins
rm -rf ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
rm -rf ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
exec zsh
```

### zoxide not found
```bash
# Install manually
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
# Then restart shell
exec zsh
```

## Related Documentation

- [[README.md]] - Project overview
- [[AGENT.md]] - Agent cross-references
- [[scripts/network/README.md]] - Network setup (run first)
- [[scripts/tools/README.md]] - Tools installation (run after)
- [Oh My Zsh Docs](https://github.com/ohmyzsh/ohmyzsh/wiki)
- [Powerlevel10k Docs](https://github.com/romkatv/powerlevel10k)
- [zoxide Docs](https://github.com/ajeetdsouza/zoxide)