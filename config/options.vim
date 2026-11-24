" config/options.vim
" 基础选项、状态栏、配色，以及文件类型和语法高亮的开关。
" 依赖：无。只用 Vim 自带的功能。
"
" 说明：注释里标注「Neovim 默认」的项，是 Vim 和 Neovim 默认值不同、
" 这里把 Vim 调成和 Neovim 一样的地方。两边来回切换时手感一致，
" 不用记「这个编辑器里退格能不能删到上一行」这种事。
" Neovim 的完整默认值差异见 :help vim-differences（在 Neovim 里查）。
scriptencoding utf-8

" 注意：mapleader 不在这里设置，它在 vimrc 最顶部。

" ====================================================================
" 1. 状态目录：swap / undo / backup / viminfo 的存放位置
" ====================================================================
" Vim 的默认值会把这些文件写进**被编辑文件所在的目录**
" （'directory' 默认是 ".,~/tmp,/var/tmp,/tmp"，第一项 "." 就是当前目录），
" 在项目里留下一堆 .swp 和 ~ 文件。Neovim 默认都放在 ~/.local/state/nvim/，
" 这里照着放到 ~/.local/state/vim/，遵守 XDG_STATE_HOME。
"
" 用 s: 开头的变量是「脚本局部」的，只在本文件里可见，不会污染全局命名空间。
let s:state = (empty($XDG_STATE_HOME) ? expand('~/.local/state') : $XDG_STATE_HOME) . '/vim'

" 目录不存在时 Vim 不会自己建，只会静默地不写 swap、报错说写不了 undo。
" 0700 是因为这些文件里有你编辑过的全部内容，不该让别的用户读到。
for s:dir in ['swap', 'undo', 'backup']
  if !isdirectory(s:state . '/' . s:dir)
    call mkdir(s:state . '/' . s:dir, 'p', 0700)
  endif
endfor
unlet s:dir

" 结尾的 // 表示用文件的完整路径来命名（/ 换成 %），
" 这样两个项目里同名的 main.py 不会抢同一个 swap 文件。
"
" 交换文件（swap）：崩溃恢复 + 多开告警
"   编辑期间把未保存的改动持续写进 .swp。断电、进程被杀后可以 :recover 找回；
"   同一个文件被两个 Vim 打开时弹出 E325 告警，防止两边互相覆盖。
"   这两层保护 undofile 都替代不了，所以保持开启（Vim 默认就是开的）。
let &directory = s:state . '/swap//'
set swapfile

" 备份文件（backup）：:w 时把保存前的版本另存一份。日常有 git 兜底，不需要。
" 但 'writebackup' 是 Vim 默认开着的：保存时先写一份临时备份，写成功后再删掉，
" 防止写到一半磁盘满了把原文件也毁掉。这个临时文件同样写在 'backupdir' 里，
" 所以 backupdir 也要挪走，否则保存时项目目录里会一闪而过一个 file~。
let &backupdir = s:state . '/backup//'
set nobackup
set writebackup

" 撤销文件（undo）：把撤销历史持久化到磁盘
"   每次 :w 把整棵撤销树写进 undo 目录，明天重开同一个文件仍然可以一路 u 回去。
"   它保护的是「已经保存过的编辑历史」，不是「还没保存的内容」，后者是 swap 的事。
"   has() 判断是给没编译 +persistent_undo 的精简版 Vim 留的。
if has('persistent_undo')
  let &undodir = s:state . '/undo//'
  set undofile
endif

" viminfo：命令历史、搜索历史、寄存器、文件标记（含「上次光标位置」）
"   相当于 Neovim 的 shada。默认写在 ~/.viminfo，这里挪到状态目录。
"   'viminfofile' 是 8.1 才有的选项，更早的版本退回默认位置。
"   ! 表示同时保存全大写的全局变量（Neovim 默认包含）。
"   '1000 表示记住最近 1000 个文件的标记，默认的 100 个太少，
"   老文件的「上次光标位置」很快就被挤掉了。
if exists('+viminfofile')
  let &viminfofile = s:state . '/viminfo'
endif
set viminfo=!,'1000,<50,s10,h

" ====================================================================
" 2. 外观与显示
" ====================================================================
set number " 显示绝对行号
set relativenumber " 同时显示相对行号：配合 5j / 10k 这类相对跳转，不用心算
set cursorline " 高亮光标所在行，长文件里更容易找到自己
set scrolloff=8 " 上下滚动时，光标距离屏幕上下边缘至少保留 8 行
set sidescrolloff=8 " 左右滚动时，光标距离屏幕左右边缘至少保留 8 列

" sidescroll：横向滚动时一次挪几列。Vim 默认 0 = 光标出屏时一下跳半屏，
" 关了 wrap 之后看长行特别晕。Neovim 默认 1，一列一列平滑地挪。
set sidescroll=1

" 没设 signcolumn：Vim 里没有插件往标记列放东西（Git 标记、诊断图标），
" 保持默认的 auto，平时不占宽度。

" showmode：在最底下一行显示 -- INSERT -- 。
" 和 Neovim 配置相反，这里要开着：Vim 没有 lualine，状态栏里也没写模式，
" 关掉就完全看不出自己在哪个模式。（Vim 默认就是开的，显式写出）
set showmode

" showcmd：右下角显示正在输入的未完成命令（比如按了 2d 还没按下一个键）。
" 可视模式下还会显示选区大小。Neovim 默认开启。
set showcmd

" laststatus=2：所有窗口都显示状态栏，只有一个窗口时也显示。
" Vim 默认 1（分屏后才有），单窗口时就看不到文件名了。Neovim 默认 2。
set laststatus=2

" display=lastline：最后一行太长、屏幕放不下时，尽量显示它的开头，
" 末尾用 @@@ 标出，而不是把整行替换成一列 @。Neovim 默认值。
set display=lastline

" 字符画：分屏竖线用连续的 │（默认是 |，上下之间有缝），折叠行用 · 填充。
" 和 Neovim 在 UTF-8 下的默认值一致。
" silent! 是给不认识某个字段的老版本 Vim 准备的，失败了就保持默认。
silent! set fillchars=vert:│,fold:·

" 不可见字符：默认不显示（list 关），需要时 :set list 临时打开看缩进和行尾空格。
" listchars 照抄 Neovim 默认值，这样两边 :set list 看到的是同一套符号。
" Vim 的默认值只有 eol:$，打开 list 后每一行末尾都多一个 $，没法读。
set nolist
set listchars=tab:>\ ,trail:-,nbsp:+

" 光标形状：普通模式方块、插入模式竖线、替换模式下划线。
" Neovim 默认就这样做，Vim 在终端里不会自己改，要手动给出 DECSCUSR 转义序列：
"   \e[2 q 方块   \e[6 q 竖线   \e[4 q 下划线   \e[0 q 恢复终端默认
" t_SI / t_SR / t_EI 分别在进入插入模式、进入替换模式、回到普通模式时发送。
" 追加到 t_ti / t_te：启动时先设成方块，退出时把光标还给终端自己的设置，
" 否则退出 Vim 之后 shell 里的光标会停在最后那个形状上。
" Linux 字符控制台（TERM=linux）不认识这组序列，跳过。
if &term !~# '^linux'
  let &t_SI = "\e[6 q"
  let &t_SR = "\e[4 q"
  let &t_EI = "\e[2 q"
  let &t_ti .= "\e[2 q"
  let &t_te .= "\e[0 q"
endif

" ====================================================================
" 3. 颜色
" ====================================================================
" termguicolors：用 24 位真彩色代替 256 色调色板。
" Neovim 会自动探测终端能力，Vim 不会，这里用 COLORTERM 判断：
" Ghostty、iTerm2、新版 tmux 都会设成 truecolor；
" Debian 的 ssh / sshd 默认配置也会转发这个变量，SSH 登录后照样能判断。
" 判断不出来时保持 256 色，habamax 本来就为 256 色调过，看起来差别不大。
if has('termguicolors') && $COLORTERM =~# '^\%(truecolor\|24bit\)$'
  set termguicolors
endif

" 暗色背景。很多配色会根据它切换深浅两套颜色。Neovim 默认 dark。
set background=dark

" 打开语法高亮。必须在 colorscheme 之前：syntax enable 会重置部分高亮组。
" 用 enable 而不是 on：on 会把你自己定义过的高亮颜色全部覆盖回默认值。
syntax enable

" 配色：habamax，Vim 9 自带的暗色主题，灰蓝底、低对比，长时间看不累。
" 选自带主题而不是第三方：克隆下来就能用，不需要额外的文件，也不会过时。
" Vim 9 之前没有 habamax，会报 E185，这时退回所有版本都有的 desert。
try
  colorscheme habamax
catch /^Vim\%((\a\+)\)\=:E185:/
  colorscheme desert
endtry

" ====================================================================
" 4. 状态栏
" ====================================================================
" 不用插件，只用 'statusline' 的格式化字符串。最终效果大致是：
"   config/options.vim [+]                    vim │ 120:8  42%
" 左边：文件路径（相对当前目录）和状态标记；右边：文件类型、行:列、位置百分比。
" 编码不是 utf-8、换行符不是 unix 时才额外显示，平时不占地方。
"
" 用 let 和 join 拼字符串，比 set statusline+=\ ... 一行行转义空格好读得多。
" 各个 % 项的含义见 :help 'statusline'。
let &statusline = join([
      \ ' %<%f',
      \ ' %h%w%m%r',
      \ '%=',
      \ "%{&fileencoding !=# '' && &fileencoding !=# 'utf-8' ? &fileencoding . ' │ ' : ''}",
      \ "%{&fileformat !=# 'unix' ? &fileformat . ' │ ' : ''}",
      \ "%{&filetype !=# '' ? &filetype . ' │ ' : ''}",
      \ '%l:%c  %P ',
      \ ], '')
" 上面每一项：
"   %<    状态栏放不下时从这里开始截断（截掉路径的开头，保住右半边）
"   %f    文件路径，按你打开它时的写法显示
"   %h%w  [帮助] [预览] 标记；%m 已修改 [+]；%r 只读 [RO]
"   %=    左右分界，之后的内容靠右对齐
"   %l:%c 行号:列号（列号按字节算，和 Neovim 的 lualine 一致）
"   %P    在文件中的位置：Top / Bot / All 或百分比

" 没设 ruler：状态栏设了之后 ruler 不再显示，开不开没区别。

" ====================================================================
" 5. 缩进与排版
" ====================================================================
set expandtab " 按 Tab 键插入空格而不是制表符
set tabstop=4 " 一个制表符在屏幕上显示为 4 列宽
set shiftwidth=4 " 每一级缩进（>> 、<< 、自动缩进）的宽度
set softtabstop=4 " 插入模式下 Tab/退格 按「4 个空格为一格」来进退
set nowrap " 关闭软折行：超长行横向滚动，代码对齐关系不被打乱

" autoindent：新开一行时沿用上一行的缩进。Vim 默认关，Neovim 默认开。
" 有 filetype indent 的语言会被 indentexpr 接管，它是没有缩进规则时的兜底。
set autoindent

" smarttab：在行首按 Tab 用 shiftwidth，其他地方用 softtabstop。Neovim 默认开启。
set smarttab

" 刻意不开 smartindent：它是粗糙的 C 风格缩进，在 Python 里行首输入 # 会被
" 强制顶到第 0 列。filetype indent（第 10 节）的效果更好，也会直接覆盖它。

" 退格键可以删掉自动缩进、行尾换行、以及进入插入模式之前的内容。
" Vim 默认值是空的，退格在这三处都删不动，像是键盘坏了。Neovim 默认值。
set backspace=indent,eol,start

" formatoptions 加上 j：用 J 合并两行注释时，自动去掉下一行开头的注释符。
" Neovim 默认是 tcqj。各语言的 ftplugin 会在缓冲区里改写它，这里只是全局默认值。
set formatoptions+=j

" nojoinspaces：J 合并句子时，句号后面只补一个空格而不是两个。Neovim 默认关。
set nojoinspaces

" nrformats：<C-a> / <C-x> 加减数字时，只认十进制、0x 十六进制、0b 二进制。
" 去掉 Vim 默认的 octal：否则对 007 按 <C-a> 会得到 010（八进制的 8）。
set nrformats=bin,hex

" ====================================================================
" 6. 搜索
" ====================================================================
set ignorecase " 搜索时忽略大小写
set smartcase " 但只要输入了大写字母，就自动切回区分大小写（要和 ignorecase 一起用）
set hlsearch " 高亮所有匹配项（Neovim 默认开启）
set incsearch " 边输入边高亮预览第一个匹配（Neovim 默认开启）

" 搜索时在命令行右侧显示 [3/12]，告诉你这是第几个、一共几个。
" Vim 默认的 shortmess 里有 S，把这个计数藏起来了；Neovim 默认去掉了 S。
set shortmess-=S

" path：gf、:find 在哪些目录里找文件。"." 是当前文件所在目录，空项是当前工作目录。
" Vim 默认还带一个 /usr/include，那是给 C 准备的，C 的 ftplugin 会自己加上。
" Neovim 默认就是 ".,,"。
set path=.,,

" :grep 用 ripgrep。和 Neovim 一样：系统里装了 rg 才用，没装就保持默认的 grep。
" -uu 表示连 .gitignore 里的文件和隐藏文件也搜（:grep 的语义就是「全搜」）。
" 结果进 quickfix，用 ]q / [q 逐条跳（config/keymaps.vim 第 5 节）。
if executable('rg')
  set grepprg=rg\ --vimgrep\ -uu
  set grepformat=%f:%l:%c:%m
endif

" ====================================================================
" 7. 剪贴板与鼠标
" ====================================================================
" 刻意不设置 clipboard 选项，保持 Vim 寄存器与系统剪贴板彼此独立，
" 和 Neovim 配置是同一个思路：y/d/p 只在 Vim 内部流转。
"
" 而且 Debian 的 vim 包没有编译 +clipboard（:echo has('clipboard') 是 0），
" "+ 寄存器根本不存在，"+y 会静默地退化成普通的 y。
" 复制到系统剪贴板改走 OSC 52：<leader>y 系列映射（config/keymaps.vim 第 3 节）
" 通过终端转义序列把内容交给终端，本地、SSH、tmux 里都能用。
" 粘贴用终端自己的粘贴键（Ctrl+Shift+V / Cmd+V），Vim 能识别括号粘贴模式，
" 插入模式下粘贴一大段代码也不会被自动缩进打乱。

set mouse=a " 所有模式都启用鼠标

" ttymouse：鼠标事件用哪种协议编码。sgr 协议没有坐标上限，也能正确报告拖动。
" Vim 只有在 TERM 以 xterm 开头时才自动选 sgr，tmux 里的 TERM 是 tmux-256color，
" 会退回老的 xterm 协议：超过 223 列的位置点不到，拖动调整分屏大小也不灵。
" tmux 和 screen 都支持 sgr，这里补上。
if has('mouse_sgr') && $TERM =~# '^\%(tmux\|screen\)'
  set ttymouse=sgr
endif

" ====================================================================
" 8. 响应速度
" ====================================================================
" timeoutlen：组合键序列中，两次按键之间的最长等待时间（毫秒）。
" 按下 <leader> 之后有这么久的时间去按下一个键，超时就当作单独的按键处理。
" Vim 默认 1000，按完前缀键停顿明显。和 Neovim 配置一致用 500。
set timeoutlen=500

" ttimeoutlen：终端发来的转义序列（方向键、Alt 组合）最多等多久凑齐。
" Vim 默认 -1 = 沿用上面的 timeoutlen，于是按 Esc 离开插入模式要等半秒，
" 因为 Vim 在等着看它是不是方向键的开头。Neovim 默认 50。
set ttimeout
set ttimeoutlen=50

" 没设 updatetime：Vim 里没有插件用 CursorHold。它的另一个作用是
" 「停止输入多久后把 swap 写盘」，保持默认的 4 秒就好。

" ====================================================================
" 9. 窗口、缓冲区与命令行
" ====================================================================
set splitbelow " :split 横向分屏时，新窗口出现在下方
set splitright " :vsplit 纵向分屏时，新窗口出现在右方

" hidden：切换到别的缓冲区时，允许当前缓冲区带着未保存的改动留在后台。
" Vim 默认关，切走之前必须先 :w，否则报 E37。Neovim 默认开启。
" 不用担心忘了保存：退出时 Vim 仍会提示还有改动没存。
set hidden

" autoread：文件在外部被改了（git checkout、格式化工具）而缓冲区里没有改动时，
" 自动重新读入。Neovim 默认开启。Vim 只在执行外部命令之后、:checktime 时检查，
" 切回终端窗口时的检查靠 config/autocmds.vim 第 4 节。
set autoread

" belloff=all：任何情况下都不响铃、不闪屏。Neovim 默认值。
set belloff=all

" history：命令行和搜索的历史条数。Vim 默认 50，Neovim 默认 10000（上限）。
set history=10000

" 命令行补全：wildmenu 在命令行上方列出候选项；pum 让它以弹出菜单的形式竖着显示。
" pum 是 8.2.4325 才有的，老版本用 silent! 跳过，保留横向的 wildmenu。
" 都是 Neovim 默认值（Neovim 还多一个 tagfile，Vim 没有）。
set wildmenu
silent! set wildoptions=pum

" 插入模式补全（<C-n> / <C-p>）的菜单：只有一个候选时也显示菜单，
" 附加信息放在旁边的弹窗而不是顶部的预览窗口。Neovim 默认值是 menu,popup。
" popup 是 8.1.1880 才有的，老版本退回默认值。
silent! set completeopt=menu,popup

" diff 模式的行对齐算法：linematch 会在改动块内部再按行配对，
" 改了几个字的行和原来那行对齐着显示，而不是整块标红再整块标绿。
" Neovim 默认包含 linematch:40。Vim 9.1.1009 才有，老版本跳过。
silent! set diffopt+=linematch:40

" 保存会话（:mksession）和视图时不带选项值。Neovim 默认排除 options：
" 否则改过的配置会被旧会话文件里存的选项覆盖回去，很难察觉。
set sessionoptions-=options
set viewoptions-=options

" langremap 关掉：避免 'langmap'（如果设了）误伤映射里的字符。
" Neovim 默认 langnoremap 开、langremap 关，两者是同一件事的正反面。
set nolangremap

" ====================================================================
" 10. 代码折叠
" ====================================================================
" Neovim 那边用 treesitter 按语法树折叠，Vim 没有 treesitter。
" 剩下的几种方式里：
"   indent  按缩进层级折，任何语言都能用，速度快              ← 选这个
"   syntax  按语法文件里定义的区块折，只有部分语言支持，大文件很慢
"   marker  只认 {{{ }}} 标记，没写标记的文件就什么都没有
" 常用按键都是内置的：za 切换、zc 收起、zo 展开、zR 全开、zM 全收。
set foldmethod=indent

" 默认全部展开，需要时再自己 zc / zM 收。
" foldlevelstart 让每个新打开的文件都从全展开开始，不受上一个窗口的影响。
set foldlevel=99
set foldlevelstart=99

" 没设 foldtext：Vim 不支持 Neovim 那种「设成空字符串就显示原文」，
" 默认的 +--  7 lines: ... 已经足够清楚。

" ====================================================================
" 11. 文件类型
" ====================================================================
" 一条命令打开三件事（Neovim 默认全开，Vim 默认全关）：
"   filetype on      按文件名和内容识别类型（还会读本仓库的 filetype.vim）
"   plugin           加载对应的 ftplugin/（注释符、局部选项）
"   indent           加载对应的 indent/（自动缩进规则）
filetype plugin indent on

" Neovim 的 :Man 是内置的，Vim 要加载 man 的 ftplugin 才有这个命令。
" 加载后 K 也改成用 :Man 在 Vim 窗口里打开手册，而不是退出全屏去跑外部的 man。
" Vim 自己的文档（:help find-manpage）推荐的就是这种写法。
runtime ftplugin/man.vim
set keywordprg=:Man

" 没开 exrc：Neovim 用 :trust 记录每个项目配置文件的 hash，
" Vim 没有这层保护，开了就等于打开任意目录都可能执行陌生的脚本。
" 项目级的缩进、编码、行宽交给 .editorconfig（config/packages.vim 第 3 节）。

" ====================================================================
" 12. 文件浏览器（netrw）
" ====================================================================
" netrw 是 Vim 自带的文件浏览器，:Explore 或 :e . 打开。
" 它的书签和历史默认存在 ~/.vim/.netrwhist，也就是本仓库里。挪到状态目录。
let g:netrw_home = s:state
" 不显示顶部那一大块说明文字，按 I 可以临时调出来。
let g:netrw_banner = 0
