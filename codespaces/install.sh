#!/usr/bin/env bash
# codespaces/install.sh – Codespaces setup (called by ../install.sh)
set -euo pipefail

log() { printf '\n%s\n' "$*"; }

log "🚀 Configuring Codespace..."

# --------------------------------------------------------
# 1. Claude Code (native installer)
# --------------------------------------------------------
log "🤖 Installing Claude Code..."
export PATH="$HOME/.local/bin:$PATH"
if ! command -v claude >/dev/null 2>&1; then
  # Allowed to fail, so a network hiccup doesn't skip the shell setup below
  curl -fsSL --retry 3 https://claude.ai/install.sh | bash \
    || log "⚠️  Claude Code install failed – rerun ./install.sh later"
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
#    (merged into an existing file, so other settings are kept)
# --------------------------------------------------------
log "⚙️  Seeding Claude Code config..."
CLAUDE_JSON="$HOME/.claude.json"
if [ ! -s "$CLAUDE_JSON" ]; then
  printf '{\n  "hasCompletedOnboarding": true,\n  "theme": "dark"\n}\n' > "$CLAUDE_JSON"
elif command -v jq >/dev/null 2>&1; then
  tmp=$(mktemp)
  if jq '.hasCompletedOnboarding = true | .theme = "dark"' "$CLAUDE_JSON" > "$tmp"; then
    mv "$tmp" "$CLAUDE_JSON"
  else
    rm -f "$tmp"
    log "⚠️  Could not merge into $CLAUDE_JSON – left unchanged"
  fi
else
  log "⚠️  $CLAUDE_JSON exists and jq is missing – left unchanged"
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

# --------------------------------------------------------
# 5. Ghostty compatibility + UTF-8 locale
# --------------------------------------------------------
# Ghostty identifies as xterm-ghostty, which doesn't render reliably here;
# fall back to the widely supported xterm-256color.
# .zshenv is read first by every zsh, before .zshrc and the prompt theme.
TERM_LINE='if [[ "$TERM" == xterm-ghostty ]]; then export TERM=xterm-256color; fi'
touch "$HOME/.zshenv"
grep -qxF "$TERM_LINE" "$HOME/.zshenv" || echo "$TERM_LINE" >> "$HOME/.zshenv"

# Default to a UTF-8 locale when the SSH session doesn't set one
LOCALE_LINE='export LANG="${LANG:-C.UTF-8}"'
for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
  grep -qxF "$LOCALE_LINE" "$rc" || echo "$LOCALE_LINE" >> "$rc"
done

log "✨ Done."
