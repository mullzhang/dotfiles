call plug#begin('~/.vim/plugged')
Plug 'scrooloose/nerdtree', { 'on': ['NERDTreeToggle'] }
Plug 'tpope/vim-fireplace', { 'for': ['clojure'] }
Plug 'zah/nim.vim', { 'for': ['nim'] }
Plug 'melrief/vim-frege-syntax', { 'for': ['frege'] }
Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'
Plug 'nathanaelkane/vim-indent-guides'
Plug 'Shougo/unite.vim'
Plug 'scrooloose/nerdtree'
Plug 'tpope/vim-fugitive'
Plug 'kien/ctrlp.vim'
Plug 'thinca/vim-visualstar'
Plug 'davidhalter/jedi-vim'
Plug 'ervandew/supertab'
Plug 'tomtom/tcomment_vim'
Plug 'osyo-manga/vim-over'
Plug 'lervag/vimtex'
Plug 'nvie/vim-flake8'
Plug 'tell-k/vim-autopep8'
Plug 'nathanaelkane/vim-indent-guides'
Plug 'Yggdroot/indentLine'
Plug 'vim-jp/vim-cpp'
Plug 'rhysd/wandbox-vim'
Plug 'osyo-manga/vim-marching'
Plug 't9md/vim-quickhl'
Plug 'jceb/vim-hier'
Plug 'tyru/caw.vim'
Plug 'thinca/vim-quickrun'
Plug 'Shougo/vimproc.vim', {'do' : 'make'}
Plug 'Shougo/neocomplete.vim'
Plug 'Shougo/neosnippet.vim'
Plug 'Shougo/neosnippet-snippets'
Plug 'Shougo/unite-outline'
Plug 'hewes/unite-gtags'
Plug 'morhetz/gruvbox'
Plug 'ujihisa/unite-colorscheme'
Plug 'altercation/vim-colors-solarized'
Plug 'Shougo/vimfiler.vim'
Plug 'Yggdroot/indentLine'
Plug 'dense-analysis/ale'
call plug#end()

setlocal omnifunc=syntaxcomplete#Complete
set number
set expandtab
set tabstop=4
set shiftwidth=4
set langmenu=en_US.UTF-8
language messages en_US.UTF-8
set backspace=indent,eol,start
set encoding=utf-8
set fileencodings=utf-8,cp932,euc-jp,sjis
set fileformats=unix,dos,mac

syntax enable
colorscheme gruvbox
set background=dark

" original http://stackoverflow.com/questions/12374200/using-uncrustify-with-vim/15513829#15513829
function! Preserve(command)
    " Save the last search.
    let search = @/
    " Save the current cursor position.
    let cursor_position = getpos('.')
    " Save the current window position.
    normal! H
    let window_position = getpos('.')
    call setpos('.', cursor_position)
    " Execute the command.
    execute a:command
    " Restore the last search.
    let @/ = search
    " Restore the previous window position.
    call setpos('.', window_position)
    normal! zt
    " Restore the previous cursor position.
    call setpos('.', cursor_position)
endfunction

function! Autopep8()
    call Preserve(':silent %!autopep8 --ignore=E501 -')
endfunction

autocmd FileType python nnoremap <S-f> :call Autopep8()<CR>

let g:indentLine_fileTypeExclude = ['help', 'nerdtree', 'calendar', 'thumbnail', 'tweetvim']

let g:ycm_global_ycm_extra_conf = '${HOME}/dotfiles/.ycm_extra_conf.py'
let g:ycm_auto_trigger = 1
let g:ycm_min_num_of_chars_for_completion = 3
let g:ycm_autoclose_preview_window_after_insertion = 1
set splitbelow

map <C-n> :NERDTreeToggle<CR>

nmap <C-K> <Plug>(caw:hatpos:toggle)
vmap <C-K> <Plug>(caw:hatpos:toggle)

nmap <Space>m <Plug>(quickhl-manual-this)
xmap <Space>m <Plug>(quickhl-manual-this)
nmap <Space>M <Plug>(quickhl-manual-reset)
xmap <Space>M <Plug>(quickhl-manual-reset)

imap <S-> <nop>
set pastetoggle=<S->

nmap te :tabedit
nmap tl :Unite tab
nmap <S-Tab> :tabprev<Return>
nmap <Tab> :tabnext<Return>

" plit window
nmap ss :split<Return><C-w>w
nmap sv :vsplit<Return><C-w>w

" Move window
nmap <Space> <C-w>w
map s<left> <C-w>h
map s<up> <C-w>k
map s<down> <C-w>j
map s<right> <C-w>l
map sh <C-w>h
map sk <C-w>k
map sj <C-w>j
map sl <C-w>l

" Resize window
nmap <C-w><left> <C-w><
nmap <C-w><right> <C-w>>
nmap <C-w><up> <C-w>+
nmap <C-w><down> <C-w>-

" VimFiler
nmap sf :VimFilerBufferDir<Return>
nmap sF :VimFilerExplorer -find<Return>
nmap sb :Unite buffer<Return>
let g:vimfiler_as_default_explorer = 1
let g:vimfiler_safe_mode_by_default = 0
let g:vimfiler_enable_auto_cd = 0
let g:vimfiler_tree_leaf_icon = ''
let g:vimfiler_tree_opened_icon = '▾'
let g:vimfiler_tree_closed_icon = '▸'
let g:vimfiler_marked_file_icon = '✓'

" Ale
nmap <silent> <C-k> <Plug>(ale_previous_wrap)
nmap <silent> <C-j> <Plug>(ale_next_wrap)

