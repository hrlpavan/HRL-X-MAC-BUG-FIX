#!/usr/bin/env bash
# ==============================================================================
# HRL-X-MAC-BUG-FIX: Safari External Link Dispatch Verifier
# ==============================================================================
# Verifies that external link clicks (from Terminal, VS Code, Discord, Mail)
# trigger LaunchServices IPC and successfully load into Safari without hanging.
# ==============================================================================

set -euo pipefail

TEST_URL="https://httpbin.org/get"
echo "[*] Testing LaunchServices link dispatch to Safari with: $TEST_URL"

START_TIME=$(date +%s)
open "$TEST_URL"
sleep 2

# Verify front tab in Safari
RESULT=$(osascript -e '
tell application "Safari"
    set fw to front window
    set curURL to URL of current tab of fw
    set curName to name of current tab of fw
    if curURL contains "httpbin.org" then
        close current tab of fw
        return "PASS: Tab loaded successfully [" & curName & "]"
    else
        return "FAIL: Expected httpbin.org, but found [" & curURL & "]"
    end if
end tell
')

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

echo "[+] Dispatch Result: $RESULT"
echo "[+] Verification Round-Trip: ${ELAPSED}s"

if [[ "$RESULT" == PASS* ]]; then
    echo "[✓] Safari Link Dispatch Queue is HEALTHY."
    exit 0
else
    echo "[✗] Safari Link Dispatch Queue is BLOCKED."
    exit 1
fi
