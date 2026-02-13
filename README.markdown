Dotfiles
========

Installation process based on [karmi](http://github.com/karmi/dotfiles/) [Ryan Bates Dot Files](http://github.com/ryanb/dotfiles/).

Installation
------------

With Git:

    git clone git://github.com/newalexandria/dotfiles ~/dotfiles
    cd ~/dotfiles
    rake install

Without Git:

    cd $HOME
    mkdir -p dotfiles
    curl -# -L -k https://github.com/newalexandria/dotfiles/tarball/master | tar xz --strip 1 -C dotfiles
    cd dotfiles
    rake install

Homebrew tools
------------

The dotfiles use `brew-new-formulae` for discovering new formulae and first installs. Install via:

    brew tap newalexandria/brew-new-formula
    brew install newalexandria/brew-new-formula/brew-new-formulae

Then run `brew new-formulae 0 30` or `brew first-installs 0 30`. See the [Brewfile](Brewfile) for the tap/formula entries.

Blog
------------

[Technical blogging, ampersand](http://newalexandria.github.io/dotfiles/), will begin here.

Futures
------------

* [zsh antidote plugin manager](https://getantidote.github.io)
