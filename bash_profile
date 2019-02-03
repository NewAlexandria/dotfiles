#!/usr/bin/sh
# functions and load-onces stuff for the environment
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
export PATH="/usr/local/opt/node@8/bin:$PATH"
export PATH=~/.sem/bin:$PATH
eval "$(rbenv init -)"

test -e "${HOME}/.iterm2_shell_integration.bash" && source "${HOME}/.iterm2_shell_integration.bash"

# Aliases
## FileSystem
alias ll='ls -alGh'
alias les='less -FRSXQ'

alias cdd='cd ~/.ssh/'
alias cddot='cd ~/.dotfiles/'
alias cds='cd ~/src/'

alias ..='cd ../'                           # Go back 1 directory level
alias ...='cd ../../'                       # Go back 2 directory levels
alias .3='cd ../../../'                     # Go back 3 directory levels
alias .4='cd ../../../../'                  # Go back 4 directory levels
alias .5='cd ../../../../../'               # Go back 5 directory levels
alias .6='cd ../../../../../../'            # Go back 6 directory levels

alias ag='ag --color  --color-path=37  --color-line-number=32'
alias dif='colordiff'
alias ack='ack --color-lineno=green --color-filename=white --color --follow'


source ~/.profile

