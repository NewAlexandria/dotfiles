#!/usr/bin/sh
#!/bin/sh

echo "___________________________________________________________"
echo "★ Customizing, Configuring & Setting Up a Mac OS X System ★"
echo "‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾"
echo

echo "  → Clean up Apple Ruby..."
sudo rm -rf /System/Library/Frameworks/Ruby.framework/Versions/1.8/usr/lib/ruby/gems/1.8
sudo gem update --system
sudo gem clean

echo "  → Installing Homebrew..."
sudo mkdir -p /usr/local
sudo mkdir -p /usr/local/bin
sudo chown -R $USER /usr/local
cd $HOME && mkdir -p homebrew
curl -# -L -k https://github.com/mxcl/homebrew/tarball/master | tar xz --strip 1 -C homebrew
ln -nfs $HOME/homebrew/bin/brew /usr/local/bin/
brew update
brew install bash-completion

echo "✓ Homebrew installed"

echo "  → Installing Git..."
brew install git
brew install diff-so-fancy
brew install git-flow
brew install git-extras
brew install bash-git-prompt

echo "✓ Git installed"

echo "  → Hooking up Homebrew to your fork..."
rm -rf /tmp/myhomebrew
git clone git@github.com:$USER/homebrew.git /tmp/myhomebrew
git --git-dir=/tmp/myhomebrew/.git remote rename origin $USER
git --git-dir=/tmp/myhomebrew/.git remote add upstream git://github.com/mxcl/homebrew.git
cp -r /tmp/myhomebrew/.git $HOME/homebrew/.git
rm -rf /tmp/myhomebrew

echo "✓ Homebrew origin pointed to http://github.com:$USER/homebrew"

echo "  → Installing essential language VMs..."

brew install asdf
echo -e "\n. $(brew --prefix asdf)/asdf.sh" >> ~/.zshrc
asdf plugin add ruby
asdf plugin add python
asdf plugin add nodejs
asdf plugin add kubectl
asdf plugin add helm
asdf plugin add elixir
exec $SHELL

echo "✓ asdf installed"

echo "  → Installing Langs"
asdf install ruby 2.7.0
asdf isngtall python 2.7.0
asdf isngtall python 3.8.0
asdf install nodejs 13.12.0
asdf install nodejs 10.18.0
asdf rehash

asdf global ruby 2.7.0
asdf global python 3.8.0
asdf global nodejs 13.12.0

echo "✓ Installed Ruby: $(rbenv global)"

echo "  → Installing essential Rubygems..."
gem install rake bundler factory_girl fakeweb iconv nokogiri paperclip rails rack-cache rack-contrib rack-test rcov rdiscount rdoc redis redis-namespace resque shoulda sinatra sqlite3-ruby thin turn will_paginate wirble yajl-ruby yard amqp clearance rest-client curb
rbenv rehash

echo "✓ Rubygems installed"


echo "  → Installing utilities..."
brew bundle

sudo easy_install pip
pip install Pygments

echo "✓ Utilities installed"

echo "  → Installing launchctl (cron) jobs"
launchctl load  ~/.dotfiles/mac/launchctl/local.brew.plist
launchctl start ~/.dotfiles/mac/launchctl/local.brew.plist
echo "✓ Launchers installed"

