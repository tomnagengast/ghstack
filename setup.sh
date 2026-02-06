#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BIN_DIR="$HOME/.local/bin"

# --- Prerequisites ---

fail() { echo "Error: $1" >&2; exit 1; }

command -v uv >/dev/null 2>&1 \
  || fail "uv not found. Install: https://docs.astral.sh/uv/"

command -v gh >/dev/null 2>&1 \
  || fail "gh not found. Install: https://cli.github.com/"

gh auth status >/dev/null 2>&1 \
  || fail "gh not authenticated. Run: gh auth login"

uv run --python 3.13 --no-project python -c "import sys; sys.exit(0 if sys.version_info >= (3,13) else 1)" 2>/dev/null \
  || fail "Python 3.13+ not available via uv. Run: uv python install 3.13"

# --- Install ---

mkdir -p "$BIN_DIR"
ln -sf "$SCRIPT_DIR/ghstack" "$BIN_DIR/ghstack"
echo "Linked: $BIN_DIR/ghstack -> $SCRIPT_DIR/ghstack"

# Check PATH
if ! echo "$PATH" | tr ':' '\n' | grep -qx "$BIN_DIR"; then
  echo ""
  echo "Warning: $BIN_DIR is not on your PATH."
  echo "Add to your shell rc:  export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

# --- Shell integration (optional) ---

echo ""
echo "Shell integration (optional — needed for --up/--down worktree navigation):"
echo "  Add to your .zshrc:  source $SCRIPT_DIR/ghstack.zsh"
echo ""
echo "Done. Try:  ghstack --all"
