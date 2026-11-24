#!/usr/bin/env bash
# uninstall-dev.sh – undo only the `dev` setup (tmux layout for Claude Code in
# a Codespace) on macOS or in a codespace. Everything else install.sh sets up
# stays. Run by hand; safe to rerun.
set -euo pipefail
cd "$(dirname "$0")"

case "$(uname -s)" in
  Darwin) exec bash mac/uninstall-dev.sh ;;
  Linux)  exec bash codespaces/uninstall-dev.sh ;;
  *)      echo "Unsupported system: $(uname -s)" >&2; exit 1 ;;
esac
