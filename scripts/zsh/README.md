# Zsh Configuration

Modern Zsh setup with **Zinit** plugin manager, **Powerlevel10k** theme, and curated plugins for productivity.

## Files

| File | Description |
|------|-------------|
| [[.zshrc|.zshrc]] | Full configuration (see breakdown below) |
| [[zsh_script.sh|zsh_script.sh]] | Quick interactive install helper |

---

## .zshrc Breakdown

### 1. Powerlevel10k Instant Prompt (lines 7-9)
Must stay near top for instant prompt to work.

### 2. Homebrew (macOS) (lines 13-20)
Auto-detects `/opt/homebrew` (Apple Silicon) or `/usr/local` (Intel).

### 3. PATH Configuration (lines 24-32)
- `$HOME/.local/bin` first (user tools like `fd`, `bat`, `atuin`)
- `$HOME/.kilo/bin` for Kilo CLI

### 4. Zinit Plugin Manager (lines 36-48)
- Auto-installs if missing (`git clone zdharma-continuum/zinit`)
- Loads `zinit.zsh`

### 5. Zinit Plugins (lines 52-67)
| Plugin | Purpose |
|--------|---------|
| `romkatv/powerlevel10k` | Theme (depth=1 for speed) |
| `zsh-users/zsh-completions` | Extra completions |
| `zsh-users/zsh-autosuggestions` | Gray inline suggestions |
| `Aloxaf/fzf-tab` | FZF-powered tab completion |

### 6. Oh My Zsh Snippets (lines 70-86)
- `OMZL::git.zsh` — Git helpers
- `OMZP::git` — Git aliases (`gst`, `gp`, `gco`, etc.)
- `OMZP::sudo` — `Esc-Esc` prepends `sudo`
- `OMZP::archlinux` — Arch aliases (Linux only)
- `OMZP::aws` / `kubectl` / `kubectx` — Cloud/k8s completions
- `OMZP::command-not-found` — Suggests packages for missing commands

### 7. Completion System (lines 89-97)
- `compinit` + `zinit cdreplay -q` for Zinit completions

### 8. Powerlevel10k Config (lines 101-104)
Sources `~/.p10k.zsh` if exists (run `p10k configure` to generate).

### 9. Keybindings (lines 108-116)
- Emacs mode (`bindkey -e`)
- `Ctrl-P` / `Ctrl-N` — History search backward/forward
- `Alt-W` — Kill region

### 10. History (lines 119-133)
- 5000 lines in memory + file
- Shared across sessions, deduped, ignores space-prefixed

### 11. Completion Styling (lines 136-152)
- Case-insensitive matching
- No menu, LS_COLORS support
- FZF-tab previews for `cd` and `zoxide`

### 12. Aliases (lines 155-166)
- Cross-platform `ls` / `grep` colors

### 13. FZF Integration (lines 170-175)
Loads FZF keybindings + completion if installed.

### 14. Zoxide Integration (lines 178-184)
`eval "$(zoxide init --cmd cd zsh)"` — replaces `cd` with smart directory jumping.
**Requires:** `sudo apt install zoxide` (or `brew install zoxide`)

### 15. NVM (lines 188-196)
Loads `nvm.sh` + bash completion from `$HOME/.nvm`.

### 16. Composio CLI (lines 199-203)
Adds `$HOME/.local/bin` to PATH (again, for good measure).

### 17. Atuin Shell History (lines 206-213)
Syncs shell history across machines. Loads env + `atuin init zsh`.

### 18. Hermes Agent Auto-Start (lines 217-228)
Starts `herdr` in interactive terminals (guarded against recursion).

### 19. Fastfetch (lines 232-238)
Clears screen + runs `fastfetch` on shell start (if installed).

### 20. Syntax Highlighting (lines 242-246)
**Must load last.** `zsh-users/zsh-syntax-highlighting`.

---

## Quick Install

```bash
# 1. Install prerequisites
sudo apt install zsh zoxide fzf git curl

# 2. Run oh-my-zsh installer (interactive)
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# 3. Clone this repo and copy .zshrc
git clone https://github.com/abxba-org/fresh_VPS
cp fresh_VPS/scripts/zsh/.zshrc ~/.zshrc

# 4. Restart terminal or:
exec zsh
```

Or use the helper:
```bash
./scripts/zsh/zsh_script.sh
```

## Required Packages (Ubuntu/Debian)

```bash
sudo apt install \
  zsh zoxide fzf fd-find bat ripgrep \
  git curl fastfetch
```

- `fd-find` → binary is `fdfind`, symlinked to `fd` by `install-sys-tools.sh`
- `bat` → binary is `batcat`, symlinked to `bat` by `install-sys-tools.sh`

## Customization

- **Theme**: Run `p10k configure` to customize Powerlevel10k
- **Plugins**: Add/remove in the "Zinit Plugins" section
- **Aliases**: Add to the "Aliases" section
- **Local overrides**: Create `~/.zshrc.local` and source it at the end of `.zshrc`

## Related

- [[../tools/install-sys-tools.sh|System tools installer]] (installs zoxide, fd, bat, fzf, ripgrep, atuin)
- [[../README|Main README]]
- [[../AGENT|Agent instructions]]
