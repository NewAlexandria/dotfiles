#!/usr/bin/sh

# Functions
function wtitle() { echo -ne "\033]0;$1\007"; }

function ssh_keygen_fingerprint() {
  ssh-keygen -lv -f $1
}


function find_in_min() {
  find . -type d -name .svn -prune -o -mmin -${1} -type f -print
}

function ff() {
  find . -type f -name "*${1}*"
}
function ffrm() {
  find . -name ${1} -depth -exec rm {} \;
}


#   extract:  Extract most know archives with one command
#   ---------------------------------------------------------
extract () {
    if [ -f $1 ] ; then
      case $1 in
        *.tar.bz2)   tar xjf $1     ;;
        *.tar.gz)    tar xzf $1     ;;
        *.bz2)       bunzip2 $1     ;;
        *.rar)       unrar e $1     ;;
        *.gz)        gunzip $1      ;;
        *.tar)       tar xf $1      ;;
        *.tbz2)      tar xjf $1     ;;
        *.tgz)       tar xzf $1     ;;
        *.zip)       unzip $1       ;;
        *.Z)         uncompress $1  ;;
        *.7z)        7z x $1        ;;
        *)     echo "'$1' cannot be extracted via extract()" ;;
         esac
     else
         echo "'$1' is not a valid file"
     fi
}

# find files that are 10MB in size, or larger
# takes PATH as an argument
function llg() {
  the_path=$1
  [ ! -x $1 ] || the_path='.'
  ll "$the_path" | grep "[0-9][0-9]\(\.[0-9]\)\?M "
}

alias rless='less -Xr'

# export UNITS="$(brew --cellar gnu-units)/$(gunits -V | head -n 1 | awk '{ print $4 }')/share/units/definitions.units'
# /usr/share/misc/units.lib

pathed_cd () {
  if [ "$1" == "" ]; then
    builtin cd
  else
    builtin cd "$1"
  fi
  pwd > ~/.cdpath
}
alias cd="pathed_cd"
if [ -f ~/.cdpath ]; then
  cd $(cat ~/.cdpath)
fi


