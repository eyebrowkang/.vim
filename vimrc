" vimrc
" Vim 配置总入口。
" 这个文件只做几件事：声明编码 → 关掉 vi 兼容 → 定义 leader 键 → 按顺序加载 config/ 下的模块。
" 具体配置都在 config/ 里，入口保持干净，方便一眼看清加载顺序。
"
" 两种用法，走的是同一份代码：
"   仓库    克隆到 ~/.vim。Vim 按 ~/.vimrc → ~/.vim/vimrc 的顺序找用户配置，
"           用第一个找到的，所以 ~/.vimrc 不能存在。
"   单文件  scripts/bundle-vimrc.sh 把下面每一行 runtime config/xxx.vim
"           原地替换成那个文件的内容，拼成一个独立的 vimrc，放到陌生服务器上用。
"           所以 config/ 下的文件不能依赖「自己是一个单独的文件」，约束见 AGENTS.md。

" ====================================================================
" 1. 编码（必须是第一条有效命令）
" ====================================================================
" encoding 是 Vim 内部表示文字用的编码，它决定了后面每一个脚本里的
" 非 ASCII 字符（中文注释、listchars 里的符号）怎么被读进来。
" 不显式设置时它跟着 locale 走，locale 是 C/POSIX 的环境（比如精简的容器、
" cron 里）会退化成 latin1，后面的符号就全乱了。Neovim 固定是 UTF-8。
set encoding=utf-8

" scriptencoding 告诉 Vim「本文件是用什么编码写的」。
" 每个含非 ASCII 字符的脚本都要写一行，config/ 下的文件也一样。
scriptencoding utf-8

" 没有 source defaults.vim：Vim 只在找不到用户 vimrc 时才加载它。
" 它设置的那些选项（incsearch、scrolloff、wildmenu……）在
" config/options.vim 里都逐条写明了，不靠它兜底，每一项为什么这么设才查得到。

" ====================================================================
" 2. 精简版 Vim 的保护
" ====================================================================
" Debian 的 vim-tiny、各种救援系统里的 vi 都没有 +eval，
" 不认识 let、function 这些命令，读到本配置会满屏报错。
" 没有 +eval 时，Vim 会跳过 if 和 endif 之间的全部内容（:help no-eval-feature）。
" 所以下面整段都包在 if 1 里：完整版 Vim 照常执行，精简版直接跳过，
" 什么都不加载，退化成一个干净的 vi。
if 1

  " ==================================================================
  " 3. 关掉 vi 兼容模式
  " ==================================================================
  " 'compatible' 开着时 Vim 尽量模仿老 vi：不认识行尾续行的 \、
  " 没有多级撤销……本配置的大部分写法都会报错。
  " 作为 ~/.vimrc 或 ~/.vim/vimrc 被找到时，Vim 会自动关掉它；
  " 但用 vim -u 文件 启动时**不会**（:help compatible-default），
  " 而 vim -u <(curl ...) 正是单文件版在陌生服务器上的用法之一。
  " 只在确实开着时才关：set nocompatible 会把一大批选项重置成 Vim 默认值，
  " 已经是 nocompatible 时再执行一次没有好处。
  if &compatible
    set nocompatible
  endif

  " ==================================================================
  " 4. Leader 键声明（必须早于任何按键映射）
  " ==================================================================
  " <leader> 在「定义映射的那一刻」就被解析成具体按键并写死，
  " 之后再改 mapleader 也不会回头修正已经定义好的映射。
  " 顺序搞反的结果是：所有 <leader> 映射都会变成默认的反斜杠 \ 触发。
  " 全仓库只在这里设置一次，和 Neovim 配置保持一致。
  let g:mapleader = ' '
  let g:maplocalleader = ' '

  " ==================================================================
  " 5. 加载核心模块
  " ==================================================================
  " :runtime 在 'runtimepath' 里查找文件，所以仓库放在 ~/.vim 还是
  " ~/.config/vim 都能找到，不用写死绝对路径。
  "
  " 顺序以 options.vim 为界，它里面的 syntax enable 和 filetype plugin indent on
  " 会启用文件类型识别、注册加载 ftplugin 的自动命令：
  "   packages.vim  必须在它之前。packadd! 只是把包登记进 'runtimepath'，
  "                 包里的 ftdetect 规则要求登记发生在 filetype on 之前（:help packadd）。
  "                 这一点和 Neovim 把插件放在最后正好相反。
  "   filetype.vim  必须在它之前。自定义识别规则要比内置规则先注册才能生效，
  "                 内置规则就是在 filetype on 时注册的。
  "   ftplugin.vim  必须在它之后。局部设置要排在 Vim 自己的 ftplugin 后面执行，
  "                 原因见该文件开头。
  " 按键、剪贴板、自动命令三者互不依赖，顺序只是为了好读。
  runtime config/packages.vim
  runtime config/filetype.vim
  runtime config/options.vim
  runtime config/ftplugin.vim
  runtime config/keymaps.vim
  runtime config/clipboard.vim
  runtime config/autocmds.vim

endif
