#!/usr/bin/sh

DOTFILES_REPO="$HOME/.dotfiles"

# functions and load-onces stuff for the environment
source "$DOTFILES_REPO/functions_shell.sh"
source "$DOTFILES_REPO/functions_colors.sh"
source "$DOTFILES_REPO/functions_dev.sh"
source "$DOTFILES_REPO/functions_osx.sh"
source "$DOTFILES_REPO/functions_graphics.sh"

# Vim IDE settings
[[ -f "$HOME/.bash_vim_append" ]] && source "$HOME/.bash_vim_append"

# Common bin paths
# ----------------
export PATH="$HOME/.sem/bin:$PATH"
eval "$(rbenv init -)"
export PATH="$HOME/.asdf/shims:$HOME/.rbenv/bin:/usr/local/bin:/usr/local/sbin:/opt/swt/bin:$PATH"
# export PATH="$HOME/.rbenv/bin:/usr/local/bin:/usr/local/sbin:/opt/swt/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"

# aliases and variables that should be available in any sub-shell or certain processes
#source "$HOME/.bashrc"
#source "$HOME/.bashrc_local"
GPG_TTY=$(tty)
export GPG_TTY

# iTerm config
#echo "iTerm config"

#test -e "$HOME/.dotfiles/mac/iterm2_shell_integration.bash" && source "$HOME/.dotfiles/mac/iterm2_shell_integration.bash"

 #requires that iTerm have accessibility permissions
#if [ $TERM_PROGRAM = "iTerm.app" ]; then
  #osascript -e 'tell application "System Events" to keystroke "e" using {command down, shift down}'
#fi


#source "$HOME/.profile"

PATH=$PATH:/opt/metasploit-framework/bin
export PATH=$PATH:/opt/metasploit-framework/bin

# Disable Homebrew auto-update messages
export HOMEBREW_NO_AUTO_UPDATE=1

. "$HOME/.cargo/env"

# Added by LM Studio CLI (lms)
export PATH="$PATH:$HOME/.lmstudio/bin"
# End of LM Studio CLI section
