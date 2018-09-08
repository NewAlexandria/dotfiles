#!/usr/bin/sh
# Completions
if [ -f $(brew --prefix)/etc/bash_completion ]; then
  . $(brew --prefix)/etc/bash_completion
fi

complete -C aws_completer aws
complete -W "$(echo `cat ~/.ssh/known_hosts | cut -f 1 -d ' ' | \
    sed -e s/,.*//g | uniq | grep -v "\["`;)" ssh

#complete -W "$(echo `cat ~/.ssh/known_hosts | cut -f 1 -d ' ' | sed -e s/,.*//g | uniq | grep -v "\["`;)" ssh
#complete -W "$(echo `cat ~/.ssh/known_hosts | cut -f 1 -d ' ' | sed -e s/,.*//g | uniq | grep -v "\["`;)" scp


# Aliases
## FileSystem
alias ll='ls -alGh'
alias les='less -FRSXQ'

alias cdd='cd ~/.ssh/'
alias cddot='cd ~/.dotfiles/'

alias ag='ag --color  --color-path=37  --color-line-number=32'
alias dif='colordiff'
alias ack='ack --color-lineno=green --color-filename=white --color --follow'


alias grep='GREP_OPTIONS="--color=auto --line-number --context=0 --exclude=*.log" GREP_COLOR="1;37;41" LANG=C grep'
 # parallel bash commands
 # http://www.rankfocus.com/use-cpu-cores-linux-commands/
function pgrep() {
  cat $1 | parallel --block 10M --pipe grep $2
}

# Correct a previous bash CLI typo
# aliased like a Fika, a small party between me and the tools
eval "$(thefuck --alias fk)"

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

#!/bin/bash
# requires that iTerm have accessibility permissions
if [ $TERM_PROGRAM = "iTerm.app" ]; then
  osascript -e 'tell application "System Events" to keystroke "e" using {command down, shift down}'
fi

complete -C /usr/local/bin/vault vault
