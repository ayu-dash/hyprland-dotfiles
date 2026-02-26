export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="duellj"

autoload -Uz compinit && compinit

plugins=(
    git
    zsh-autosuggestions
    zsh-completions 
    zsh-history-substring-search 
    zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# User configuration
export PATH="$HOME/.local/bin:$PATH"

export PATH="/opt/lampp/bin:$PATH"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" #
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" 


#alias
alias ff="fastfetch"
alias ll="ls -la"
alias la="ls -A"
alias l="ls -CF"

# Package management
alias p="sudo pacman"
alias ps="sudo pacman -S"
alias pr="sudo pacman -Rns"
alias pu="sudo pacman -Syu"
alias y="yay"
alias ys="yay -S"
alias yu="yay -Syu"

# Navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias ~="cd ~"

# System
alias s="sudo"
alias cls="clear"
alias reload="source ~/.zshrc"
alias ports="ss -tulanp"

# Git shortcuts
alias gs="git status"
alias ga="git add"
alias gc="git commit -m"
alias gp="git push"
alias gl="git pull"
alias gd="git diff"
alias glog="git log --oneline -10"

# Dev
alias py="python"
alias nrd="npm run dev"
alias prd="pnpm run dev"

# Hyprland
alias hc="cd ~/.config/hypr"
alias hs="cd ~/.config/hypr/Scripts"
