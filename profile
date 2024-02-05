#!/usr/bin/sh
# ======================================
# Bash profile, reload with `. .profile`
# ======================================

# Custom prompt
# -------------
if [ "Users" = ^\/Users* ]; then
  export PS1='\[$(iterm2_prompt_mark)\] \[\033[01;34m\]\u@\h\[\033[00m\]\] \w\033[32m\]$(__git_ps1) \[\033[38;5;202m\]\nΨ \[\033[00m\]'
#             iterm2-prompt             color  bold   u@host color  stop  path color green git-repo 256code fg color lf Ψ norm. color" 
#                                                    ^^--replace this if you're working locally" 
else
  export PS1='\[\033[01;34m\]\u@\h\[\033[00m\]\] \w\033[32m\]$(__git_ps1) \[\033[38;5;202m\]\nΨ \[\033[00m\]'
fi

#  for bash ANSI color codes, use the profile_functions colors() and colors_256()
#  http://bitmote.com/index.php?post/2012/11/19/Using-ANSI-Color-Codes-to-Colorize-Your-Bash-Prompt-on-Linux
export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced


# Vim/Emacs key syntax for bash
# -----------------------------
# set -o vi
set -o emacs
export EDITOR="vim"

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
#export PATH=~/.rbenv/shims:$PATH
export CC=gcc-4.2

# use .profile.local for setting machine-specific options
[[ -f ~/.profile.local ]] && .  ~/.profile.local

