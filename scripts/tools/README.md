# CLI Tools Installation & Reference

This directory contains scripts and documentation for installing and managing modern CLI tools on the VPS.

## Scripts

| Script | Description |
|--------|-------------|
| [[install-sys-tools.sh|install-sys-tools.sh]] | Installs core terminal tools (exa, fd, zoxide, bat, fzf, ripgrep, atuin, neofetch) |
| [[tools.sh|tools.sh]] | Placeholder for future tooling |

## Subdirectories

- [[cloudflare/README|cloudflare/]] — Cloudflare Tunnel setup (`CF-setup.sh`, `CF-tunnels.md`)
- [[tailscale/README|tailscale/]] — Tailscale setup (`tailscale-setup.sh`)

---

## Installed Tools (via `install-sys-tools.sh`)

| Tool | Binary | Purpose | Notes |
|------|--------|---------|-------|
| **exa** | `exa` | Modern `ls` replacement | Colors, git status, tree view |
| **fd-find** | `fd` (via symlink) | Fast `find` alternative | Respects `.gitignore`, parallel |
| **zoxide** | `zoxide` / `z` | Smart `cd` replacement | Learns habits, `zi` for interactive |
| **bat** | `bat` (via symlink) | `cat` with syntax highlighting | Paging, git diff integration |
| **fzf** | `fzf` | Fuzzy finder | Ctrl-R history, Ctrl-T files, **tab completion** |
| **ripgrep** | `rg` | Fast `grep` | Respects `.gitignore`, PCRE2 |
| **atuin** | `atuin` | Shell history sync | Encrypted, cross-machine, `Ctrl-R` UI |
| **neofetch** | `neofetch` | System info display | Runs on shell start (see `.zshrc`) |

### Ubuntu/Debian Name Fixes

The installer creates symlinks in `~/.local/bin`:
```bash
ln -sf /usr/bin/fdfind ~/.local/bin/fd
ln -sf /usr/bin/batcat ~/.local/bin/bat
```
Ensure `~/.local/bin` is in PATH (handled by `.zshrc` and `.bashrc`).

---

## AI Tool Integration

These tools enhance AI-assisted development workflows:

| Tool | AI Use Case |
|------|-------------|
| **ripgrep (`rg`)** | Fast codebase search for context gathering |
| **fd** | Quick file discovery for reading/writing |
| **bat** | Syntax-highlighted file reads |
| **fzf** | Interactive file/history selection in scripts |
| **zoxide** | Jump to project dirs without full paths |
| **atuin** | Shared shell history across sessions/machines |
| **exa** | Better directory listings for file ops |

**For AI agents:** Prefer `rg` over `grep`, `fd` over `find`, `bat` over `cat`. They're faster and respect `.gitignore`.

---

## Installation

```bash
# Run the installer (idempotent)
./scripts/tools/install-sys-tools.sh

# Then restart shell or:
source ~/.bashrc  # or ~/.zshrc
```

## Verification

```bash
# Check all tools available
for cmd in exa fd zoxide bat fzf rg atuin neofetch; do
  command -v "$cmd" && echo "✅ $cmd" || echo "❌ $cmd"
done
```

## Related

- [[../zsh/README|Zsh configuration]] (integrates fzf, zoxide, atuin)
- [[../README|Main README]]
- [[../AGENT|Agent instructions]]
