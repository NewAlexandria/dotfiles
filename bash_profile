#!/usr/bin/sh
# functions and load-onces stuff for the environment
echo "function config"
source ~/.functions_shell.sh
source ~/.functions_colors.sh
source ~/.functions_dev.sh
source ~/.functions_osx.sh
source ~/.functions_graphics.sh

# Vim IDE settings
source ~/.bash_vim_append

# Common bin paths
# ----------------
echo "bin PATH config"
export PATH="$HOME/.sem/bin:$PATH"
eval "$(rbenv init -)"
export PATH="$HOME/.rbenv/bin:/usr/local/bin:/usr/local/sbin:/opt/swt/bin:$PATH"

# aliases and variables that should be available in any sub-shell or certain processes
echo "local shell config"
#source ~/.bashrc
#source ~/.bashrc_local
GPG_TTY=$(tty)
export GPG_TTY

# iTerm config
echo "iTerm config"

test -e "${HOME}/.dotfiles/mac/iterm2_shell_integration.bash" && source "${HOME}/.dotfiles/mac/iterm2_shell_integration.bash"

# requires that iTerm have accessibility permissions
if [ $TERM_PROGRAM = "iTerm.app" ]; then
  osascript -e 'tell application "System Events" to keystroke "e" using {command down, shift down}'
fi


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


echo ".profile config"
#source ~/.profile

PATH=$PATH:/opt/metasploit-framework/bin
export PATH=$PATH:/opt/metasploit-framework/bin
