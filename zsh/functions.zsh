
source ~/.functions_colors_shell.zsh

# functions and load-onces stuff for the environment
echo "function config"
source ~/.functions_shell.sh
source ~/.functions_colors.sh
source ~/.functions_dev.sh
source ~/.functions_osx.sh
source ~/.functions_graphics.sh

# Vim IDE settings
source ~/.bash_vim_append

alias mkdir=/bin/mkdir
alias ll='ls -alGh'

export PATH="$HOME/.dotfiles/bin:$PATH"
