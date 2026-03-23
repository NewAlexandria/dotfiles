# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# --- Completion system (standalone, no oh-my-zsh) ---
autoload -Uz compinit && compinit

# History settings
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_DUPS SHARE_HISTORY APPEND_HISTORY

export EDITOR='vim'

# Source function files
source ~/.functions_shell.sh
source ~/.functions_colors.sh
source ~/.functions_dev.sh
source ~/.functions_osx.sh
source ~/.functions_graphics.sh
source ~/.functions_colors_shell.zsh

#. $(brew --prefix asdf)/asdf.sh
. /opt/homebrew/opt/asdf/libexec/asdf.sh

if [[ -e ~/.zshrc_local.sh ]]; then
  source ~/.zshrc_local.sh
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh


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

eval "$(rbenv init - zsh)"

# PROMPT 
eval "$(starship init zsh)"
export STARSHIP_CONFIG=~/example/non/default/path/starship.toml
export STARSHIP_CACHE=~/.starship/cache

# fzf tab completion
source $HOME/.dotfiles/zsh/plugins/fzf-tab/fzf-tab.plugin.zsh
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

export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
export PATH="$HOME/.local/bin:$PATH"


unset -f video2agif 2>/dev/null; export PATH="$HOME/.local/bin:$PATH"


# Added by LM Studio CLI (lms)
export PATH="$PATH:$HOME/.lmstudio/bin"
# End of LM Studio CLI section


# Added by Antigravity
export PATH="$HOME/.antigravity/antigravity/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"


# --- Gas Town Integration (managed by gt) ---
[[ -f "/Users/zak/.config/gastown/shell-hook.sh" ]] && source "/Users/zak/.config/gastown/shell-hook.sh"
# --- End Gas Town ---

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
