#!/usr/bin/sh

# set dotfiles repo path for later use
# v-naise https://stackoverflow.com/a/246128/263858
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
#DOTFILES_REPO="$( dirname "$SOURCE" )"
DOTFILES_REPO="/Users/$(whoami)/.dotfiles"

function getuser() {
  if [ -z "$LOGNAME" ]; then
    if [ -z "$USER" ]; then
      if [ -z "$LNAME" ]; then
        if [ -z "$USERNAME" ]; then
          # do nothing
        else
          echo "$USERNAME"
        fi
      else
        echo "$LNAME"
      fi
    else
      "$USER"
    fi
  else
    "$LOGNAME"
  fi
}

# Aliases

## Display
alias rless='less -Xr'
alias dif='colordiff'

#alias ls='lsd'

alias ll='lsd -Alh'
alias lll='exa -lh'
#alias ll='ls -alGh'
alias les='less -FRSXQ'

## Navigation

alias cd.='cd ~/.ssh/'
alias cddot='cd ~/.dotfiles/'
alias cds='cd ~/src/'

alias ..='cd ../'                # Go back 1 directory level
alias ...='cd ../../'            # Go back 2 directory levels
alias .3='cd ../../../'          # Go back 3 directory levels
alias .4='cd ../../../../'       # Go back 4 directory levels
alias .5='cd ../../../../../'    # Go back 5 directory levels
alias .6='cd ../../../../../../' # Go back 6 directory levels

man() {
  env \
    LESS_TERMCAP_mb=$(printf "\e[1;31m") \
    LESS_TERMCAP_md=$(printf "\e[1;31m") \
    LESS_TERMCAP_me=$(printf "\e[0m") \
    LESS_TERMCAP_se=$(printf "\e[0m") \
    LESS_TERMCAP_so=$(printf "\e[1;44;33m") \
    LESS_TERMCAP_ue=$(printf "\e[0m") \
    LESS_TERMCAP_us=$(printf "\e[1;32m") \
    man "$@"
}

## Finding in Files
alias ag='ag --color  --color-path=37  --color-line-number=32'
alias ack='ack --color-lineno=green --color-filename=white --color --follow'

# export GREP_OPTIONS="--color=auto --line-number --context=0 --exclude=*.log"
export GREP_COLOR="1;37;41"

# parallel bash commands
# http://www.rankfocus.com/use-cpu-cores-linux-commands/
function pgrep() {
  cat $1 | parallel --block 10M --pipe grep $2
}

function jcp() {
  the_path=$1
  #[ ! -x $1 ] || the_path='.'
  q=$2
  [ ! -x $2 ] || q='.'
  cat ~/.ssh/$the_path.json | jq $q -r | tr -d '\n' | pbcopy
}

function 2fa() {
  the_path=$1
  q=$2
  [ ! -x $2 ] || q='.mfa_key'
  n=$3
  [ ! -x $3 ] || n='2'
  oathtool --base32 -w $n $(jq $q ~/.ssh/$the_path.json -r)
}

## File Finders

# quick get of MB or GB files
alias bigs='du -sh  * | grep "[0-9][MG]"'

# find files that are 10MB in size, or larger
# takes PATH as an argument
function llg() {
  the_path=$1
  [ ! -x $1 ] || the_path='.'
  ll "$the_path" | grep "[0-9][0-9]\(\.[0-9]\)\?M "
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

function rm_icon() {
  find . -name 'Icon?' -delete
}

# Term Functions
function wtitle() { echo -ne "\033]0;$1\007"; }

function ssh_keygen_fingerprint() {
  ssh-keygen -lv -f $1
}

function mvnospace() {
  mv "$1" "${1// /-}"
}

function cp_dir_structure() {
  excl=$3
  [ ! -z $3 ] || excl='xattr'
  rsync -av --exclude '$excl' -f"+ */" -f"- *" "$1" "$2"
}

#   extract:  Extract most know archives with one command
#   ---------------------------------------------------------
extract() {
  if [ -f $1 ]; then
    case $1 in
    *.tar.bz2) tar xjf $1 ;;
    *.tar.gz) tar xzf $1 ;;
    *.bz2) bunzip2 $1 ;;
    *.rar) unrar e $1 ;;
    *.gz) gunzip $1 ;;
    *.tar) tar xf $1 ;;
    *.tbz2) tar xjf $1 ;;
    *.tgz) tar xzf $1 ;;
    *.zip) unzip $1 ;;
    *.Z) uncompress $1 ;;
    *.7z) 7z x $1 ;;
    *) echo "'$1' cannot be extracted via extract()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

function random() {
  num=$1
  [ ! -z $1 ] || num='12'
  env LC_CTYPE=C LC_ALL=C tr -dc "a-zA-Z0-9-_\^\&\$\?\(\)\*\#\@\!\%" </dev/urandom | head -c $num
  echo
  #openssl rand -base64 $num
}

function pghsol() {
  ruby -e "require 'time'; puts 'Sol ' + (Date.today.mjd - DateTime.parse('2022-08-01').mjd + 1).to_s"
}
