fastfetch
export ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
source "${ZINIT_HOME}/zinit.zsh"
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-syntax-highlighting
eval "$(starship init zsh)"
setopt autocd
setopt correct
setopt interactive_comments
setopt hist_ignore_all_dups
setopt share_history
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
alias ll='ls -lA'
alias gs='git status'
export TERM="xterm-256color"
bindkey '^[[C' forward-char
bindkey '^[[C' autosuggest-accept
