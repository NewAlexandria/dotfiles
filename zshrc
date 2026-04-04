# --- Completion system (standalone, no oh-my-zsh) ---
autoload -Uz compinit && compinit

# History settings
HISTSIZE=10000
SAVEHIST=10000
HISTFILE="$HOME/.zsh_history"
setopt HIST_IGNORE_DUPS SHARE_HISTORY APPEND_HISTORY

export EDITOR='vim'

# Dotfiles repo and Homebrew prefix
DOTFILES_REPO="$HOME/.dotfiles"
if command -v brew &>/dev/null; then
  BREW_PREFIX="$(brew --prefix)"
fi

# Source function files
source "$DOTFILES_REPO/functions_shell.sh"
source "$DOTFILES_REPO/functions_colors.sh"
source "$DOTFILES_REPO/functions_dev.sh"
source "$DOTFILES_REPO/functions_osx.sh"
source "$DOTFILES_REPO/functions_graphics.sh"
source "$DOTFILES_REPO/functions_colors_shell.zsh"
source "$DOTFILES_REPO/prompt.sh"


if [[ -e "$HOME/.zshrc_local.sh" ]]; then
  source "$HOME/.zshrc_local.sh"
fi


#. $(brew --prefix asdf)/asdf.sh
. "$BREW_PREFIX/opt/asdf/libexec/asdf.sh"

eval "$(rbenv init - zsh)"


# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
#__conda_setup="$('/opt/homebrew/Caskroom/miniconda/base/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
#if [ $? -eq 0 ]; then
    #eval "$__conda_setup"
#else
    #if [ -f "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh" ]; then
        #. "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh"
    #else
        #export PATH="/opt/homebrew/Caskroom/miniconda/base/bin:$PATH"
    #fi
#fi
#unset __conda_setup
# <<< conda initialize <<<

export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

# get zsh complete kubectl
#source <(kubectl completion zsh)
#alias kubectl=kubecolor
# make completion work with kubecolor
#compdef kubecolor=kubectl

# fzf tab completion
source "$DOTFILES_REPO/zsh/plugins/fzf-tab/fzf-tab.plugin.zsh"
source <(fzf --zsh)

# Configure fzf-tab to show directories first
zstyle ':fzf-tab:complete:*:*' fzf-preview 'ls -la $realpath'
zstyle ':fzf-tab:complete:*' fzf-flags --height=50% --reverse
# Sort directories first in file completion
zstyle ':completion:*' file-sort modification
zstyle ':completion:*:*:*:*:descriptions' format '%F{green}-- %d --%f'
zstyle ':completion:*' group-name ''
zstyle ':completion:*:*:-command-:*:*' group-order alias builtins functions commands
# Directories first, then files
zstyle ':completion:*' list-dirs-first true

export PATH="$BREW_PREFIX/opt/openjdk/bin:$PATH"

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
export PATH="$HOME/.local/bin:$PATH"


unset -f video2agif 2>/dev/null; export PATH="$HOME/.local/bin:$PATH"



# === Word Navigation — stop at . / - and spaces ===
WORDCHARS='*?_[]~=&;!#$%^(){}<>'
bindkey '\e[1;3D' backward-word
bindkey '\e[1;3C' forward-word
bindkey '\eb' backward-word
bindkey '\ef' forward-word
bindkey '\e[1;9D' backward-word
bindkey '\e[1;9C' forward-word
bindkey '\e[1;5D' backward-word
bindkey '\e[1;5C' forward-word

# === Forward Delete (fn+backspace) ===
bindkey '\e[3~' delete-char
