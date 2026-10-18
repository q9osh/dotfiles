#!/usr/bin/env bash
# install.sh – dotfiles bootstrap for GitHub Codespaces
set -euo pipefail

log() { printf '\n%s\n' "$*"; }

log "🚀 Configuring Codespace..."

# --------------------------------------------------------
# 1. Claude Code (native installer)
# --------------------------------------------------------
log "🤖 Installing Claude Code..."
export PATH="$HOME/.local/bin:$PATH"
if ! command -v claude >/dev/null 2>&1; then
  curl -fsSL --retry 3 https://claude.ai/install.sh | bash
fi
claude --version || log "⚠️  'claude' not found on PATH after install"

# Make ~/.local/bin available in future shells (idempotent: no duplicate lines)
PATH_LINE='export PATH="$HOME/.local/bin:$PATH"'
for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
  touch "$rc"
  grep -qxF "$PATH_LINE" "$rc" || echo "$PATH_LINE" >> "$rc"
done

# --------------------------------------------------------
# 2. Claude Code config: skip onboarding, dark theme
#    (only written if absent, so nothing gets clobbered)
# --------------------------------------------------------
log "⚙️  Seeding Claude Code config..."
mkdir -p "$HOME/.claude"
if [ ! -f "$HOME/.claude.json" ]; then
  cat > "$HOME/.claude.json" <<'EOF'
{
  "hasCompletedOnboarding": true,
  "theme": "dark"
}
EOF
fi

# --------------------------------------------------------
# 3. Zsh as default VS Code terminal (remote machine settings)
# --------------------------------------------------------
if command -v zsh >/dev/null 2>&1; then
  log "🐚 Setting zsh as default terminal profile..."
  MACHINE_DIR="$HOME/.vscode-remote/data/Machine"
  MACHINE_SETTINGS="$MACHINE_DIR/settings.json"
  KEY='terminal.integrated.defaultProfile.linux'
  mkdir -p "$MACHINE_DIR"

  if [ ! -s "$MACHINE_SETTINGS" ]; then
    printf '{\n  "%s": "zsh"\n}\n' "$KEY" > "$MACHINE_SETTINGS"
  elif command -v jq >/dev/null 2>&1; then
    tmp=$(mktemp)
    if jq --arg k "$KEY" '.[$k] = "zsh"' "$MACHINE_SETTINGS" > "$tmp"; then
      mv "$tmp" "$MACHINE_SETTINGS"
    else
      rm -f "$tmp"
      log "⚠️  Could not merge into $MACHINE_SETTINGS (comments in file?) – left unchanged"
    fi
  else
    log "⚠️  $MACHINE_SETTINGS exists and jq is missing – left unchanged"
  fi
else
  log "⚠️  zsh not installed in this image – keeping default shell"
fi

# --------------------------------------------------------
# 4. zsh for SSH sessions and tmux
# --------------------------------------------------------
if command -v zsh >/dev/null 2>&1; then
  ZSH_PATH=$(command -v zsh)

  # Hand interactive SSH sessions from bash over to zsh
  ZSH_SWITCH='[[ $- == *i* && -n "$SSH_CONNECTION" && -z "$ZSH_VERSION" ]] && SHELL=$(command -v zsh) exec zsh -l'
  grep -qxF "$ZSH_SWITCH" "$HOME/.bashrc" || echo "$ZSH_SWITCH" >> "$HOME/.bashrc"

  # Make tmux open zsh in every new window and pane
  TMUX_LINE="set -g default-shell $ZSH_PATH"
  touch "$HOME/.tmux.conf"
  grep -qxF "$TMUX_LINE" "$HOME/.tmux.conf" || echo "$TMUX_LINE" >> "$HOME/.tmux.conf"

  # zsh corrects $SHELL itself, however it was started
  SHELL_LINE='export SHELL=$(command -v zsh)'
  grep -qxF "$SHELL_LINE" "$HOME/.zshrc" || echo "$SHELL_LINE" >> "$HOME/.zshrc"
fi

log "✨ Done."
