#!/usr/bin/sh

# Common bin paths
# ----------------
echo "bin PATH config"
#export PATH="$HOME/.sem/bin:$PATH"
#eval "$(rbenv init -)"
#eval "$(nodenv init -)"
#export PATH="$HOME/.rbenv/bin:/usr/local/bin:/usr/local/sbin:/opt/swt/bin:$PATH"
#export PATH=~/.rbenv/shims:$PATH

# AWS autocomplete not working, from the source, rn
#complete -C aws_completer aws
#complete -W "$(echo `cat ~/.ssh/known_hosts | cut -f 1 -d ' ' | sed -e s/,.*//g | uniq | grep -v "\["`;)" ssh

function awss3newest() {
  [ -z "$1" ] && echo "Must provide bucket name" && exit 1
  [ -z "$2" ] && echo "Must provide path" && exit 1
  aws s3api list-objects-v2i \
    --bucket $1 \
    --prefix $2 \
    --query 'reverse(sort_by(Contents,&LastModified))[0]'
}


# Compiler things
echo "Compiler things"
alias gcc=cc
alias gcc-4.2=gcc
export CC=gcc

#export PATH="/usr/local/opt/node@8/bin:$PATH"
export NODE_PATH="/usr/local/lib/jsctags:${NODE_PATH}"
export NODE_PATH=/usr/local/lib/jsctags/:$NODE_PATH
export PATH="$PATH:/usr/local/opt/go/libexec/bin:"
export PATH="/usr/local/opt/libxml2/bin:$PATH"

export LDFLAGS="-L/usr/local/opt/libxml2/lib"
export CPPFLAGS="-I/usr/local/opt/libxml2/include"
export PKG_CONFIG_PATH="/usr/local/opt/libxml2/lib/pkgconfig"

# for pyenv install, on osx 10.14
export LDFLAGS="-L/usr/local/opt/openssl/lib"
export CPPFLAGS="-I/usr/local/opt/openssl/include"



## Aliases
alias exportenv='export $(cat .env | grep -v ^# | cut -d: -f2 | xargs)'
alias a="arch -x86_64"
alias ibrew="arch -x86_64 brew"


### Artifact Cleanup

alias docker_clean_images='docker rmi $(docker images -a --filter=dangling=true -q)'
alias docker_clean_ps='docker rm $(docker ps --filter=status=exited --filter=status=created -q)'

alias fix-spotlight-npm="find ~/. -type d -path './.*' -prune -o -path './Pictures*' -prune -o -path './Library*' -prune -o -path '*node_modules/*' -prune -o -type d -name 'node_modules' -exec touch '{}/.metadata_never_index' \; -print"

function gem_remove_all() {
  for i in `gem list --no-versions`
  do
    gem uninstall -aIx $i
  done
}

### Rails support
alias be='bundle exec'
alias bes='RAILS_ENV=test bundle exec rspec -f d -c'
alias bec='bundle exec cucumber'
alias berdbm='echo "=============="; echo "= running DEVELOPMENT env migrations"; echo "=============="; bundle exec rake db:migrate; echo "=============="; echo "= running Test env. migrations"; echo "=============="; RAILS_ENV=test dotenv -f .env bundle exec rake db:migrate'
#alias rspec='wtitle "rspec"; rspec'
alias rspec='rspec -f d -c'

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


## Git
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

DEV_BRANCH='dev'

alias gpom='git push origin master --tags'
alias gpod='git push origin $DEV_BRANCH'
alias  gpo='git push origin $(git rev-parse --abbrev-ref HEAD) --set-upstream'

alias  guo='git pull origin $(git rev-parse --abbrev-ref HEAD) && git fetch &'

alias  grd='git rebase $DEV_BRANCH'
alias  grm='git rebase master'
alias  grc='git rebase --continue'
alias  gra='git rebase --abort'
alias grod='git fetch; git rebase origin/$DEV_BRANCH'

alias gspr='git submodule update --init --recursive --remote'
alias  gsp='git submodule update --init'

alias   gd='git diff --color'
alias gdod='git diff --color origin/$DEV_BRANCH'
alias gdom='git diff --color origin/master'

alias  fix='$EDITOR `git diff --name-only | uniq`'

# pipe control via http://unix.stackexchange.com/a/77593/14845
function gdo() {
  ref=$1
  [ ! -x $1 ] || ref='HEAD'
  #editor=$EDITOR
  #[ ! -x $EDITOR ] || editor='vim'
  git diff --name-only $ref | uniq | xargs sh -c 'vim -- "$@" <$0' /dev/tty
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

function clone_org() {
  org=$1
  token_file=$2
  if [ ! -x $1 ] ; then
    echo "first var, organization token, is required"
  else
    [ ! -x $2 ] || token_file="~/.ssh/keys/github-pers-token-all-repos.txt"
    curl -s https://$token_file:@api.github.com/orgs/$org/repos\?per_page\=200 | jq ".[].ssh_url" | xargs -n 1 git clone --recursive
  fi
}


### tmux support

function tmux_layout_code() {
  tmux list-windows -F "#{window_active} #{window_layout}" | grep "^1" | cut -d " " -f 2
}

function mux() {
  tmux new-session -d -s mbt
  tmux send-keys   -t    mbt:0 'teamocil mbt' Enter
}


## Examples

#  If you have two CSV's that each have a column with the same data, and you'd like to join them, use join. For example:
#  join \
#    -t, \
#    -1 2 \
#    -2 1 \
#    -o 0,1.1,1.3,2.2,2.3 \
#    <(sort -k2 -t, leads.csv) \
#    <(sort -t, names.csv)
#  
#  In this example, leads.csv has lead UUID in the second column and names.csv has lead UUID in the first column. Input files must be sorted on the join column, and the output is the lead UUID, following by the first attribute in the first file, etc (as specified by -o)

function _perimiter_array() {
  ruby -e "div=((ARGV[0]||6)-1); min=0.0;max=1.0; x=Array.new(div,(max/div)).map.with_index{|i,idx| (i*(idx+1)).floor(2) }.unshift(0.0); y=x.zip(Array.new(div+1,min)) + x.zip(Array.new(div+1,max)) + Array.new(div+1,max).zip(x) + Array.new(div+1,min).zip(x); puts y.uniq.to_s.gsub(' ','')"
}

# takes the files returned by an ag search, and opens them in vim
function agcode() {
  code $(ag "$1" $2 -l --nocolor | xargs)
  return 0
  func_arr=( 'nvim' 'mvim' 'vim' )
  for func in "${func_arr[@]}"
  do
    if [ -n "$(which $func)" ] && [ "$(which $func)" = file ] || 'vim'
    then 
      echo "Using $func"
      $func $(ag "$1" $2 -l --nocolor | xargs)
      break
    fi
  done
}

# takes the files returned by an ack search, and opens them in vim
function ackcode() {
  code $(ack "$1" $2 -l --nocolor | xargs)
  return 0
  func_arr=( 'code' )
  for func in "${func_arr[@]}"
  do
    if [ -n "$(type -t $func)" ] && [ "$(type -t $func)" = file ]
    then 
      echo "Using $func"
      mvim $(ack $1 $2 -l --nocolor | xargs)
      break
    fi
  done
}

function kubesh() {
  kubectl run -i --tty --rm --privileged debug --image=amazonlinux --restart=Never --overrides='{ "apiVersion": "v1", "metadata": {"annotations": { "eks.amazonaws.com/compute-type":"ec2" } } }' -- sh
}

function kubelogs() {
  kubectl logs -f -n tpl-development  $(kubectl get pods -n tpl-development | grep $1 | cut -f 1 -d" ")
}

