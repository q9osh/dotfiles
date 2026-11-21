#!/usr/bin/env bash
# install.sh – entry point for Codespaces (run automatically) and macOS (run by hand)
set -euo pipefail
cd "$(dirname "$0")"

case "$(uname -s)" in
  Darwin) exec bash mac/install.sh ;;
  Linux)  exec bash codespaces/install.sh ;;
  *)      echo "Unsupported system: $(uname -s)" >&2; exit 1 ;;
esac
