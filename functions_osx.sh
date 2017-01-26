#!/usr/bin/sh

alias brewup="brew upgrade $(brew outdated | cut -d ' ' -f1 | grep -v mysql | cut -d ':' -f2 | xargs)"
alias brew_deptree="brew deps --installed --tree"
alias act="open -a Activity\ Monitor.app"

# spotlight control
alias spsize="sudo du -m /.Spotlight-V100"
alias spon="sudo mdutil -a -i on"
alias spof="sudo mdutil -a -i off"
alias spoff="spof"
alias spmds='sudo lsof -c "/mds$/"'

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

## Open markdown in Mou
mou() {
  open -a /Applications/Mou.app/Contents/MacOS/Mou "${1}"
}

## Open markdown in Mou
git-kraken() {
  open -a /Applications/GitKraken.app/Contents/MacOS/GitKraken "${1}"
}
alias gk=git-kraken
gitkraken() {
  /Applications/GitKraken.app/Contents/MacOS/GitKraken "${1}" &
}
