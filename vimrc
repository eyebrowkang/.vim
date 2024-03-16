" Options: {{{
" <<< Indentation >>>
set autoindent
set expandtab
set smarttab
set shiftround
set shiftwidth=4
set tabstop=4
set softtabstop=4
" <<< Display >>>
set background=dark
set termguicolors
set cursorcolumn
set cursorline
set display=lastline,uhex
set number
set relativenumber
set scrolloff=5
set sidescroll=1
set sidescrolloff=5
set list
set listchars=tab:▸\ ,trail:▫,nbsp:␣,precedes:«,extends:» " eol:⏎
set showcmd
set showmode
set showmatch
set matchtime=1
set nowrap
set wildmenu
set wildignore=*.o,*.obj,*.swp,*/node_modules/*
set laststatus=2
set statusline=
set statusline+=\>\ 
set statusline+=[%n] " Buffer number
set statusline+=%m " Modified flag
set statusline+=%q " [Quickfix List], [Location List] or empty.
set statusline+=\ %f\  " Path to the file in the buffer
set statusline+=%y " filetype
set statusline+=%= " seperation
set statusline+=Ln\ %l,Col\ %c,Tot\ %L(%p%%) " line number, column, total, percent
set statusline+=\ < " end
" <<< Search >>>
set hlsearch
set ignorecase
set incsearch
set smartcase
" <<< Others >>>
set autoread
set backspace=indent,eol,start
set encoding=utf-8
set foldlevel=99
set foldmethod=marker
set history=200
set langnoremap
set nolangremap
set mouse=nvi
set ruler
set nostartofline
set ttimeoutlen=100
" }}}
" Syntax: {{{
syntax enable
colorscheme solarized8
" }}}
" Filetype: {{{
filetype plugin indent on
" }}}
" Keymap: {{{
" <<< Arrow Keys >>>
noremap n h
noremap u k
noremap e j
noremap i l

noremap L H
noremap N M
noremap M L
noremap h nzz
noremap H Nzz
noremap U K
noremap k i
noremap K I
" noremap E J
noremap j e
" noremap J E
noremap I U
noremap l u

" Copy to system clipboard
vnoremap Y "+y

noremap <CR> ciw
inoremap <C-A> <Esc>I
inoremap <C-E> <Esc>A
nnoremap <C-L> :nohlsearch<CR><C-L>

" <<< Window Management >>>
" map <C-W>u <C-W>k
" map <C-W>e <C-W>j
" map <C-W>n <C-W>h
" map <C-W>i <C-W>l
map <C-W><C-U> <C-W>k
map <C-W><C-E> <C-W>j
map <C-W><C-N> <C-W>h
map <C-W><C-I> <C-W>l

let g:mapleader=" "

nmap <leader>pe :set paste<CR>
nmap <leader>pd :set nopaste<CR>
" }}}
" Miscellaneous: {{{
" let &t_ut=''
" <<< Abbreviations >>>
cabbrev hb botright help
cabbrev hr vertical botright help
cabbrev ht tab help

augroup vimStartup
  autocmd!

  " When editing a file, always jump to the last known cursor position.
  " Don't do it when the position is invalid, when inside an event handler
  " (happens when dropping a file on gvim), for a commit or rebase message
  " (likely a different one than last time), and when using xxd(1) to filter
  " and edit binary files (it transforms input files back and forth, causing
  " them to have dual nature, so to speak)
  autocmd BufReadPost *
    \ let line = line("'\"")
    \ | if line >= 1 && line <= line("$") && &filetype !~# 'commit'
    \      && index(['xxd', 'gitrebase'], &filetype) == -1
    \ |   execute "normal! g`\""
    \ | endif

augroup END
"}}}
" Plugin: {{{
packadd! matchit
"}}}
