#!/usr/bin/env bash
# codespaces/uninstall-dev.sh – undo what the `dev` setup added to a codespace
# (called by ../uninstall-dev.sh): tmux, its config and dev-remote. Claude Code
# and the shell setup from install.sh stay. Safe to rerun.
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
log() { printf '\n%s\n' "$*"; }

log "🧹 Removing the dev setup from this codespace..."

# --------------------------------------------------------
# 1. The shell pane's tmux session
# --------------------------------------------------------
if command -v tmux >/dev/null 2>&1; then
  tmux kill-session -t "=shell" 2>/dev/null && log "🪟 Closed tmux session shell"
fi

# --------------------------------------------------------
# 2. ~/.tmux.conf back to what install.sh leaves without the dev setup:
#    only the zsh line (a version with your own changes is kept as backup)
# --------------------------------------------------------
TMUX_CONF="$HOME/.tmux.conf"
SHELL_LINE=""
command -v zsh >/dev/null 2>&1 && SHELL_LINE="set -g default-shell $(command -v zsh)"
if [[ -f "$TMUX_CONF" ]] && grep -qxF 'set -g prefix C-q' "$TMUX_CONF"; then
  if ! cmp -s "$TMUX_CONF" <(cat "$DIR/tmux.conf"; [[ -z "$SHELL_LINE" ]] || echo "$SHELL_LINE"); then
    cp -p "$TMUX_CONF" "$TMUX_CONF.backup-$STAMP"
    log "   ~/.tmux.conf had changes – kept as $TMUX_CONF.backup-$STAMP"
  fi
  if [[ -n "$SHELL_LINE" ]]; then
    echo "$SHELL_LINE" > "$TMUX_CONF"
  else
    rm -f "$TMUX_CONF"
  fi
fi

# --------------------------------------------------------
# 3. dev-remote
# --------------------------------------------------------
rm -f "$HOME/.local/bin/dev-remote"

# --------------------------------------------------------
# 4. tmux itself (install.sh installs it only where it was missing)
# --------------------------------------------------------
if command -v tmux >/dev/null 2>&1 && command -v apt-get >/dev/null 2>&1; then
  if tmux list-sessions >/dev/null 2>&1; then
    log "⚠️  Other tmux sessions are still running – keeping tmux. Close them and rerun to remove it."
  elif dpkg -s tmux >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
    log "📦 Uninstalling tmux..."
    sudo DEBIAN_FRONTEND=noninteractive apt-get remove -y -qq tmux >/dev/null
  fi
fi

log "✨ Done."
