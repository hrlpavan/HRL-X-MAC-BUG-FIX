# HRL X MAC BUG FIX

> **Automated Diagnostics, WebKit Process Pool Resolution, and Safari State Recovery Suite for macOS.**

[![Dual Sync: GitHub & GitLab](https://img.shields.io/badge/Dual--Sync-GitHub%20%7C%20GitLab-brightgreen.svg)](https://github.com/hrlpavan/HRL-X-MAC-BUG-FIX)
[![Platform: macOS](https://img.shields.io/badge/Platform-macOS%2027.x+-lightgrey.svg)](https://apple.com)
[![Engine: AppleScript & Bash](https://img.shields.io/badge/Automation-AppleScript%20%7C%20Bash-orange.svg)]()
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## Overview

**HRL X MAC BUG FIX** is a specialized engineering toolkit and incident archive created to resolve edge-case glitches in macOS Safari and developer OAuth workflows on Apple Silicon systems.

This repository codifies the automated diagnostics, AppleScript surgical pruning scripts, and LaunchServices event queue recovery mechanisms developed to eliminate:
1. **The Sticky Tab Redirection Glitch** (Uncontrolled focus snapping to stalled portal sessions under heavy pinned-tab loads).
2. **LaunchServices `kAEGetURL` Dispatch Lockups** (Safari failing to open external hyperlinks due to crashed `missing value` WebContent processes).
3. **GitHub OAuth Scope Masking Issues** (Account creation rejections caused by private noreply email masking).

---

## Incident Summary & Root Cause Matrix

| Incident | Primary Symptom | Root Cause | Automated Resolution |
| :--- | :--- | :--- | :--- |
| **01. Stalled Tab Snapping** | Link clicks snap focus to Startup India portal | 213 tabs + 35 pinned tabs across 5 windows; stuck JavaScript session in Window 4 | Reverse-index tab pruning via AppleScript |
| **02. GitHub OAuth Failure** | "Unable to Sign In with GitHub" error | GitHub "Keep my email addresses private" hides verified address from OAuth providers | Email privacy configuration update |
| **03. Dispatch Queue Lockup** | Safari won't open new links from external apps | 12 windows, 112 tabs, 54 WebProcesses; crashed tabs with `missing value` URLs block `kAEGetURL` | Terminated dead tabs & pruned ghost single-tab windows |

---

## Toolkit Structure

```
HRL-X-MAC-BUG-FIX/
├── README.md                                  # Repository overview and quickstart
├── LICENSE                                    # MIT License
├── .gitignore                                 # Git configuration
├── docs/
│   ├── INCIDENT_LOG.md                        # Full incident timeline, metrics & telemetry
│   └── WEBKIT_PROCESS_MANAGEMENT.md           # Deep-dive into WebKit & LaunchServices architecture
└── scripts/
    ├── safari_health_check.sh                 # Inspects PIDs, memory, WebContent pool & dead tabs
    ├── safari_kill_dead_tabs.applescript       # Reverse-index purger for missing-URL tabs
    ├── safari_cleanup_duplicates.applescript   # Cleans duplicate URLs, 404s & stale OAuth redirects
    ├── safari_test_link_dispatch.sh           # Verifies LaunchServices IPC dispatch latency
    └── safari_emergency_reset.sh              # Safe cache flush and clean relaunch tool
```

---

## Quickstart & Usage

### 1. Run the Safari Health Inspector
Inspect active Safari PIDs, total WebContent rendering processes, resident memory, and identify any dead/crashed tabs:
```bash
chmod +x scripts/*.sh
./scripts/safari_health_check.sh
```

### 2. Purge Dead & Crashed Tabs
If Safari stops opening links or becomes sluggish, run the reverse-index tab purger:
```bash
osascript scripts/safari_kill_dead_tabs.applescript
```

### 3. Clean Stale OAuth Redirects & Duplicate Tabs
Prune expired OAuth callback URLs (e.g., `login.nvidia.com/callback/redirect?code=...`) and redundant open pages:
```bash
osascript scripts/safari_cleanup_duplicates.applescript
```

### 4. Verify Link Dispatch Health
Test that LaunchServices can successfully dispatch external URLs to Safari without stalling:
```bash
./scripts/safari_test_link_dispatch.sh
```

### 5. Emergency Clean Reset
If Safari becomes completely unresponsive, perform a clean reset without losing history or bookmarks:
```bash
./scripts/safari_emergency_reset.sh
```

---

## Dual Sync Protocol

This repository is mirrored simultaneously across **GitHub** and **GitLab**:
- **GitHub**: [`hrlpavan/HRL-X-MAC-BUG-FIX`](https://github.com/hrlpavan/HRL-X-MAC-BUG-FIX)
- **GitLab**: [`hrlpavan/HRL-X-MAC-BUG-FIX`](https://gitlab.com/hrlpavan/HRL-X-MAC-BUG-FIX)

To push changes to both remotes in a single command, use the configured dual-push remote:
```bash
git push origin main
```

---

## License

Distributed under the [MIT License](LICENSE).
Copyright © 2026 Pavan Kumar Sadashiv (HRL).
