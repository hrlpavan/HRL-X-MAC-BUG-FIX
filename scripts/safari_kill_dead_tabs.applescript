-- ==============================================================================
-- HRL-X-MAC-BUG-FIX: Terminate Crashed / Missing-URL Tabs in Safari
-- ==============================================================================
-- Scans all open windows and safely terminates tabs where the URL is
-- missing value or empty (indicating a crashed WebContent process),
-- using reverse-index iteration to prevent index shifting.
-- ==============================================================================

tell application "Safari"
    if not (exists (windows)) then
        return "No Safari windows open."
    end if
    
    set closedCount to 0
    set wCount to count of windows
    
    repeat with wIdx from wCount to 1 by -1
        set w to window wIdx
        set tCount to count of tabs of w
        
        repeat with tIdx from tCount to 1 by -1
            set t to tab tIdx of w
            if (URL of t is missing value) or (URL of t is "") then
                try
                    close t
                    set closedCount to closedCount + 1
                end try
            end if
        end repeat
        
        -- If window is now empty, close the window
        if (count of tabs of w) is 0 then
            try
                close w
            end try
        end if
    end repeat
    
    return "Successfully purged " & closedCount & " dead/crashed tabs."
end tell
