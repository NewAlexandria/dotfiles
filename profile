#!/usr/bin/sh
# ======================================
# Bash profile, reload with `. .profile`
# ======================================

# Common bin paths
# ----------------
export PATH="$HOME/.rbenv/bin:/usr/local/bin:/usr/local/sbin:/opt/swt/bin:$PATH"
export PATH="$PATH:$HOME/.dotfiles/bin:"

# Custom prompt
# -------------
export PS1='\[\033[01;34m\]\u@\h\[\033[00m\]\] \w\033[32m\]$(__git_ps1) \[\033[38;5;202m\]\nΨ \[\033[00m\]'
#   prompt   color  bold   u@host color  stop  path color green git-repo 256code fg color lf Ψ norm. color" 
#                            ^^--replace this if you're working locally" 
#  for bash ANSI color codes, use the profile_functions colors() and colors_256()
#  http://bitmote.com/index.php?post/2012/11/19/Using-ANSI-Color-Codes-to-Colorize-Your-Bash-Prompt-on-Linux
export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced


# Vim/Emacs key syntax for bash
# -----------------------------
# set -o vi
set -o emacs
export EDITOR="vim "

# History settings
# ----------------
export HISTCONTROL=erasedups
export HISTSIZE=10000
shopt -s histappend
PROMPT_COMMAND="history -a;$PROMPT_COMMAND"

# Services
# --------
unset MAILCHECK

# Building
# --------
export PATH=~/.rbenv/shims:$PATH
eval "$(rbenv init -)"  # config for rbenv
export CC=gcc-4.2
alias gcc=cc
alias gcc-4.2=cc

export NODE_PATH="/usr/local/lib/jsctags:${NODE_PATH}"
export NODE_PATH=/usr/local/lib/jsctags/:$NODE_PATH
export PATH="$PATH:/usr/local/opt/go/libexec/bin:"

# use .profile.local for setting machine-specific options
[[ -f ~/.profile.local ]] && .  ~/.profile.local

export PATH="$HOME/.dotfiles/bin:$PATH"
