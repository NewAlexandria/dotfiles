#!/bin/bash

# Change PyCharm theme

# Assumes default key mappings
# Switch to dark theme if macOS dark mode is on
# 2>/dev/null to suppress error if macOS dark mode is off
if defaults read -g AppleInterfaceStyle 2>/dev/null | grep -q "Dark"; then
    osascript -e '
        if application "PyCharm" is running then
            -- switch focus to PyCharm
            tell application "PyCharm" to activate
            tell application "System Events"
                -- open Quick Switch Theme menu
                keystroke "`" using {control down}
                -- Select Look and Feel
                keystroke "5"
                delay 0.4
                -- Select Darcula
                keystroke "2"
            end tell
        end if
        '
# Switch to light theme if macOS dark mode is off
else
    osascript -e '
        if application "PyCharm" is running then
          tell application "PyCharm" to activate
            tell application "System Events"
                keystroke "`" using {control down}
                keystroke "5"
                delay 0.4
                keystroke "1"
            end tell
        end if
        '
fi
