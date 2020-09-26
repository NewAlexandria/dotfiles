#!/usr/bin/sh
#!/bin/sh

echo "___________________________________________________________"
echo "★                         ZSH setup                       *"
echo "‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾"
echo

sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

mkdir -p ~/.oh-my-zsh/custom/
cp .zsh-oh-my-zsh/* ~/.oh-my-zsh/custom/
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k

mv ~/.oh-my-zsh/default.zsh  ~/.oh-my-zsh/default.old.zsh 
ln -s ~/.dotfiles/.zsh-oh-my-zsh/default.zsh ~/.oh-my-zsh/default.zsh 
mv ~/.oh-my-zsh/functions.zsh  ~/.oh-my-zsh/functions.old.zsh 
ln -s ~/.dotfiles/.zsh-oh-my-zsh/functions.zsh ~/.oh-my-zsh/functions.zsh 

