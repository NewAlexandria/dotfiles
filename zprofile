
fpath=(/usr/local/share/zsh-completions $fpath)

export TERM="xterm-256color"


# History settings
# ----------------
export HISTCONTROL=erasedups
export HISTSIZE=10000
PROMPT_COMMAND="history -a;$PROMPT_COMMAND"

# Services
# --------
unset MAILCHECK

# Building
# --------
GPG_TTY=$(tty)
export GPG_TTY

export PATH="$HOME/.dotfiles/bin:$PATH"

# set macosx shell
# sudo dscl . -create /Users/$USER UserShell /usr/local/bin/zsh

source ~/.zsh/prompt.zsh
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

# use .profile.local for setting machine-specific options
[[ -f ~/.zprofile.local.zsh ]] && .  ~/.zprofile.local.zsh
