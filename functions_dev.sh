#!/usr/bin/sh

# Common bin paths
# ----------------
echo "🎫  bin PATH config"
#export PATH="$HOME/.sem/bin:$PATH"
#eval "$(rbenv init -)"
#eval "$(nodenv init -)"
#export PATH="$HOME/.rbenv/bin:/usr/local/bin:/usr/local/sbin:/opt/swt/bin:$PATH"
#export PATH=~/.rbenv/shims:$PATH

# repo branches.  should be read from a dotfile per repo
export DEV_BRANCH="development"
export PROD_BRANCH="main"
#
export MAIN_BR=$PROD_BRANCH
# export MAIN_BR=${$(MAIN_BRANCH):-'main'};
export DEVL_BR=$DEV_BRANCH
# export DEVL_BR=${$(DEV_BRANCH):-'development'};
export RELEASE_BR="main-release-2nd-pipe"
# export RELEASE_BR=${$(RELEASE_BRANCH):-'main-release'};
export STAGING_BR="staging"

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

function awsact() {
  aws sts get-caller-identity | jq .Account -r | pbcopy
}

# Compiler things
echo "🎫  Compiler things"
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

#alias findport() {
#$(netstat -vanp tcp | grep $1)
#}

### Artifact Cleanup

alias docker_clean_images='docker rmi $(docker images -a --filter=dangling=true -q)'
alias docker_clean_ps='docker rm $(docker ps --filter=status=exited --filter=status=created -q)'

alias fix-spotlight-npm="find ~/. -type d -path './.*' -prune -o -path './Pictures*' -prune -o -path './Library*' -prune -o -path '*node_modules/*' -prune -o -type d -name 'node_modules' -exec touch '{}/.metadata_never_index' \; -print"

function gem_remove_all() {
  for i in $(gem list --no-versions); do
    gem uninstall -aIx $i
  done
}

### Rails support
echo "🎫  rails Support"

alias be='bundle exec'
alias bert='PARALLEL_WORKERS=1 DISABLE_SPRING=true bundle exec rails test'
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
  FNAME=$(ls | grep $1.*\.tgz | cut -d':' -f 2)
  tar -zxvf $FNAME
  cd ..
}

## Apps
alias bb='bbedit --clean --view-top'
alias jobs='jobs -l'

## Git
echo "🎫  Git"
alias gs='git status'
alias gse="$EDITOR $(git status --porcelain | cut -f2 -s -d 'M' | tr '\n' ' ')"

alias ga='git add'
alias gc='git commit'
alias ggc='lucky commit'
alias gcaa='gc -a --amend'
alias gcaae='gc -a --amend --no-edit'

function gpr() {
  hub pull-request -h $2 -b $1 -m | open
}
function gco() {
  git checkout $(git branch | grep $1 | awk '{ print $2 }' | xargs | awk '{ print $1 }')
}

### git in-flow cleanups
#function gfbr() {
#git co dev; git pull; git co $1; git rebase dev
#}
function gfb() {
  # echo $1
  # echo $2
  # echo 'vars'
  arg_or_var=${2:-$(DEV_BRANCH)}
  input_base_branch=${arg_or_var:-$(parent_branch)}
  echo "input_base_branch: $input_base_branch"
  branch=$1
  exists=$(git branch --list | grep $branch)
  new_branch=''
  if [[ -z "$exists" ]]; then
    new_branch="-b"
  fi
  ref_branch=$2
  [ ! -x $2 ] || ref_branch="$input_base_branch"
  echo "ref_branch: $ref_branch"

  git co $ref_branch
  git pull
  git co $new_branch $branch
  if [[ -z "$exists" ]]; then
    git branch --set-upstream-to=origin/$branch $branch
  fi
  git pull
  git rebase $ref_branch
}

alias gmd="git merge $DEV_BRANCH"

function ghpr() {
  gh pr view --web $1
}
function ghbo() {
  gh repo view --web -b $1
}

function gom() {
  $EDITOR $(gs | grep "both modified" | cut -d' ' -f5 | xargs)
}
# git commit with the last message
function gcam() {
  $(git commit --amend -m "$(exec lcm)")
}

alias gcps='git cherry-pick --skip'
alias gcpc='git cherry-pick --continue'
alias gcpa='git cherry-pick --abort'

# refresh the release branch from main
function gmr() {
  MAIN_BR=$PROD_BRANCH
  # MAIN=${$(MAIN_BRANCH):-'main'};
  DEVL_BR=$DEV_BRANCH
  # DEVL=${$(DEV_BRANCH):-'development'};
  RELEASE_BR="main-release"
  # RELEASE=${$(RELEASE_BRANCH):-'main-release'};
  git co $MAIN_BR
  git pull
  git co $DEVL_BR
  git pull
  git co $RELEASE_BR
  git reset --hard $MAIN_BR
  git merge $DEVL_BR
}

function gmra() {
  gcml
  gcdl
  git co $RELEASE_BR
  git reset --hard $MAIN_BR
}

function gmmd() {
  gcdl
  gcml
  gcd
  git merge main
}

function gcd() {
  git co $DEVL_BR
}
function gcdl() {
  gcd
  git pull
}

function gcst() {
  git co $STAGING_BR
}
function gcstl() {
  gcst
  git pull
}

function gcm() {
  git co $MAIN_BR
}
function gcml() {
  gcm
  git pull
}

function lcm() {
  git log -1 --pretty=%B
}

# https://stackoverflow.com/a/17843908/263858
function parent_branch() {
  git show-branch |
    sed "s/].*//" |
    grep "\*" |
    grep -v "$(git rev-parse --abbrev-ref HEAD)" |
    head -n1 |
    sed "s/^.*\[//"
}

# https://stackoverflow.com/a/69649359/263858
function default_branch() {
  gh repo view --json defaultBranchRef --jq .defaultBranchRef.name
  # git remote show origin | sed -n '/HEAD branch/s/.*: //p'
}

alias gpom='git push origin $PROD_BRANCH --tags'
alias gpod='git push origin $DEV_BRANCH'
alias gpo='git push origin $(git rev-parse --abbrev-ref HEAD) --set-upstream'

alias guo='git pull origin $(git rev-parse --abbrev-ref HEAD) && git fetch &'

alias grd='git rebase $DEV_BRANCH'
alias grr='git rebase $PROD_BRANCH'
alias grm='git rebase $PROD_BRANCH'
alias grc='git rebase --continue'
alias gra='git rebase --abort'
alias grod='git fetch; git rebase origin/$DEV_BRANCH'

alias gspr='git submodule update --init --recursive --remote'
alias gsp='git submodule update --init'

alias gd='git diff --color'
alias gdod='git diff --color origin/$DEV_BRANCH'
alias gdom='git diff --color origin/$PROD_BRANCH'

alias fix='$EDITOR `git diff --name-only | uniq`'

# pipe control via http://unix.stackexchange.com/a/77593/14845
function gdo() {
  ref=$1
  [ ! -x $1 ] || ref='HEAD'
  #editor=$EDITOR
  #[ ! -x $EDITOR ] || editor='vim'
  git diff --name-only $ref | uniq | xargs sh -c 'vim -- "$@" <$0' /dev/tty
  #$EDITOR $( git diff --name-only $ref | uniq | xargs )
}

alias gl='git log --graph --full-history --all --color --pretty=tformat:"%x1b[31m%h%x09%x1b[32m%d%x1b[0m%x20%s%x20%x1b[33m(%an)%x1b[0m"$'
alias gll='git log --graph'
# seach git logs for a string from a diff
alias gls='git log --pickaxe-regex -p --color-words -S '

# alias gcwtc="git commit -m \"`curl http://whatthecommit.com 2>/dev/null | grep '<p>' | sed 's/<p>//'`\""
# alias wtc="echo \"merge-wtc: `curl http://whatthecommit.com 2>/dev/null | grep '<p>' | sed 's/<p>//'`\""

# kill auto rubocop -A
function kautocop() {
  ruby -e 'require "open3"; x,y = Open3.capture2("ps aux | grep rubo"); xx = x.split("\n").select{|l| l.to_s.match(/rubocop \-A/) }.reject{|l| l.to_s.match(/Open3/) }.first; puts "id: #{xx.split}";  system("kill -9 #{xx.split[1]}") if xx.split[1];'
}

## Repos
echo "🎫  Repo helpers"

function update_repos() {
  __batt_yellow=$(tput setaf 184)
  __batt_green=$(tput setaf 120)
  __batt_red=$(tput setaf 160)
  __batt_reset="$(tput init)"
  for f in $(ls -w); do
    echo ""
    echo "$__batt_green$f$__batt_reset"
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
  if [ ! -x $1 ]; then
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
  tmux send-keys -t mbt:0 'teamocil mbt' Enter
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

## Search
echo "🎫  search helpers"

func_arr=('cursor' 'nvim' 'mvim' 'vim')

# takes the files returned by an ag search, and opens them in vim
function agcode() {
  cursor $(ag "$1" $2 -l --nocolor | xargs)
  return 0
  #func_arr=('nvim' 'mvim' 'vim')
  for func in "${$func_arr[@]}"; do
    if [ -n "$(which $func)" ] && [ "$(which $func)" = file ] || 'vim'; then
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
  func_arr=('code')
  for func in "${func_arr[@]}"; do
    if [ -n "$(type -t $func)" ] && [ "$(type -t $func)" = file ]; then
      echo "Using $func"
      mvim $(ack $1 $2 -l --nocolor | xargs)
      break
    fi
  done
}

alias cr='cursor'

function kubesh() {
  kubectl run -i --tty --rm --privileged debug --image=amazonlinux --restart=Never --overrides='{ "apiVersion": "v1", "metadata": {"annotations": { "eks.amazonaws.com/compute-type":"ec2" } } }' -- sh
}

function kubelogs() {
  kubectl logs -f -n tpl-development $(kubectl get pods -n tpl-development | grep $1 | cut -f 1 -d" ")
}

alias kubectl=kubecolor
