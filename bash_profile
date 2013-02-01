# ======================================
# Bash profile, reload with `. .profile`
# ======================================

# Completions
source ~/.git-completion.bash

if [ -f `brew --prefix`/etc/bash_completion ]; then
  . `brew --prefix`/etc/bash_completion
fi

function _ssh_completion() {
perl -ne 'print "$1 " if /^Host (.+)$/' ~/.ssh/config
}
complete -W "$(_ssh_completion)" ssh
complete -W "$(_ssh_completion)" scp


# Functions
function wtitle() { echo -ne "\033]0;$1\007"; }

# prompt
export PS1='#:\w\[\033[32m\]$(__git_ps1) \[\033[0m\]$ '

# export PATH="$PATH:/Users/ZacharyStarkJones/.rvm/bin"
export PATH="$HOME/.rbenv/bin:/usr/local/bin:/usr/local/sbin:$PATH"
export CC=gcc-4.2
# export DYLD_LIBRARY_PATH=/usr/local/Cellar/mysql/5.5.15/lib:$DYLD_LIBRARY_PATH

# Package Managers
# [[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm" # Load RVM function
eval "$(rbenv init -)"  # config for rbenv

# Aliases
## FileSystem
alias ll='ls -alGh'
alias les='less -FRSXQ'
alias be='bundle exec'
alias angsave="cd /usr/local/Cellar/angband/3.0.9b/libexec/save/"
alias cdcr='cd ~/Sites/utils/gems/crossing_guard'
alias cdv='cd ~/.vim.ana/'

alias cdw='cd ~/Sites/waywire/; wtitle waywire'
alias cdd='cd ~/Sites/waywire_deploy/; wtitle waywire_deploy'
alias cdws='cd ~/Sites/waywire/; wtitle "server: waywire"; be rails s -p 3000'
alias cdwc='cd ~/Sites/waywire/; wtitle "irb: waywire"; be rails c'
alias rspec='wtitle "rspec: waywire"; rspec'

## Apps
alias bb='bbedit --clean --view-top'
alias rspec='rspec -f d -c'
alias ack='ack --color-lineno=green --color-filename=white --color --follow'
alias dif='colordiff'

export LESS='-R'
export LESSOPEN='| ~/.lessfilter.sh %s'
export LESSCOLORIZER=pygmentize

## Git
alias  gc='git commit'
alias gco='git co'
alias gci='git ci'
alias grb='git rb'
alias  ga='git add'
alias  gs='git status'
alias git='hub'

alias  gl='git log --graph --full-history --all --color --pretty=tformat:"%x1b[31m%h%x09%x1b[32m%d%x1b[0m%x20%s%x20%x1b[33m(%an)%x1b[0m"$'
alias gll='git log --graph'

alias  gd='git diff --color'
alias gdf='git diff dev --name-only'
alias gde="vim $(git diff --name-status --diff-filter=U | cut -f2 | tr '\n' ' ')"
alias gse="vim $(git status --porcelain | cut -f2 -s -d 'M' | tr '\n' ' ' )"

alias gcwtc="git commit -m \"`curl http://whatthecommit.com 2>/dev/null | grep '<p>' | sed 's/<p>//'`\""
alias wtc="echo \"merge-wtc: `curl http://whatthecommit.com 2>/dev/null | grep '<p>' | sed 's/<p>//'`\""

GIT_EDITOR="vim -u NONE"; export GIT_EDITOR

# Waywire Env
source ~/Sites/waywire_deploy/.bash_ww
