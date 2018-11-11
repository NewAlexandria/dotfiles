#!/usr/bin/sh

alias brewup="brew upgrade $(brew outdated | cut -d ' ' -f1 | grep -v mysql | cut -d ':' -f2 | xargs)"
alias brew_deptree="brew deps --installed --tree"
alias act="open -a Activity\ Monitor.app"

# security control
alias sec_policy_enable="sudo spctl --master-enable"
alias sec_policy_disable="sudo spctl --master-disable"

# spotlight control
alias spsize="sudo du -m /.Spotlight-V100"
alias spon="sudo mdutil -a -i on"
alias spof="sudo mdutil -a -i off"
alias spoff="spof"
alias spmds='sudo lsof -c "/mds$/"'

alias nettetherorder='sudo networksetup -ordernetworkservices "Display Ethernet" "Thunderbolt Ethernet" "Display FireWire" "Bluetooth PAN" "Wi-Fi"  "iPhone USB" "Thunderbolt Bridge"'
alias netwifiorder='sudo networksetup -ordernetworkservices "Display Ethernet" "Thunderbolt Ethernet" "Display FireWire" "Wi-Fi" "Bluetooth PAN" "iPhone USB" "Thunderbolt Bridge"'

cdf () {
    currFolderPath=$( /usr/bin/osascript <<EOT
        tell application "Finder"
            try
        set currFolder to (folder of the front window as alias)
            on error
        set currFolder to (path to desktop folder as alias)
            end try
            POSIX path of currFolder
        end tell
EOT
    )
    echo "cd to \"$currFolderPath\""
    cd "$currFolderPath"
}

# workaround for Timeout
# http://apple.stackexchange.com/q/234419/37586
pboard_fix() {
  sudo kill -9 `ps aux | grep pboard | grep -v "grep" | awk '{print $2}'`
  sudo killall -KILL Finder
}

# OSX helpers
## Open man pages in Preview
pman() {
  man -t "${1}" | open -f -a /Applications/Preview.app/
}

## Open in Preview
pv() {
  open -a /Applications/Preview.app/ "${1}"
}

## Open markdown in MacDown
md() {
  open -a /Applications/MacDown.app/Contents/MacOS/MacDown "${1}"
}

# Fidder seOWASP tool
function  fiddler() {
  mono /Applications/fiddler-mac/Fiddler.exe
}

## Open git kraken
gitkraken() {
  /Applications/GitKraken.app/Contents/MacOS/GitKraken "${1}" &
}
alias gk=gitkraken

source ~/.dotfiles/lib/osx-shell-battery/functions_battery.sh
