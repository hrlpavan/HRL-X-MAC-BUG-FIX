# Incident Log: macOS Safari Glitch Diagnostics & Resolution

This document records the diagnostics, root cause analyses, telemetry, and remediation protocols executed for issues affecting macOS Safari and third-party developer integrations.

---

## Incident 1: Tab-Focus Snapping & Stalled Portal Redirection Loop

### Telemetry & Symptoms
- **Reported Symptom**: Clicking external or in-app links caused Safari to bounce/redirect to the Government of India DPIIT Startup India portal (`https://www.startupindia.gov.in/content/sih/en/user/my-dashboard/Corporate.html#`).
- **Active State Metrics**:
  - Open Safari Windows: 5
  - Active Tab Count: 213 tabs
  - Shared Pinned Tabs: 35 tabs shared across all 5 windows
  - Frontmost Window 4 State: Tab 36 was stuck holding an active, complex JavaScript session on `Corporate.html#`.
  - Address Bar State: Displayed `Search or enter website name` placeholder due to focus loss under high tab count.

### Root Cause Analysis
1. Under heavy tab loads (200+ tabs and 35 persistent pinned tabs), Safari's internal window controller experienced tab routing degradation.
2. In macOS Sonoma / Sequoia, when incoming links with generic targets (`_blank` or unnamed window requests) were opened, Safari's window indexing failed to spawn a distinct tab and instead snapped focus to the pre-existing window and tab holding the active Corporate dashboard session.
3. This gave the appearance that every link was "redirecting" to Startup India, when in reality the browser was repeatedly re-focusing the stuck tab.

### Remediation Protocol
- Automated AppleScript query identified all instances of `startupindia.gov.in` and `Corporate.html#`.
- Implemented reverse-index loop (`repeat with i from tCount to 1 by -1`) to cleanly terminate target tabs without index-shifting errors.
- Verified removal across all 5 windows.
- Executed link navigation tests confirming that subsequent clicks spawned clean tabs.

---

## Incident 2: GitHub OAuth Email Scope Masking Failure

### Telemetry & Symptoms
- **Reported Symptom**: Third-party developer platform rejected sign-in with the error:
  `"Unable to Sign In with GitHub: We couldn't sign you in because your GitHub account is configured to keep your email address private."`
- **Security Event**: Third-party OAuth application requested `user:email` scope, but received an anonymous noreply alias (`<id>+username@users.noreply.github.com`).

### Root Cause Analysis
- The user's GitHub account had the security feature **"Keep my email addresses private"** enabled in `Settings > Emails`.
- When external OAuth providers require a verified, primary email for account provisioning or domain matching, receiving a masked or private email fails validation and aborts the login flow.

### Remediation Protocol
- Navigated to `https://github.com/settings/emails`.
- De-selected "Keep my email addresses private" to expose the primary verified address to authorized OAuth apps.
- Verified successful authentication on the destination service.

---

## Incident 3: WebContent Process Pool Lockup & LaunchServices `kAEGetURL` Event Queue Blockage

### Telemetry & Symptoms
- **Reported Symptom**: Safari completely stopped opening new links. Clicking links in external applications (Discord, VS Code, Mail, Terminal) or using system `open <url>` failed to load pages. Safari would activate or switch windows but the requested URL never loaded.
- **Active State Metrics**:
  - Open Safari Windows: 12
  - Active Tabs: 112
  - Background WebContent Rendering Processes: 54 (`com.apple.WebKit.WebContent`)
  - Ghost Single-Tab Windows: 2 (redundant single-tab windows)
  - Dead/Crashed Tabs Detected: 3 tabs with `URL: missing value` (including crashed Cloudflare challenge sessions and `[Untitled]` frames).

### Root Cause Analysis
1. When a WebContent process crashes or stalls during a challenge/handshake, Safari leaves an `[Untitled]` tab holding a `missing value` URL pointer.
2. The macOS LaunchServices subsystem dispatches incoming URLs via `kAEGetURL` Apple Events to `com.apple.Safari`.
3. When dead tabs reside in the frontmost window or active profile group, Safari's internal document controller queue becomes blocked waiting on the unresponsive WebProcess pool.
4. As a result, subsequent `kAEGetURL` events are accepted by LaunchServices (exit code 0) but silently dropped or stalled by Safari's main thread.

### Remediation Protocol
1. **Targeted Tab Purge**: Scanned all 12 windows via AppleScript for tabs where `URL is missing value`. Executed reverse-index termination on `Window 4 Tab 3`, `Window 4 Tab 4`, and `Window 12 Tab 1`.
2. **Ghost Window Cleanup**: Terminated single-tab duplicate windows (Windows 2 and 9) that were consuming process slots without serving active content.
3. **Verification**: Executed `open "https://httpbin.org/get"` and `open -a Safari "https://example.com"`. Both URLs loaded instantaneously and were verified via front-tab title checks.
