#!/usr/bin/env bash
# uninstall.sh – undo the `dev` setup (tmux layout for Claude Code in a
# Codespace) on macOS or in a codespace. Run by hand; safe to rerun.
set -euo pipefail
cd "$(dirname "$0")"

case "$(uname -s)" in
  Darwin) exec bash mac/uninstall.sh ;;
  Linux)  exec bash codespaces/uninstall.sh ;;
  *)      echo "Unsupported system: $(uname -s)" >&2; exit 1 ;;
esac
