call plug#begin('~/.vim/plugged')
Plug 'davidhalter/jedi-vim'  " Using the jedi autocompletion library for VIM.
Plug 'ervandew/supertab'  " Perform all your vim insert mode completions with Tab
Plug 'tell-k/vim-autopep8'  " autopep8 plugin for Vim
Plug 'Shougo/unite.vim'  " Unite and create user interfaces
Plug 'Shougo/vimfiler.vim'  " Powerful file explorer implemented by Vim script
Plug 'Shougo/vimproc.vim'  " Interactive command execution in Vim.
Plug 'morhetz/gruvbox'  " Retro groove color scheme for Vim
Plug 'dense-analysis/ale'  " Check syntax in Vim asynchronously and fix files, with Language Server Protocol (LSP) support
Plug 'tpope/vim-surround'  " surround.vim: quoting/parenthesizing made simple
Plug 'tyru/open-browser.vim'  " Open URI with your favorite browser from your most favorite editor
Plug 'tomtom/tcomment_vim'  " An extensible & universal comment vim-plugin that also handles embedded filetypes
Plug 'Shougo/vimproc.vim', {'do' : 'make'}  " Distraction-free writing in Vim
Plug 'nathanaelkane/vim-indent-guides'  " A Vim plugin for visually displaying indent levels in code
Plug 'Yggdroot/indentLine'  " A vim plugin to display the indention levels with thin vertical lines
Plug 'integralist/vim-mypy'  " Vim plugin for executing Python's optional static type checker MyPy
Plug 'ConradIrwin/vim-bracketed-paste'  " vim-bracketed-paste enables transparent pasting into vim.
Plug 'vim-scripts/grep.vim'  " Plugin to integrate various grep like search tools with Vim.
Plug 'mattn/jvgrep'  " jvgrep is grep for Japanese vimmer. You can find text from files that written in another Japanese encodings.
Plug 'vlime/vlime', {'rtp': 'vim/'}  " Vlime is a Common Lisp dev environment for Vim (and Neovim), similar to SLIME for Emacs and SLIMV for Vim.
Plug 'justmao945/vim-clang'  " Use of clang to parse and complete C/C++ source files.
Plug 'tpope/vim-fugitive'  " Fugitive is the premier Vim plugin for Git.
call plug#end()

" Basic
set number
set expandtab
set softtabstop=4
set shiftwidth=4
set langmenu=en_US.UTF-8
language messages en_US.UTF-8
set backspace=indent,eol,start
set smartindent
set wildmenu
set wildmode=full
set history=200

" Color scheme
syntax enable
colorscheme gruvbox
set background=dark

" Python execution
nmap <C-S-f> :!python %<Return>

" Autopep8
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

" supertab
let g:SuperTabContextDefaultCompletionType = "context"
let g:SuperTabDefaultCompletionType = "<c-n>"

" Tab
nmap te :tabedit<Return>
nmap tl :Unite tab<Return>
nmap <S-Tab> :tabprev<Return>
nmap <Tab> :tabnext<Return>

" Split window
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
nmap <C-p> <Plug>(ale_previous_wrap)
nmap <C-n> <Plug>(ale_next_wrap)

let g:ale_python_flake8_args = '--ignore=E501'
let g:ale_python_flake8_executable = 'flake8'
let g:ale_python_flake8_options = '--ignore=E501'
let g:lightline = {
  \'active': {
  \  'left': [
  \    ['mode', 'paste'],
  \    ['readonly', 'filename', 'modified', 'ale'],
  \  ]
  \},
  \'component_function': {
  \  'ale': 'ALEGetStatusLine'
  \}
  \ }

" open-browser.vim
let g:netrw_nogx = 1 " disable netrw's gx mapping.
nmap gx <Plug>(openbrowser-smart-search)
vmap gx <Plug>(openbrowser-smart-search)

" Rgrep
nmap gr :Rgrep<CR>
let Grep_Skip_Dirs = '.svn .git'  " ignore the directories
let Grep_Default_Options = '-I'   " grep no binary files
let Grep_Skip_Files = '*.bak *~'  " ignore the backup file

if executable('jvgrep')
  set grepprg=jvgrep
endif

" set clang options for vim-clang
let g:clang_c_options = '-std=c14'
let g:clang_cpp_options = '-std=c++1z -stdlib=libc++ --pedantic-errors'
