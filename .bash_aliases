# ~/.bash_aliases

# --- Navigation ---
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias c='clear'
alias j='jump' # Your custom jump function is in .bashrc

# --- Enhanced Core Commands ---
alias ls='eza'
alias ll='eza -alF --git --icons'
alias la='eza -A'
alias l='eza -CF'
alias tree='eza --tree'
alias cat='bat --paging=never'
alias bat='batcat' # For systems where bat is installed as batcat

# Make common commands interactive to prevent mistakes
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# --- Search ---
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# --- System Info & Management ---
alias free='free -h'
alias du='du -h'
alias df='df -h'
alias top='top -d 1'
alias update='sudo apt update && sudo apt upgrade -y'
alias cleanup='sudo apt autoremove -y && sudo apt clean'

# --- Networking ---
alias ping='ping -c 5'
alias myip='curl ifconfig.me'
alias localip="ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -n 1"

# --- Git ---
alias gs='git status -sb'
alias ga='git add .'
alias gc='git commit -m'
alias gp='git push'
alias gl='git log --oneline --decorate --all --graph'
alias gco='git checkout'
alias gb='git branch'

# --- Miscellaneous ---
alias bk='backup' # Your custom backup function is in .bashrc
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'
