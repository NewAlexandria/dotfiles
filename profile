# ======================================
# Bash profile, reload with `. .profile`
# ======================================

# Common bin paths
# ----------------
export PATH="$HOME/.rbenv/bin:/usr/local/bin:/usr/local/sbin:/opt/swt/bin:/bb/blaw/tools/bin:$PATH"

# Custom prompt
# -------------
export PS1="\[\e]2;\u@\H:\W\a\[\e[0;30;1m\]\w\[\e[0m\]\n$ \H \[\e[31;1m\]| \[\e[0m\]"

# Vim/Emacs key syntax for bash
# -----------------------------
# set -o vi
set -o emacs

# History settings
# ----------------
export HISTCONTROL=erasedups
export HISTSIZE=10000
shopt -s histappend
PROMPT_COMMAND="history -a;$PROMPT_COMMAND"

# Settings
# --------
unset MAILCHECK

GIT_EDITOR="vim -u NONE"; export GIT_EDITOR
export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced
export CC=gcc-4.2

# Custom aliases
# --------------
alias ll='ls -lah'

## Apps

alias les='less -FRSXQ'
alias be='bundle exec'
alias rspec='wtitle "rspec: blaw"; rspec'
# alias rspec='rspec -f d -c'
alias ack='ack --color-lineno=green --color-filename=white --color --follow'
alias dif='colordiff'
# Add color and default options to grep
alias grep='GREP_OPTIONS="--color=auto --ignore-case --line-number --context=0 --exclude=*.log" GREP_COLOR="1;37;41" LANG=C grep'
alias xtermb='xterm -bg black -fg green -cr purple +cm +dc -geometry 80x20+100+50 &'

## Git
alias  gc='git commit'
alias gco='git co'
alias gci='git ci'
alias grb='git rb'
alias  ga='git add'
alias  gs='git status'
alias  gl='git log --graph --full-history --all --color --pretty=tformat:"%x1b[31m%h%x09%x1b[32m%d%x1b[0m%x20%s%x20%x1b[33m(%
an)%x1b[0m"$'
alias gll='git log --graph'

alias  gd='git diff --color'
alias gdf='git diff dev --name-only'
# alias gde="vim $(git diff --name-status --diff-filter=U | cut -f2 | tr '\n' ' ')"
# alias gse="vim $(git status --porcelain | cut -f2 -s -d 'M' | tr '\n' ' ' )"

# alias gcwtc="git commit -m \"`curl http://whatthecommit.com 2>/dev/null | grep '<p>' | sed 's/<p>//'`\""
# alias wtc="echo \"merge-wtc: `curl http://whatthecommit.com 2>/dev/null | grep '<p>' | sed 's/<p>//'`\""

# SVN
alias svnd='svn diff | vimdiff'
alias svns='svn status'



# Add color and default options to grep
# -------------------------------------
alias grep='GREP_OPTIONS="--color=auto --ignore-case --line-number --context=0 --exclude=*.log" GREP_COLOR="1;37;41" LANG=C grep'

# Functions
function wtitle() { echo -ne "\033]0;$1\007"; }
function _ssh_completion() {
  perl -ne 'print "$1 " if /^Host (.+)$/' ~/.ssh/config
}

# Completions
complete -W "$(_ssh_completion)" ssh
complete -W "$(_ssh_completion)" scp




# Tricks
# ------
# Open new shells in most recently visited dir (http://gist.github.com/132456)
#
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

# use .profile.local for setting machine-specific options
[[ -f ~/.profile.local ]] && .  ~/.profile.local
