#. /usr/local/opt/asdf/asdf.sh

#fpath=(/usr/local/share/zsh-completions $fpath)

export TERM="xterm-256color"


# History settings
# ----------------
export HISTCONTROL=erasedups
export HISTSIZE=10000
PROMPT_COMMAND="history -a;$PROMPT_COMMAND"

# Services
# --------
unset MAILCHECK

# Building
# --------
GPG_TTY=$(tty)
export GPG_TTY

#source ~/.zsh/prompt.zsh


# use .profile.local for setting machine-specific options
[[ -f ~/.zprofile.local.zsh ]] && .  ~/.zprofile.local.zsh
