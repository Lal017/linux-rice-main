#
# ~/.zshrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'

eval "$(starship init zsh)"

fastfetch --logo-padding 10

# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
bindkey -e
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '/home/lalo/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall

alias ls='ls -A --color=auto'
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh