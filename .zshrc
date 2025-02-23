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

#alias
alias ff="fastfetch"