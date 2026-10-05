#!/usr/bin/env bash
# ==============================================================================
# HRL-X-MAC-BUG-FIX: Safari Emergency Reset & Cache Flush
# ==============================================================================
# Gracefully terminates hung WebContent processes, flushes WebKit caches,
# and relaunches Safari with fresh session state.
# ==============================================================================

set -euo pipefail

echo "[*] Initiating Safari Safe Reset..."

# 1. Gracefully tell Safari to quit
osascript -e 'tell application "Safari" to quit' || true
sleep 2

# 2. Force terminate if still lingering
if pgrep -x Safari >/dev/null 2>&1; then
    echo "[!] Safari did not exit cleanly. Force terminating..."
    killall Safari || true
    sleep 1
fi

# 3. Terminate orphaned WebContent processes
echo "[*] Cleaning orphaned WebContent rendering processes..."
killall "com.apple.WebKit.WebContent" 2>/dev/null || true

# 4. Clear WebKit Caches (Local Sandbox Safe)
echo "[*] Purging user WebKit cache directories..."
rm -rf ~/Library/Caches/com.apple.Safari* 2>/dev/null || true

echo "[+] Safari state reset complete. Launching clean instance..."
open -a Safari "about:blank"
sleep 2
echo "[✓] Safari relaunched cleanly."
