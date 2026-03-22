Dotfiles
========

⚙️  Recently updated for Agent prompting

Installation process based on [karmi](http://github.com/karmi/dotfiles/) [Ryan Bates Dot Files](http://github.com/ryanb/dotfiles/).

Installation
------------

With Git:

    git clone git://github.com/newalexandria/dotfiles ~/.dotfiles
    cd ~/.dotfiles
    rake install

Without Git:

    cd $HOME
    mkdir -p .dotfiles
    curl -# -L -k https://github.com/newalexandria/dotfiles/tarball/master | tar xz --strip 1 -C .dotfiles
    cd .dotfiles
    rake install

Futures
------------

I think it's a lot of value to improving the way that this repository could boot strap environments through agents. There's a lot of assumptions about common working environment and it really could use a bit more of a contemporary bootloader idea.
