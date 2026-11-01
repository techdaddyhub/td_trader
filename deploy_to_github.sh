#!/usr/bin/env bash
# ==============================================================================
# TD TRADER - Turnkey GitHub Deployment Script
# Pushes the repository and tag to GitHub to trigger automated multi-platform app builds
# ==============================================================================

set -e

REPO_URL="${1:-https://github.com/techdaddyhub/td_trader.git}"

echo "=================================================================="
echo "  TD TRADER - Deploying to GitHub for Automated Multi-Platform Release"
echo "=================================================================="

# Check if remote origin already exists
if git remote | grep -q 'origin'; then
    echo "[INFO] Updating remote origin to: $REPO_URL"
    git remote set-url origin "$REPO_URL"
else
    echo "[INFO] Adding remote origin: $REPO_URL"
    git remote add origin "$REPO_URL"
fi

echo "[INFO] Pushing main branch..."
git push -u origin main

echo "[INFO] Pushing release tag v2.0.0 (triggers automated multi-platform release)..."
git push origin v2.0.0

echo "=================================================================="
echo "  SUCCESS! Repository and v2.0.0 tag deployed to GitHub."
echo "  GitHub Actions is now automatically building:"
echo "    - TDTrader-Android.apk (Android)"
echo "    - TDTrader-Windows-x64.zip (Windows Desktop)"
echo "    - TDTrader-Linux-x64.tar.gz (Linux Desktop)"
echo "    - TDTrader-macOS.zip (macOS Desktop)"
echo "    - TDTrader-Web-App.zip (Web App)"
echo "    - MetaTrader 4 & 5 Expert Advisors"
echo ""
echo "  Users can download the apps at: ${REPO_URL%.git}/releases"
echo "=================================================================="
