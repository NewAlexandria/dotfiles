
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

test -e "${HOME}/.dotfiles/mac/iterm2_shell_integration.sh" && source "${HOME}/.dotfiles/mac/iterm2_shell_integration.sh"

alias mkdir=/bin/mkdir
alias ll='ls -alGh'

export PATH="$HOME/.dotfiles/bin:$PATH"
