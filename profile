# ======================================
# Bash profile, reload with `. .profile`
# ======================================

# Common bin paths
# ----------------
export PATH="$HOME/.rbenv/bin:/usr/local/bin:/usr/local/sbin:/opt/swt/bin:/bb/blaw/tools/bin:$PATH"

# Custom prompt
# -------------
export PS1='\[\033[01;34m\]\u@\h\[\033[00m\]\] \w\033[32m\]$(__git_ps1) \[\033[31m\]| \[\033[00m\]'
export PS1='\[\033[01;34m\]\u@\h\[\033[00m\]\] \w\033[32m\]$(__git_ps1) \[\033[38;5;202m\]Ψ \[\033[00m\]'
#   prompt   color  bold   u@host color  stop  path color green git-repo 256code fg color Ψ  norm. color" 
#                            ^^--replace this if you're working locally" 
#  for bash ANSI color codes, use the profile_functions colors() and colors_256()
#  http://bitmote.com/index.php?post/2012/11/19/Using-ANSI-Color-Codes-to-Colorize-Your-Bash-Prompt-on-Linux

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
export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced
EDITOR="vim -u NONE"; export EDITOR
export PATH=~/.rbenv/shims:$PATH
eval "$(rbenv init -)"  # config for rbenv
export CC=gcc-4.2


# use .profile.local for setting machine-specific options
[[ -f ~/.profile.local ]] && .  ~/.profile.local


