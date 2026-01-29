# ~/.bashrc: executed by bash(1) for non-login shells.

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# --- Core Shell Options & History ---

# Don't put duplicate lines or lines starting with space in the history.
# Erase duplicates throughout the history file.
export HISTCONTROL=ignoreboth:erasedups

# For setting history length
export HISTSIZE=10000
export HISTFILESIZE=20000

# Append to the history file, don't overwrite it
shopt -s histappend

# Check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# Enable ** for recursive globbing (e.g. ls **/*.txt)
shopt -s globstar

# Correct minor spelling errors in cd
shopt -s cdspell

# Set editor for command line and tools
export EDITOR=vim
export VISUAL=vim

# --- Custom Functions ---

# Create a directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Create a timestamped backup of a file
backup() {
    if [ -f "$1" ]; then
        cp -iv "$1" "$1.$(date +%Y%m%d-%H%M%S).bak"
    else
        echo "Error: File '$1' not found."
    fi
}

# Extract common file types
extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2)  tar xjf "$1"    ;;
            *.tar.gz)   tar xzf "$1"    ;;
            *.bz2)      bunzip2 "$1"    ;;
            *.rar)      unrar x "$1"    ;;
            *.gz)       gunzip "$1"     ;;
            *.tar)      tar xf "$1"     ;;
            *.tbz2)     tar xjf "$1"    ;;
            *.tgz)      tar xzf "$1"    ;;
            *.zip)      unzip "$1"      ;;
            *.Z)        uncompress "$1" ;;
            *.7z)       7z x "$1"       ;;
            *)          echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Directory Bookmark Management Function
jump() {
    local bookmark_file="$HOME/.bash_bookmarks"
    [ ! -f "$bookmark_file" ] && touch "$bookmark_file"
    case "$1" in
        -a)
            [ -z "$2" ] || [ -z "$3" ] && echo "Usage: jump -a <name> <path>" && return 1
            local bookmark_path="$(realpath "$3")"
            if grep -q "^$2=" "$bookmark_file"; then
                sed -i "/^$2=/c\\$2=$bookmark_path" "$bookmark_file"
                echo "Bookmark '$2' updated to '$bookmark_path'."
            else
                echo "$2=$bookmark_path" >> "$bookmark_file"
                echo "Bookmark '$2' added: '$bookmark_path'."
            fi
            ;;
        -d)
            [ -z "$2" ] && echo "Usage: jump -d <name>" && return 1
            if grep -q "^$2=" "$bookmark_file"; then
                sed -i "/^$2=/d" "$bookmark_file"
                echo "Bookmark '$2' deleted."
            else
                echo "Error: Bookmark '$2' not found." && return 1
            fi
            ;;
        -l)
            if [ ! -s "$bookmark_file" ]; then
                echo "No directory bookmarks found."
            else
                echo "Your directory bookmarks:"
                while IFS='=' read -r name path; do
                    printf "  %s -> %s\n" "$name" "$path"
                done < "$bookmark_file"
            fi
            ;;
        *)
            [ -z "$1" ] && echo "Usage: jump <name> | jump -a <name> <path> | jump -d <name> | jump -l" && return 1
            local bookmark_path=$(grep "^$1=" "$bookmark_file" | cut -d'=' -f2-)
            if [ -z "$bookmark_path" ]; then
                echo "Error: Bookmark '$1' not found." && return 1
            elif [ ! -d "$bookmark_path" ]; then
                echo "Error: Directory '$bookmark_path' for bookmark '$1' not found." && return 1
            else
                cd "$bookmark_path" || return 1
            fi
            ;;
    esac
}

# --- Tool Initializations ---

# Add user's local bin to PATH if it exists
[ -d "$HOME/.local/bin" ] && export PATH="$HOME/.local/bin:$PATH"

# nvm (Node Version Manager)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# conda (Python Environment Manager)
__conda_setup="$('/home/enweii/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/enweii/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/home/enweii/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/enweii/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup

# zoxide (smarter cd)
eval "$(zoxide init bash)"

# fzf (fuzzy finder)
# Enables keybindings (CTRL-T, CTRL-R, ALT-C)
[ -f /usr/share/doc/fzf/examples/key-bindings.bash ] && source /usr/share/doc/fzf/examples/key-bindings.bash
[ -f ~/.fzf-completion.bash ] && source ~/.fzf-completion.bash

# starship (prompt)
# Note: All visual prompt configuration is now in ~/.config/starship.toml
eval "$(starship init bash)"

# --- Sourcing Aliases ---

# Load custom aliases, if the file exists
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# --- Final Touches ---

# For real-time history sharing between terminals
# Appends history every time a command is run, and reloads it for the new prompt
export PROMPT_COMMAND="history -a; history -n; $PROMPT_COMMAND"