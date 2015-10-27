# Completions
if [ -f $(brew --prefix)/etc/bash_completion ]; then
  . $(brew --prefix)/etc/bash_completion
fi

complete -C aws_completer aws

function _ssh_completion() {
  perl -ne 'print "$1 " if /^Host (.+)$/' ~/.ssh/config
}
complete -W "$(_ssh_completion)" ssh
complete -W "$(_ssh_completion)" scp



# Aliases
## FileSystem
alias ll='ls -alGh'
alias les='less -FRSXQ'

alias cdd='cd ~/.ssh/'

alias ag='ag --color  --color-path=37  --color-line-number=32'
alias dif='colordiff'
alias grep='GREP_OPTIONS="--color=auto --line-number --context=0 --exclude=*.log" GREP_COLOR="1;37;41" LANG=C grep'
alias ack='ack --color-lineno=green --color-filename=white --color --follow'

 # parallel bash commands
 # http://www.rankfocus.com/use-cpu-cores-linux-commands/

function pgrep() {
  cat $1 | parallel --block 10M --pipe grep $2
}


