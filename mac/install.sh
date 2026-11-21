#!/usr/bin/env bash
# mac/install.sh – minimal Mac setup; everything else lives in Codespaces.
# Safe to rerun: finished steps are skipped, configs are refreshed from this repo.
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
log() { printf '\n%s\n' "$*"; }

[[ "$(uname -s)" == Darwin ]] || { echo "mac/install.sh is for macOS only." >&2; exit 1; }

log "🚀 Setting up Mac..."

# --------------------------------------------------------
# 1. Homebrew (also installs Apple's Command Line Tools incl. git)
# --------------------------------------------------------
if [[ ! -x /opt/homebrew/bin/brew ]]; then
  log "🍺 Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
# For this script only; new shells find brew via /etc/paths.d/homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# --------------------------------------------------------
# 2. Apps, CLI tools, font, zsh plugins, VS Code extension
# --------------------------------------------------------
log "📦 Installing from Brewfile..."
brew bundle --file "$DIR/Brewfile"

# --------------------------------------------------------
# 3. Configs (copies; an existing different file is backed up first)
# --------------------------------------------------------
install_file() {
  local src="$1" dest="$2" backup
  mkdir -p "$(dirname "$dest")"
  if [[ -e "$dest" ]] && ! cmp -s "$src" "$dest"; then
    backup="$dest.backup-$(date +%Y%m%d-%H%M%S)"
    cp "$dest" "$backup"
    log "   Backed up old $dest to $backup"
  fi
  cp "$src" "$dest"
}

log "📝 Copying configs..."
install_file "$DIR/zshrc" "$HOME/.zshrc"
install_file "$DIR/ghostty/config.ghostty" "$HOME/.config/ghostty/config.ghostty"
touch "$HOME/.hushlogin"   # no "Last login" line in new terminals

if [[ -e "$HOME/.config/ghostty/config" ]]; then
  log "⚠️  ~/.config/ghostty/config also exists and overrides config.ghostty – delete it if it's an old copy."
fi

# --------------------------------------------------------
# 4. GitHub CLI login incl. Codespaces permission
# --------------------------------------------------------
if ! gh auth status >/dev/null 2>&1; then
  log "🔑 Signing in to GitHub (choose HTTPS, answer 'n' to 'Authenticate Git')..."
  gh auth login -h github.com -p https -s codespace -w
elif ! gh auth status 2>&1 | grep -q "'codespace'"; then
  log "🔑 Adding Codespaces permission to gh..."
  gh auth refresh -h github.com -s codespace
fi

log "✨ Done. Left to do by hand:
   • Open VS Code once, sign in with GitHub (also for Settings Sync).
   • Open a new Ghostty window and run: gh cs code"
