# WebKit Process Management & macOS LaunchServices Architecture

This guide details the internal execution model of Apple WebKit on macOS and explains why extreme tab counts cause LaunchServices link dispatch failures.

---

## 1. Process Isolation Architecture

Modern Safari on macOS uses a multi-process architecture based on Apple's WebKit framework:

```
┌─────────────────────────────────────────────────────────────┐
│                    Safari UI Process                        │
│                 (/Applications/Safari.app)                  │
│                                                             │
│  - Window Management & Tab Bar State                       │
│  - Bookmarks & Pinned Tabs Registry                         │
│  - Apple Event / LaunchServices Dispatch (kAEGetURL)        │
└───────────────┬─────────────────────────────┬───────────────┘
                │                             │
        (IPC / Mach Ports)            (IPC / Mach Ports)
                │                             │
                ▼                             ▼
┌───────────────────────────────┐ ┌───────────────────────────┐
│     WebKit Network Process    │ │     WebKit GPU Process    │
│  (HTTP/3, Cookies, DNS cache) │ │ (Metal, Canvas, Hardware) │
└───────────────────────────────┘ └───────────────────────────┘
                │
        (IPC / Mach Ports)
                │
                ▼
┌─────────────────────────────────────────────────────────────┐
│             WebKit WebContent Rendering Pool                │
│            (com.apple.WebKit.WebContent)                    │
│                                                             │
│  [Tab Process 1]  [Tab Process 2]  ...  [Tab Process 54+]   │
└─────────────────────────────────────────────────────────────┘
```

### Key Components
1. **Safari UI Process**: The main application thread managing windows, toolbars, user interaction, and system events.
2. **WebKit WebContent Processes**: Sandboxed rendering processes hosting the DOM, JavaScript execution, and CSS styling for individual tabs or origins.
3. **WebKit Network Process**: Centralized daemon handling networking, HTTP caching, and certificate validation.

---

## 2. The Link Dispatch Failure Mechanism

When a user clicks a hyperlink in an external application (VS Code, Discord, Terminal, Slack, etc.):

```
[External App: e.g. Discord]
       │
       ▼
[LaunchServices Daemon: lsd]
       │
       ▼  (kAEGetURL Apple Event via Mach port)
[Safari UI Process: BrowserDocumentController]
       │
       ├──► Check Active Profile & Window
       │
       ├──► Check WebProcess Pool Availability
       │       │
       │       ├── If Dead/Hanging WebProcess in Queue:
       │       │       └── [BLOCK / DROP EVENT] ◄── GLITCH OCCURS HERE
       │       │
       │       └── If Healthy:
       │               └── Spawn / Assign WebContent Process ──► Load URL
```

### Why Dead Tabs Block Link Loading
1. **Unresponsive Mach Ports**: When a WebContent process crashes (such as during a Cloudflare challenge timeout or memory spike), its Mach port channel may remain registered but unresponsive.
2. **Missing-URL State**: Safari represents these hung tabs with `URL: missing value`.
3. **Queue Stalling**: When an incoming `kAEGetURL` event arrives, the `BrowserDocumentController` attempts to query or re-use existing tabs or evaluate document suitability. A hung WebProcess causes the synchronous IPC call to time out or stall, preventing the creation of a new tab.

---

## 3. Reverse-Index Pruning Strategy

When scripting tab manipulation via AppleScript, iterating forward (`from 1 to count`) causes index shifting when a tab is closed:

```applescript
-- WRONG: Forward iteration skips elements
repeat with i from 1 to count of tabs of w
    if condition then close tab i of w  -- Next tab shifts into index i!
end repeat

-- CORRECT: Reverse iteration maintains valid indices
repeat with i from (count of tabs of w) to 1 by -1
    if condition then close tab i of w  -- Lower indices remain untouched
end repeat
```

---

## 4. Best Practices for High-Tab Mac Workflows
- **Keep Pinned Tabs < 10**: Pinned tabs are replicated across every Safari window and hold persistent memory.
- **Clear Suspended Sessions**: Periodically run `safari_kill_dead_tabs.applescript` to remove orphaned tabs.
- **Weekly Safari Restart**: Restarting Safari refreshes the WebKit WebContent process pool and reclaims Mach port descriptors.
