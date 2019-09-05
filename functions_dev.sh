#!/usr/bin/sh

# Common bin paths
# ----------------
echo "bin PATH config"
export PATH="$HOME/.sem/bin:$PATH"
eval "$(rbenv init -)"
export PATH="$HOME/.rbenv/bin:/usr/local/bin:/usr/local/sbin:/opt/swt/bin:$PATH"
export PATH=~/.rbenv/shims:$PATH

# AWS autocomplete not working, from the source, rn
#complete -C aws_completer aws
#complete -W "$(echo `cat ~/.ssh/known_hosts | cut -f 1 -d ' ' | sed -e s/,.*//g | uniq | grep -v "\["`;)" ssh


# Compiler things
echo "Compiler things"
alias gcc=cc
alias gcc-4.2=gcc
export CC=gcc-4.2

export PATH="/usr/local/opt/node@8/bin:$PATH"
export NODE_PATH="/usr/local/lib/jsctags:${NODE_PATH}"
export NODE_PATH=/usr/local/lib/jsctags/:$NODE_PATH
export PATH="$PATH:/usr/local/opt/go/libexec/bin:"
export PATH="/usr/local/opt/libxml2/bin:$PATH"

export LDFLAGS="-L/usr/local/opt/libxml2/lib"
export CPPFLAGS="-I/usr/local/opt/libxml2/include"
export PKG_CONFIG_PATH="/usr/local/opt/libxml2/lib/pkgconfig"


## Aliases
alias exportenv='export $(cat .env | grep -v ^# | cut -d: -f2 | xargs)'

alias be='bundle exec'
alias bes='RAILS_ENV=test bundle exec rspec -f d -c'
alias bec='bundle exec cucumber'
alias berdbm='echo "=============="; echo "= running DEVELOPMENT env migrations"; echo "=============="; bundle exec rake db:migrate; echo "=============="; echo "= running Test env. migrations"; echo "=============="; RAILS_ENV=test bundle exec rake db:migrate'
#alias rspec='wtitle "rspec"; rspec'
alias rspec='rspec -f d -c'

function gem_remove_all() {
  for i in `gem list --no-versions`
  do
    gem uninstall -aIx $i
  done
}

function gempath() {
  rbenv exec gem environment | grep INSTALLATION | cut -d : -f 3 | xargs
}

function npmget() {
  mkdir $1
  cd $1
  wget $(npm v $1 dist.tarball)
  FNAME=$(ls  | grep $1.*\.tgz | cut -d':' -f 2)
  tar -zxvf $FNAME
  cd ..
}

## Apps
alias bb='bbedit --clean --view-top'
alias jobs='jobs -l'

alias gs='git status'
alias gse="$EDITOR $(git status --porcelain | cut -f2 -s -d 'M' | tr '\n' ' ' )"

alias ga='git add'
alias gc='git commit'
function gpr() {
  hub pull-request -h $2 -b $1 -m | open
}
function gco() {
  git checkout $( git branch | grep $1 | awk '{ print $2 }' | xargs | awk '{ print $1 }' )
}
function gom() {
  $EDITOR $(gs | grep "both modified" | cut -d' ' -f5 | xargs)
}

alias gpom='git push origin master --tags'
alias gpod='git push origin develop'
alias  gpo='git push origin $(git rev-parse --abbrev-ref HEAD) --set-upstream'

alias  guo='git pull origin $(git rev-parse --abbrev-ref HEAD) && git fetch &'

alias  grd='git rebase develop'
alias  grm='git rebase master'
alias  grc='git rebase --continue'
alias  gra='git rebase --abort'
alias grod='git fetch; git rebase origin/develop'

alias   gd='git diff --color'
alias gdod='git diff --color origin/develop'
alias gdom='git diff --color origin/master'

alias  fix='$EDITOR `git diff --name-only | uniq`'

# pipe control via http://unix.stackexchange.com/a/77593/14845
function gdo() {
  ref=$1
  [ ! -x $1 ] || ref='HEAD'
  git diff --name-only $ref | uniq | xargs sh -c '$EDITOR -- "$@" <$0' /dev/tty
  #$EDITOR $( git diff --name-only $ref | uniq | xargs )
}

alias  gl='git log --graph --full-history --all --color --pretty=tformat:"%x1b[31m%h%x09%x1b[32m%d%x1b[0m%x20%s%x20%x1b[33m(%an)%x1b[0m"$'
alias gll='git log --graph'


# alias gcwtc="git commit -m \"`curl http://whatthecommit.com 2>/dev/null | grep '<p>' | sed 's/<p>//'`\""
# alias wtc="echo \"merge-wtc: `curl http://whatthecommit.com 2>/dev/null | grep '<p>' | sed 's/<p>//'`\""

function update_repos() {
  __batt_yellow=$(tput setaf 184)
  __batt_green=$( tput setaf 120)
  __batt_red=$(   tput setaf 160)
  __batt_reset="$(tput init)"
  for f in $(ls -w)
  do 
    echo "";
    echo "$__batt_green$f$__batt_reset";
    cd ${f}
    git stash save "xxx"
    git pull
    git stash pop $(git log -g stash --grep="xxx" --pretty=format:"%gd")
    cd ..
  done
}

function release_complete() {
  now=$(date "+%Y%m%d")
  if [ $# -eq 0 ]; then
    echo "No tag value provided"
    exit 1
  else
    git co master
    git pull origin master
    git merge origin release/$now.1
    git tag $1
    git push origin master --tags
    git co develop
    git pull origin develop
    git merge -m 'merge release master into develop' master
    git push origin develop
  fi
}

function release_start() {
  now=$(date "+%Y%m%d")
  git co develop
  git pull
  git co -b release/$now.1
  git push origin release/$now.1
}

export JIRA_PROJECT_PREFIX='BT'
function hubpr() {
  TARGET=$1
  [ ! -z $1 ] || TARGET='develop'

  echo $(git branch |
    grep '*' |
    cut -d' ' -f2 |
    ruby -e 'jira_regex = Regexp.new(ENV["JIRA_PROJECT_PREFIX"]+"-[0-9]+"); \
      b=gets; j=(b.match(jira_regex) || [])[0].to_s; \
      title=((j.empty?) ? b : (b.split(j) - [j] - [""]).compact.first).strip.tr("/\()-_"," "); \
      title+=" : #{j}" if !j.empty?; \
      `echo "#{title}" > /tmp/prfile`; \
      (`echo "#### [#{j}](https://adsixty.atlassian.net/browse/#{j})" >> /tmp/prfile`) if !j.empty? \
      ')
  cat PR_TEMPLATE.md >> /tmp/prfile
  URL=$(hub pull-request -b $TARGET -F /tmp/prfile)
  echo "New PR created at $URL"
  open $URL
}

function tmux_layout_code() {
  tmux list-windows -F "#{window_active} #{window_layout}" | grep "^1" | cut -d " " -f 2
}

function mux() {
  tmux new-session -d -s mbt
  tmux send-keys   -t    mbt:0 'teamocil mbt' Enter
}

