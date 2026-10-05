-- ==============================================================================
-- HRL-X-MAC-BUG-FIX: Prune Stale OAuth Callbacks & Duplicate Tabs
-- ==============================================================================
-- Eliminates single-use expired OAuth callback tabs and duplicate URLs.
-- ==============================================================================

tell application "Safari"
    if not (exists (windows)) then
        return "No Safari windows open."
    end if
    
    set closedReport to ""
    set closedTotal to 0
    set seenURLs to {}
    
    repeat with wIdx from (count of windows) to 1 by -1
        set w to window wIdx
        set tCount to count of tabs of w
        
        repeat with tIdx from tCount to 1 by -1
            set t to tab tIdx of w
            set thisURL to (URL of t as string)
            
            -- Check for single-use OAuth callback redirects
            if (thisURL contains "oauth") and (thisURL contains "code=") then
                close t
                set closedTotal to closedTotal + 1
                set closedReport to closedReport & "Closed stale OAuth redirect: " & thisURL & return
            else if (thisURL contains "login.nvidia.com/callback/redirect") then
                close t
                set closedTotal to closedTotal + 1
                set closedReport to closedReport & "Closed stale NVIDIA OAuth callback" & return
            else if (thisURL contains "404") or (name of t contains "Site not found") then
                close t
                set closedTotal to closedTotal + 1
                set closedReport to closedReport & "Closed 404 page: " & thisURL & return
            else
                -- Check for identical duplicate URLs across session
                if (thisURL is not missing value) and (thisURL is not "") and (thisURL is not "favorites://") then
                    if seenURLs contains thisURL then
                        close t
                        set closedTotal to closedTotal + 1
                        set closedReport to closedReport & "Closed duplicate tab: " & thisURL & return
                    else
                        set end of seenURLs to thisURL
                    end if
                end if
            end if
        end repeat
        
        -- Clean up single-tab empty ghost windows
        if (count of tabs of w) is 0 then
            try
                close w
            end try
        end if
    end repeat
    
    return "Total closed tabs: " & closedTotal & return & closedReport
end tell
