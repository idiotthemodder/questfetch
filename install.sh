#!/usr/bin/env bash
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$HOME/.local/bin" "$HOME/.local/share/questfetch"
cp "$DIR/questfetch.sh" "$HOME/.local/share/questfetch/questfetch.sh"
cp "$DIR/questfetch-pc" "$HOME/.local/bin/questfetch"
chmod +x "$HOME/.local/bin/questfetch"

echo "installed to ~/.local/bin/questfetch"
echo "make sure ~/.local/bin is in your PATH, then run: questfetch"
