#!/usr/bin/env bash
set -euo pipefail

# --- [設定區] ---
DOTFILES_REPO="https://github.com/YOUR_USERNAME/dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"

# --- [變數定義] ---
TOOLS_COMMON=(git curl wget tmux vim jq htop tree unzip zip)
TOOLS_DEV=(ripgrep fzf zoxide)
BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- [輔助函式] ---

log() { printf "${BLUE}\n==> %s${NC}\n" "$*"; }
warn() { printf "${YELLOW}[WARN] %s${NC}\n" "$*"; }
success() { printf "${GREEN}[OK] %s${NC}\n" "$*"; }
error() { printf "${RED}[ERROR] %s${NC}\n" "$*"; exit 1; }

need_cmd() { command -v "$1" >/dev/null 2>&1; }

sudo_cmd() {
  if need_cmd sudo && [ "${EUID:-0}" -ne 0 ]; then
    echo sudo
  else
    echo
  fi
}

# 備份並建立連結
link_dotfile() {
  local src="$1"  # e.g., $HOME/.dotfiles/.vimrc
  local dest="$2" # e.g., $HOME/.vimrc

  if [ ! -e "$src" ]; then
    return 0
  fi

  # 如果目標是連結且指向正確，跳過
  if [ -L "$dest" ] && [ "$(readlink -f "$dest")" = "$(readlink -f "$src")" ]; then
    log "Skipping $dest (already linked)"
    return
  fi

  # 如果目標存在（是檔案或錯誤的連結），先備份
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    warn "Backing up existing $dest to $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    mv "$dest" "$BACKUP_DIR/"
  fi

  log "Linking $src -> $dest"
  ln -s "$src" "$dest"
}

# --- [核心邏輯] ---

log "Detecting package manager..."
PM=""
if need_cmd apt-get; then PM=apt
elif need_cmd dnf; then PM=dnf
elif need_cmd pacman; then PM=pacman
elif need_cmd zypper; then PM=zypper
elif need_cmd brew; then PM=brew
else
  error "No supported package manager found."
fi
success "Detected: $PM"

log "Installing tools..."
SUDO=$(sudo_cmd)

# 處理不同發行版的套件名稱差異
PKG_FD="fd"
PKG_BAT="bat"
PKG_EZA="eza"

case "$PM" in
  apt)
    PKG_FD="fd-find" # Ubuntu/Debian 特有名稱
    PKG_BAT="bat"    # 新版 Ubuntu/Debian 已經叫 bat (有些舊版叫 batcat，下面會做連結處理)
    # Ubuntu 舊版可能沒有 eza，這裡假設是用戶已處理好來源或使用較新版
    $SUDO apt-get update -y
    $SUDO apt-get install -y "${TOOLS_COMMON[@]}" "${TOOLS_DEV[@]}" $PKG_FD $PKG_BAT
    ;;
  dnf)
    $SUDO dnf install -y "${TOOLS_COMMON[@]}" "${TOOLS_DEV[@]}" $PKG_FD $PKG_BAT $PKG_EZA
    ;;
  pacman)
    $SUDO pacman -Syu --noconfirm "${TOOLS_COMMON[@]}" "${TOOLS_DEV[@]}" $PKG_FD $PKG_BAT $PKG_EZA
    ;;
  brew)
    brew install "${TOOLS_COMMON[@]}" "${TOOLS_DEV[@]}" $PKG_FD $PKG_BAT $PKG_EZA
    ;;
esac

log "Ensuring local bin and fixing naming (batcat/fdfind)"
mkdir -p "$HOME/.local/bin"

# Ubuntu/Debian 常常安裝成 fdfind 和 batcat，這裡自動建立 alias 連結
if need_cmd fdfind && ! need_cmd fd; then
  ln -s "$(command -v fdfind)" "$HOME/.local/bin/fd"
  success "Linked fdfind -> fd"
fi
if need_cmd batcat && ! need_cmd bat; then
  ln -s "$(command -v batcat)" "$HOME/.local/bin/bat"
  success "Linked batcat -> bat"
fi

# 確保 .local/bin 在 PATH 中
PATH_FIX='export PATH="$HOME/.local/bin:$PATH"'
for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
  [ -f "$rc" ] && grep -qF "$PATH_FIX" "$rc" || echo "$PATH_FIX" >> "$rc"
done

log "Setting up Starship (Prompt)"
if ! need_cmd starship; then
  curl -fsSL https://starship.rs/install.sh | sh -s -- -y
fi

log "Cloning/Updating Dotfiles from Cloud..."
if [ -d "$DOTFILES_DIR" ]; then
  log "Dotfiles dir exists. Pulling latest changes..."
  git -C "$DOTFILES_DIR" pull || warn "Git pull failed"
else
  if [[ "$DOTFILES_REPO" == *"YOUR_USERNAME"* ]]; then
    warn "Dotfiles repo URL not set. Skipping cloud config sync."
    warn "Please edit the 'DOTFILES_REPO' variable in this script."
  else
    log "Cloning $DOTFILES_REPO to $DOTFILES_DIR"
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
  fi
fi

log "Linking Config Files..."
# 這裡列出你想要同步的檔案 (對應到 repo 內的檔名)
# 邏輯： Repo內檔案 -> 連結到 Home 目錄
if [ -d "$DOTFILES_DIR" ]; then
  link_dotfile "$DOTFILES_DIR/.vimrc"      "$HOME/.vimrc"
  link_dotfile "$DOTFILES_DIR/.tmux.conf"  "$HOME/.tmux.conf"
  link_dotfile "$DOTFILES_DIR/.zshrc"      "$HOME/.zshrc"
  link_dotfile "$DOTFILES_DIR/.bashrc"     "$HOME/.bashrc"
  link_dotfile "$DOTFILES_DIR/starship.toml" "$HOME/.config/starship.toml"
  # 你可以繼續新增，例如 .gitconfig 等
else
  warn "Dotfiles directory not found, skipping linking."
fi

log "Injecting Tool Init Scripts (fzf, zoxide, starship)"
# 為了避免重複寫入，我們使用一個統一的 Block
RC_BLOCK='
# --- Bootstrap Tool Managed Block ---
# Starship
command -v starship >/dev/null && eval "$(starship init bash)"

# Zoxide (Better cd)
command -v zoxide >/dev/null && eval "$(zoxide init bash)"

# FZF
if command -v fzf >/dev/null; then
  export FZF_DEFAULT_COMMAND="rg --files --hidden --follow --glob \"!.git/*\""
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  # 嘗試載入系統預設的 key-bindings
  [ -f /usr/share/doc/fzf/examples/key-bindings.bash ] && . /usr/share/doc/fzf/examples/key-bindings.bash
  [ -f /usr/share/fzf/key-bindings.bash ] && . /usr/share/fzf/key-bindings.bash
fi
# ------------------------------------
'

# Zsh 專用 Block (有些語法不同)
ZSH_RC_BLOCK='
# --- Bootstrap Tool Managed Block ---
command -v starship >/dev/null && eval "$(starship init zsh)"
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"
if command -v fzf >/dev/null; then
  export FZF_DEFAULT_COMMAND="rg --files --hidden --follow --glob \"!.git/*\""
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ] && . /usr/share/doc/fzf/examples/key-bindings.zsh
  [ -f /usr/share/fzf/key-bindings.zsh ] && . /usr/share/fzf/key-bindings.zsh
fi
# ------------------------------------
'

# 寫入設定檔函式
inject_rc() {
  local file="$1"
  local content="$2"
  [ ! -f "$file" ] && return
  # 檢查是否已經存在 Block 標記，若無則追加
  if ! grep -q "Bootstrap Tool Managed Block" "$file"; then
    echo "$content" >> "$file"
    success "Added init scripts to $file"
  else
    log "Init scripts already present in $file"
  fi
}

inject_rc "$HOME/.bashrc" "$RC_BLOCK"
inject_rc "$HOME/.zshrc" "$ZSH_RC_BLOCK"

log "Creating Vim directories"
mkdir -p "$HOME/.vim/undo" "$HOME/.vim/backup" "$HOME/.vim/swap"

success "Installation Complete!"
if [ -d "$BACKUP_DIR" ]; then
  warn "Old config files were backed up to: $BACKUP_DIR"
fi
echo "Please restart your shell or run: source ~/.bashrc (or ~/.zshrc)"
