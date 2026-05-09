#!/usr/bin/env bash
set -euo pipefail

# Rebuild bat's theme/syntax cache so custom themes under ~/.config/bat/themes
# (e.g. Catppuccin Mocha) are picked up. Idempotent.
bat cache --build >/dev/null
