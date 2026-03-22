#!/usr/bin/sh
# Completions
if [ -f $(brew --prefix)/etc/bash_completion ]; then
  source $(brew --prefix)/etc/bash_completion
fi
source ~/.dotfiles/lib/git-completion.sh

complete -C aws_completer aws
complete -W "$(echo `cat ~/.ssh/known_hosts | cut -f 1 -d ' ' | \
    sed -e s/,.*//g | uniq | grep -v "\["`;)" ssh

#complete -W "$(echo `cat ~/.ssh/known_hosts | cut -f 1 -d ' ' | sed -e s/,.*//g | uniq | grep -v "\["`;)" ssh
#complete -W "$(echo `cat ~/.ssh/known_hosts | cut -f 1 -d ' ' | sed -e s/,.*//g | uniq | grep -v "\["`;)" scp

#complete -C /usr/local/bin/vault vault


# Compiler things
alias gcc=cc
alias gcc-4.2=gcc

export PATH="/usr/local/opt/node@8/bin:$PATH"
export NODE_PATH="/usr/local/lib/jsctags:${NODE_PATH}"
export NODE_PATH=/usr/local/lib/jsctags/:$NODE_PATH
export PATH="$PATH:/usr/local/opt/go/libexec/bin:"
export PATH="/usr/local/opt/libxml2/bin:$PATH"
export PATH="/Applications/HDF_Group/HDF5/1.14.6/bin/:$PATH"

export LDFLAGS="-L/usr/local/opt/libxml2/lib"
export CPPFLAGS="-I/usr/local/opt/libxml2/include"
export PKG_CONFIG_PATH="/usr/local/opt/libxml2/lib/pkgconfig"

# Correct a previous bash CLI typo
# aliased like a Fika, a small party between me and the tools
#eval "$(thefuck --alias fk)"

man() {
	env \
		LESS_TERMCAP_mb=$(printf "\e[1;31m") \
		LESS_TERMCAP_md=$(printf "\e[1;31m") \
		LESS_TERMCAP_me=$(printf "\e[0m") \
		LESS_TERMCAP_se=$(printf "\e[0m") \
		LESS_TERMCAP_so=$(printf "\e[1;44;33m") \
		LESS_TERMCAP_ue=$(printf "\e[0m") \
		LESS_TERMCAP_us=$(printf "\e[1;32m") \
			man "$@"
}

alias ll='ls -al'
alias ll='eza -al'
alias l='eza '

alias unmute='osascript -e "set volume output muted false" && osascript -e "set volume output volume 75"'
function aftestbf() {
       	cd ~/src/marine-acoustics
	afplay apps/sd-modem/fsk/output_fsk/jan31/test97_2300hz_2-fsk_50baud.wav -v 20 -q 1 -d -t 6 
}

alias ic="ibmcloud"
. "$HOME/.cargo/env"
export PATH="$HOME/.local/bin:$PATH"

export PATH=~/.npm-global/bin:$PATH

function reset_ard() {
  sudo killall screensharingd
  sudo killall loginwindow
}

[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path bash)"
