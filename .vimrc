" =============================================================================
"  Vim 8.2 Ultimate Config for C++ Senior Developer
"  Features: CoC (LSP), FZF, Git Fugitive, Sonokai Theme, Semantic Highlighting
" =============================================================================

" --- 0. 自動安裝 vim-plug (若未安裝) ---
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" =============================================================================
"  1. 插件管理 (Plugins)
" =============================================================================
call plug#begin('~/.vim/plugged')

" --- 核心開發引擎 (針對 Vim 8.2 鎖定版本) ---
" [關鍵] 使用 tag: v0.0.82 避免版本過新報錯，並執行 npm ci 編譯
Plug 'neoclide/coc.nvim', {'tag': 'v0.0.82', 'do': 'npm ci'}

" --- 介面與美學 ---
Plug 'sainnhe/sonokai'             " 高級莫蘭迪色系主題
Plug 'sainnhe/everforest'
Plug 'dracula/vim', { 'as': 'dracula' }
Plug 'bfrg/vim-cpp-modern'         " C++ 語法高亮增強 (關鍵字/變數分色)
Plug 'vim-airline/vim-airline'     " 狀態列
Plug 'vim-airline/vim-airline-themes'
Plug 'ryanoasis/vim-devicons'      " 檔案圖示 (需 Nerd Fonts)

" --- 檔案導航 ---
Plug 'preservim/nerdtree'          " 檔案樹
Plug 'Xuyuanp/nerdtree-git-plugin' " 讓檔案樹顯示 Git 狀態
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'            " 極速模糊搜尋

" --- Git 整合 ---
Plug 'tpope/vim-fugitive'          " Git 神器 (:Git, :Gdiffsplit)
Plug 'airblade/vim-gitgutter'      " 側邊欄顯示修改狀態 (+/-)

" --- 編輯輔助 ---
Plug 'preservim/nerdcommenter'     " 快速註解 (<leader>c<space>)
Plug 'jiangmiao/auto-pairs'        " 自動補全括號

call plug#end()

" =============================================================================
"  2. 基礎設定 (Basics)
" =============================================================================
set nocompatible
syntax on
set number                  " 顯示行號
set relativenumber          " 相對行號 (大範圍跳轉神器)
set cursorline              " 高亮當前行
set encoding=utf-8
set fileencodings=utf-8,big5,gbk
set clipboard=unnamedplus   " 系統剪貼簿互通
set mouse=a                 " 允許滑鼠滾動/點擊
set updatetime=300          " 加快更新頻率 (對 GitGutter/CoC 重要)
set signcolumn=yes          " 總是顯示側邊欄 (避免畫面跳動)
set shortmess+=c            " 減少補全時的干擾訊息

" --- 縮排 (C++ 標準 4 空格) ---
set tabstop=4
set shiftwidth=4
set expandtab               " Tab 轉 Space
set smartindent

" --- 搜尋 ---
set ignorecase              " 忽略大小寫
set smartcase               " 有大寫時才區分
set hlsearch                " 高亮結果
set incsearch               " 邊打邊搜

" =============================================================================
"  3. 主題與外觀 (Aesthetics)
" =============================================================================
" 開啟全彩支援 (Sonokai 必須)
if (has("termguicolors"))
  set termguicolors
endif

" vim-cpp-modern 設定 (讓 C++ 顏色豐富化)
let g:cpp_class_scope_highlight = 1
let g:cpp_member_variable_highlight = 1
let g:cpp_class_decl_highlight = 1
let g:cpp_concepts_highlight = 1
let g:cpp_experimental_template_highlight = 1 

colorscheme dracula
let g:airline_theme = 'dracula'

" =============================================================================
"  4. 按鍵映射 (Key Mappings)
" =============================================================================
let mapleader=","  " Leader Key 設為,

" --- 視窗操作 ---
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l
nnoremap <leader>nh :nohl<CR> " 清除搜尋高亮

" --- 檔案與搜尋 ---
nnoremap <leader>e :NERDTreeToggle<CR>
nnoremap <leader>f :Files<CR>
nnoremap <leader>g :Rg<CR>
nnoremap <leader>b :Buffers<CR>

" --- Git 操作 (Fugitive) ---
nnoremap <leader>gs :Git<CR>         " Git Status 儀表板
nnoremap <leader>gd :Gdiffsplit<CR>  " 左右比對差異
nnoremap <leader>gc :Git commit<CR>  " 提交
nnoremap <leader>gb :Git blame<CR>   " 查看每行作者

" =============================================================================
"  5. CoC.nvim 設定 (Vim 8.2 Legacy Mode)
" =============================================================================
" TAB 鍵補全邏輯
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Enter 確認補全
inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"

" 程式碼導航
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" 顯示文件 (K)
nnoremap <silent> K :call <SID>show_documentation()<CR>
function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

" 重新命名變數 (Leader + rn)
nmap <leader>rn <Plug>(coc-rename)

" 格式化程式碼 (Leader + fm)
nmap <leader>fm <Plug>(coc-format)
