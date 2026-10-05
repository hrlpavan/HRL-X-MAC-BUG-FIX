#!/usr/bin/env bash
# ==============================================================================
# HRL-X-MAC-BUG-FIX: Safari Health & WebKit Diagnostic Inspector
# ==============================================================================
# Inspects running Safari instances, window/tab metrics, WebContent processes,
# and identifies dead/crashed tabs causing LaunchServices dispatch blockage.
# ==============================================================================

set -euo pipefail

echo "========================================================"
echo "  HRL-X-MAC-BUG-FIX: Safari & WebKit Health Inspector  "
echo "========================================================"

# 1. Process Status
SAFARI_PID=$(pgrep -x Safari || true)
if [ -z "$SAFARI_PID" ]; then
    echo "[!] Safari is NOT running."
    exit 0
fi

echo "[+] Safari Main Process PID: $SAFARI_PID"

# 2. Count WebContent / Rendering Processes
WEB_CONTENT_COUNT=$(ps aux | grep -i "com.apple.WebKit.WebContent" | grep -v grep | wc -l | tr -d ' ')
echo "[+] Active WebContent Rendering Processes: $WEB_CONTENT_COUNT"

# 3. Memory Consumption of Safari + Helpers
TOTAL_SAFARI_MEM=$(ps aux | grep -iE "Safari|WebKit" | grep -v grep | awk '{sum += $6} END {print sum/1024 " MB"}')
echo "[+] Total Safari & WebKit Resident Memory: $TOTAL_SAFARI_MEM"

# 4. Window & Tab Metrics via AppleScript
echo ""
echo "[*] Querying Safari Windows & Tabs..."
osascript -e '
tell application "Safari"
    if not (exists (windows)) then
        return "No open Safari windows."
    end if
    set wCount to count of windows
    set totalTabs to 0
    set deadTabCount to 0
    set out to "Total Windows: " & wCount & return
    
    repeat with i from 1 to wCount
        set w to window i
        set tCount to count of tabs of w
        set totalTabs to totalTabs + tCount
        set currentTitle to name of current tab of w
        set out to out & "  - Window " & i & " (" & tCount & " tabs): [" & currentTitle & "]" & return
        
        repeat with j from 1 to tCount
            set t to tab j of w
            if (URL of t is missing value) or (URL of t is "") then
                set deadTabCount to deadTabCount + 1
                set out to out & "    [!] DEAD TAB: Window " & i & " Tab " & j & " [" & (name of t) & "]" & return
            end if
        end repeat
    end repeat
    
    set out to out & return & "Summary:" & return
    set out to out & "  Total Tabs: " & totalTabs & return
    set out to out & "  Dead/Crashed Tabs: " & deadTabCount & return
    return out
end tell
'

echo "========================================================"
echo "Health check complete."
