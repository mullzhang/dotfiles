call plug#begin('~/.vim/plugged')
Plug 'junegunn/seoul256.vim'
Plug 'scrooloose/nerdtree', { 'on': ['NERDTreeToggle'] }
Plug 'tpope/vim-fireplace', { 'for': ['clojure'] }
Plug 'zah/nim.vim', { 'for': ['nim'] }
Plug 'melrief/vim-frege-syntax', { 'for': ['frege'] }
Plug 'SirVer/ultisnips' | Plug 'honza/vim-snippets'
Plug 'tomasr/molokai'
Plug 'nathanaelkane/vim-indent-guides'
Plug 'Shougo/unite.vim'
Plug 'scrooloose/nerdtree'
Plug 'AlessandroYorba/Alduin'
Plug 'tpope/vim-fugitive'
Plug 'kien/ctrlp.vim'
Plug 'thinca/vim-visualstar'
Plug 'davidhalter/jedi-vim'
Plug 'tomtom/tcomment_vim'
Plug 'osyo-manga/vim-over'
Plug 'lervag/vimtex'
Plug 'nvie/vim-flake8'
call plug#end()

setlocal omnifunc=syntaxcomplete#Complete
set number
set expandtab
set tabstop=4
set shiftwidth=4

syntax on
let g:alduin_Shout_Dragon_Aspect = 1
colorscheme alduin

map <C-n> :NERDTreeToggle<CR>
