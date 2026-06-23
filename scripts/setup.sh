#!/bin/bash
#
# setup.sh — one-command project setup for NvidiaLLM on macOS.
#
# Installs XcodeGen (if missing), generates the Xcode project from project.yml,
# resolves SPM dependencies, and opens the project in Xcode.
#
# Usage:
#   chmod +x scripts/setup.sh
#   ./scripts/setup.sh
#
set -euo pipefail

echo "=== NvidiaLLM setup ==="

# --- 1. Check macOS / Xcode ---
if [[ "$(uname)" != "Darwin" ]]; then
  echo "ERROR: This script must be run on macOS." >&2
  exit 1
fi

if ! xcode-select -p >/dev/null 2>&1; then
  echo "ERROR: Xcode Command Line Tools not found." >&2
  echo "Install Xcode from the App Store, then run: sudo xcode-select -s /Applications/Xcode.app/Contents/Developer" >&2
  exit 1
fi
echo "✓ Xcode found: $(xcode-select -p)"

# --- 2. Install XcodeGen via Homebrew (if missing) ---
if ! command -v xcodegen >/dev/null 2>&1; then
  echo "→ Installing XcodeGen via Homebrew…"
  if ! command -v brew >/dev/null 2>&1; then
    echo "ERROR: Homebrew not found. Install from https://brew.sh" >&2
    exit 1
  fi
  brew install xcodegen
else
  echo "✓ XcodeGen found: $(xcodegen --version)"
fi

# --- 3. Generate the Xcode project ---
echo "→ Generating NvidiaLLM.xcodeproj…"
xcodegen generate
echo "✓ Project generated"

# --- 4. Open in Xcode ---
echo "→ Opening project in Xcode…"
open NvidiaLLM.xcodeproj

echo ""
echo "=== Setup complete ==="
echo "In Xcode: select the NvidiaLLM scheme, then press Cmd+R to build & run."
echo "For a signed release build, set your team under Signing & Capabilities."
