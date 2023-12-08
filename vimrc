" ===== Basic Setting ===== {{{
filetype on
filetype indent on
filetype plugin on
filetype plugin indent on

set autochdir

set nocompatible
set encoding=utf-8
set mouse=a

set number
set relativenumber
set numberwidth=4
set ruler
set cursorline
set cursorcolumn

set wrap

set shiftwidth=2
set shiftround
set expandtab
set tabstop=2
set softtabstop=2
set list
set scrolloff=5

set backspace=indent,eol,start
set foldmethod=indent
set foldlevel=99

set showmatch
set matchtime=2

syntax enable
syntax on

" === Search === {{{
set hlsearch
set incsearch
set ignorecase
set smartcase
" }}}

" === Statusline === {{{
set laststatus=2
set statusline=
set statusline+=\>
set statusline+=\ %{FugitiveStatusline()} " git branch
set statusline+=\ %m " modified
set statusline+=\ %F " file path
set statusline+=\ %y " filetype
set statusline+=%= " seperation
set statusline+=\ Ln\ %l,Col\ %c,Tot\ %L(%p%%) " line number, column, total, percent
set statusline+=\ < " end
set showmode
set showcmd
" Show command autocomplete
set wildignore=log/**,node_modules/**,target/**,tmp/**,*.rbc
set wildmenu
set wildmode=full
" }}}
" === Style ==={{{
set listchars=tab:▸\ ,trail:▫
let &t_ut=''

set t_Co=256
set background=dark
let g:solarized_termcolors=256
colorscheme solarized8
" }}}
" }}}

" ===== Basic Mappings ===== {{{
noremap n h
noremap u k
noremap e j
noremap i l
noremap N ^
noremap I g_

noremap h nzz
noremap j e
noremap k i
noremap l u
noremap K I
noremap H Nzz
" U/E keys for 5 times u/e (faster navigation)
noremap U 5k
noremap E 5j

noremap <CR> o<esc>

" Copy to system clipboard
vnoremap Y "+y
" }}}

" ===== Key Combinaitons ===== {{{
inoremap <c-a> <esc>I
inoremap <c-e> <esc>A
nnoremap <c-l> :nohlsearch<CR><C-L>
" }}}

let g:mapleader=" "

nmap <leader>pe :set paste<CR>
nmap <leader>pd :set nopaste<CR>

" ===== Window Management ===== {{{
map <leader>u <C-w>k
map <leader>e <C-w>j
map <leader>n <C-w>h
map <leader>i <C-w>l
" }}}

" ===== Tab Management ===== {{{
" Create a new tab with tu
nnoremap <silent> tu :tabnew<CR>
" change curruent window to new tab
nnoremap <silent> te <C-w>T
" Move around tabs with tn and ti
nnoremap <silent> tn :tabprevious<CR>
nnoremap <silent> ti :<C-U>if v:count == 0<CR>execute 'tabnext'<CR>else<CR>execute v:count . 'tabnext'<CR>endif<CR>
" Move the tabs with tmn and tmi
nnoremap <silent> tmn :-tabmove<CR>
nnoremap <silent> tmi :+tabmove<CR>
" }}}

" open help window vertically and on the right side
cabbrev hv vertical botright help

autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif

augroup newfile
  autocmd!
  autocmd BufNewFile,BufRead *.log setlocal nowrap
augroup END

packadd! matchit

" ===== Plugins ===== {{{
" install plugins by vim-plug
call plug#begin()

Plug 'nelstrom/vim-visual-star-search'
Plug 'mtdl9/vim-log-highlighting'
Plug 'tpope/vim-fugitive'
Plug 'justinmk/vim-sneak'
Plug 'tomtom/tcomment_vim'
Plug 'tpope/vim-surround'
Plug 'preservim/nerdtree'

call plug#end()
" }}}
