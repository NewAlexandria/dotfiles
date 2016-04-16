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

Blog
------------

[Technical blogging, ampersand](http://newalexandria.github.io/dotfiles/), will begin here.
