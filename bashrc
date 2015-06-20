
if [ -f $(brew --prefix)/etc/bash_completion ]; then
  . $(brew --prefix)/etc/bash_completion
fi

# Aliases
## FileSystem
alias ll='ls -alGh'
alias les='less -FRSXQ'
alias be='bundle exec'
alias ag='ag --color  --color-path=37  --color-line-number=32'
#alias rspec='wtitle "rspec"; rspec'
alias rspec='rspec -f d -c'
alias bes='bundle exec rspec -f d -c'
alias dif='colordiff'
alias grep='GREP_OPTIONS="--color=auto --line-number --context=0 --exclude=*.log" GREP_COLOR="1;37;41" LANG=C grep'
alias ack='ack --color-lineno=green --color-filename=white --color --follow'

## Apps
alias bb='bbedit --clean --view-top'

alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gd='git diff'
alias gl='git log'

alias  gl='git log --graph --full-history --all --color --pretty=tformat:"%x1b[31m%h%x09%x1b[32m%d%x1b[0m%x20%s%x20%x1b[33m(%an)%x1b[0m"$'
alias gll='git log --graph'

alias  gd='git diff --color'
alias gdf='git diff dev --name-only'
alias gde="vim $(git diff --name-status --diff-filter=U | cut -f2 | tr '\n' ' ')"
alias gse="vim $(git status --porcelain | cut -f2 -s -d 'M' | tr '\n' ' ' )"

alias gcwtc="git commit -m \"`curl http://whatthecommit.com 2>/dev/null | grep '<p>' | sed 's/<p>//'`\""
alias wtc="echo \"merge-wtc: `curl http://whatthecommit.com 2>/dev/null | grep '<p>' | sed 's/<p>//'`\""

export UNITS="$(brew --cellar gnu-units)/$(gunits -V | head -n 1 | awk '{ print $4 }')/share/units/definitions.units'
# /usr/share/misc/units.lib
