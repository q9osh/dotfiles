#!/usr/bin/env bash
# mac/uninstall-dev.sh – undo what the `dev` setup added to the Mac: tmux, the
# `dev` command and its tmux and SSH configs. The rest of mac/install.sh
# (Homebrew, the other Brewfile entries, zsh and Ghostty configs, gh login)
# stays.
# Safe to rerun. A file you changed is moved to <file>.backup-<date-time>
# instead of deleted; edited files keep everything but the lines install added.
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
log() { printf '\n%s\n' "$*"; }

[[ "$(uname -s)" == Darwin ]] || { echo "mac/uninstall-dev.sh is for macOS only." >&2; exit 1; }

# Delete a file install copied; if it was changed since, keep it as a backup
remove_file() {
  local src="$1" dest="$2"
  [[ -e "$dest" || -L "$dest" ]] || return 0
  if cmp -s "$src" "$dest"; then
    rm -f "$dest"
  else
    mv "$dest" "$dest.backup-$STAMP"
    log "   $dest had changes – kept as $dest.backup-$STAMP"
  fi
}

# Rewrite a file through an awk program (backup first, only if it changes).
# If nothing but blank lines would be left, the file held only install's
# lines: delete it, no backup needed.
edit_file() {
  local f="$1" prog="$2" tmp
  [[ -f "$f" ]] || return 0
  tmp=$(mktemp "$f.XXXXXX")
  awk "$prog" "$f" > "$tmp"
  if cmp -s "$f" "$tmp"; then
    rm -f "$tmp"
    return 0
  fi
  if ! grep -q '[^[:space:]]' "$tmp"; then
    rm -f "$tmp" "$f"
    log "   Removed $f (it held only install's lines)"
    return 0
  fi
  cp -p "$f" "$f.backup-$STAMP"
  cat "$tmp" > "$f"   # keeps the file's permissions (and a symlink's target)
  rm -f "$tmp"
  log "   Edited $f (previous version: $f.backup-$STAMP)"
}

log "🧹 Removing the dev setup from this Mac..."

# --------------------------------------------------------
# 1. Close dev's tmux sessions and shared SSH connections
#    (before the SSH config is gone: ssh -O exit needs it)
# --------------------------------------------------------
if command -v tmux >/dev/null 2>&1 && tmux list-sessions >/dev/null 2>&1; then
  # dev's sessions are those with a pane that `dev --pane` marked
  for s in $(tmux list-panes -a -F '#{session_name} #{@dev_kind}' | awk '$2 != "" {print $1}' | sort -u); do
    tmux kill-session -t "=$s" && log "🪟 Closed tmux session $s"
  done
fi
for f in "$HOME/.ssh/config.d/codespaces"/*; do
  [[ -e "$f" ]] || continue
  ssh -O exit "cs.$(basename "$f")" 2>/dev/null || true
done

# --------------------------------------------------------
# 2. Files install and dev created
# --------------------------------------------------------
log "📝 Removing files..."
remove_file "$DIR/tmux.conf" "$HOME/.tmux.conf"
remove_file "$DIR/bin/dev" "$HOME/.local/bin/dev"
remove_file "$DIR/ssh/codespaces.conf" "$HOME/.ssh/config.d/codespaces.conf"
rm -rf "$HOME/.ssh/config.d/codespaces" "$HOME/.ssh/cm"
rm -f "$HOME/.ssh/codespaces.auto" "$HOME/.ssh/codespaces.auto.pub"   # gh's key for codespace SSH
rm -f "${TMPDIR:-/tmp}"/dev-ssh-*

# --------------------------------------------------------
# 3. ~/.ssh/config: the comment, the Include line and the blank line after it
# --------------------------------------------------------
edit_file "$HOME/.ssh/config" '
  index($0, "# Codespaces for `dev` (dotfiles)") == 1 { next }
  $0 == "Include config.d/codespaces.conf"       { drop_blank = 1; next }
  drop_blank && $0 == ""                          { drop_blank = 0; next }
                                                  { drop_blank = 0; print }'

# --------------------------------------------------------
# 4. ~/.zshrc: the PATH block for ~/.local/bin
# --------------------------------------------------------
edit_file "$HOME/.zshrc" '
  $0 == "# Own scripts (dev)"                          { st = 1; next }
  st == 1 && $0 == "export PATH=\"$HOME/.local/bin:$PATH\"" { st = 2; next }
  st == 2 && $0 == ""                                  { st = 0; next }
                                                       { st = 0; print }'

# --------------------------------------------------------
# 5. tmux, and its dependencies that nothing else needs now
#    (not `brew autoremove`: that would remove unrelated packages too)
# --------------------------------------------------------
if command -v brew >/dev/null 2>&1 && brew list --formula tmux >/dev/null 2>&1; then
  if tmux list-sessions >/dev/null 2>&1; then
    log "⚠️  Other tmux sessions are still running – keeping tmux. Close them and rerun to remove it."
  else
    log "📦 Uninstalling tmux..."
    deps=$(brew deps --installed tmux) || deps=""
    brew uninstall tmux
    # Remove deps that are now unused and were installed only as dependencies
    while true; do
      orphans=$(brew leaves --installed-as-dependency) || break
      unused=()
      for d in $deps; do
        grep -qxF -- "$d" <<<"$orphans" && unused+=("$d")
      done
      [[ ${#unused[@]} -gt 0 ]] || break
      brew uninstall "${unused[@]}"
    done
  fi
fi

# --------------------------------------------------------
# 6. Folders that are empty now (rmdir leaves any with content alone)
# --------------------------------------------------------
rmdir "$HOME/.ssh/config.d" "$HOME/.ssh" "$HOME/.local/bin" "$HOME/.local" 2>/dev/null || true

log "✨ Done. Open a new terminal window so zsh rereads ~/.zshrc.
   Backups (*.backup-*) of changed files are kept – delete them when no longer needed.
   (gh's codespace key was only added inside the codespaces it connected to.)"
