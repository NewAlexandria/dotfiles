#!/usr/bin/sh
echo "OSX config"

## iTerm config
test -e "${HOME}/.dotfiles/mac/iterm2_shell_integration.bash" && source "${HOME}/.dotfiles/mac/iterm2_shell_integration.bash"


## Brew

alias brewup="brew upgrade $(brew outdated | cut -d ' ' -f1 | grep -v mysql | cut -d ':' -f2 | xargs)"
alias brewpull="brew update && brew upgrade && brew cleanup && brew cleanup -s --prune=all"

alias brew_deptree="brew deps --installed --tree"
function brewreset() {
  nam=$1
  brew unlink $nam
  brew uninstall $nam
  mkdir -p /usr/local/Cellar/$nam
  # chown -R $(whoami):admin   /usr/local/Cellar/$nam
  sudo chown -R $(whoami):admin   /usr/local/Cellar/$nam
  brew install $nam
}

function brewdump() {
  fout=$1
  # [ ! -x $1 ] || fout='~/.dotfiles/brewfile_new'
  [ ! -x $1 ] || fout="$DOTFILES_REPO/Brewfile_new"
  brew bundle dump --file=$fout
}


function diffbrewfile() {
  newfile=$1
  [ ! -x $1 ] || newfile='HEAD'
  oldfile=$2
  [ ! -x $2 ] || oldfile='HEAD'
  ruby -e "puts File.readlines('$newfile').sort - File.readlines('$oldfile').sort" > Brewfile.removed
  ruby -e "puts File.readlines('$oldfile').sort - File.readlines('$newfile').sort" > Brewfile.added
}


## Aliases
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



## Functions
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
function pboard_fix() {
  sudo kill -9 `ps aux | grep pboard | grep -v "grep" | awk '{print $2}'`
  sudo killall -KILL Finder
}

function rm_icons() {
  echo 'Removing Icon files from Documents...'
  find "${1}" -type f -name 'Icon?' -print -delete;
}

# OSX helpers
## Open man pages in Preview
function pman() {
  man -t "${1}" | open -f -a /Applications/Preview.app/
}

## Open in Preview
function pv() {
  open -a /Applications/Preview.app/ "${1}"
}

## Open markdown in MacDown
function m() {
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

source "${DOTFILES_REPO}/lib/osx-shell-battery/functions_battery.sh"

function killdock() {
  # Dock, Finder, SystemUIServer
  syspart=$1
  [ ! -x $1 ] || syspart='Dock'
  killall -KILL $syspart
}
