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

# I need to cut field-1 for this to trim evenly
function __batt_state() {
  bstate=$(pmset -g batt | awk '/charging|discharging|charged/ {print $4}' | cut -f1 -d';')
  yellow="$(printf '\033[33m')"
  green="$( printf '\033[32m')"
  red="$(   printf '\033[31m')"
  reset="$( printf '\033[00m')"
  crd='charged'
  crg='charging'
  dcg='discharging'
  case "$bstate" in
    charged)
      echo "$green$crd$reset"
      ;;
    charging)
      echo "$yellow$crg$reset"
      ;;
    discharging)
      echo "$red$dcg$reset"
      ;;
    *)
      echo $bstate
      exit
  esac
}

function __batt_pct() {
  pmset -g batt | egrep '([0-9]+\%).*' -o | cut -f1 -d';'
}

# now, as a function, we can easily handle a conditional
function __batt_time() {
  btime=$(pmset -g batt | grep -Eo '([0-9][0-9]|[0-9]):[0-5][0-9]')
  btime=${btime:2}
  if [[ "$btime" == "0:00" ]]; then echo ''; else echo " [$btime]"; fi
}

