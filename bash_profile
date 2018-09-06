#!/usr/bin/sh
# functions and load-onces stuff for the environment
source ~/.profile
source ~/.functions_shell.sh
source ~/.functions_colors.sh
source ~/.functions_dev.sh
source ~/.functions_osx.sh
source ~/.functions_graphics.sh

# aliases and variables that should be available in any sub-shell or certain processes
source ~/.bashrc
source ~/.bashrc_local

# Vim IDE settings
source ~/.bash_vim_append

export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

alias gcc=cc
alias gcc-4.2=cc

test -e "${HOME}/.iterm2_shell_integration.bash" && source "${HOME}/.iterm2_shell_integration.bash"
