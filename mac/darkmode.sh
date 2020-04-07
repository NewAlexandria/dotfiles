#!/bin/bash

# Switch macOS dark mode on and off
osascript -e '
    tell application "System Events"
        tell appearance preferences
            set dark mode to not dark mode
        end tell
    end tell
'

source "$DOTFILES_REPO/mac/darkmode_manual_apps.sh"
