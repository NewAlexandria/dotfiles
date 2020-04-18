#!/usr/bin/sh
#!/bin/sh

echo "___________________________________________________________"
echo "★                         ZSH setup                       *"
echo "‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾"
echo

mkdir ~/.oh-my-zsh/custom/
cp .zsh-oh-my-zsh/* ~/.oh-my-zsh/custom/
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k
