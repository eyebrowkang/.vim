" vimrc
" Vim 配置总入口。
" 这个文件只做三件事：声明编码 → 定义 leader 键 → 按顺序加载 config/ 下的模块。
" 具体配置都在 config/ 里，入口保持干净，方便一眼看清加载顺序。
"
" Vim 按 ~/.vimrc → ~/.vim/vimrc → ~/.config/vim/vimrc 的顺序找用户配置，
" 用第一个找到的。本仓库克隆到 ~/.vim 即可生效，前提是 ~/.vimrc 不存在。

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

" 没写 set nocompatible：只要 Vim 找到了用户 vimrc（或用 -u 指定了文件），
" 就会自动关掉 compatible。在这里再写一遍，反而会把已经设好的选项重置一次。

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
  " 3. Leader 键声明（必须早于任何按键映射）
  " ==================================================================
  " <leader> 在「定义映射的那一刻」就被解析成具体按键并写死，
  " 之后再改 mapleader 也不会回头修正已经定义好的映射。
  " 顺序搞反的结果是：所有 <leader> 映射都会变成默认的反斜杠 \ 触发。
  " 全仓库只在这里设置一次，和 Neovim 配置保持一致。
  let g:mapleader = ' '
  let g:maplocalleader = ' '

  " ==================================================================
  " 4. 加载核心模块
  " ==================================================================
  " 顺序：自带的可选包 → 选项 → 按键 → 自动命令。
  " :runtime 在 'runtimepath' 里查找文件，所以仓库放在 ~/.vim 还是
  " ~/.config/vim 都能找到，不用写死绝对路径。
  "
  " 可选包排在最前面，和 Neovim 把插件放在最后正好相反，原因是两边机制不同：
  " packadd! 并不加载插件，只是把包登记进 'runtimepath'，
  " 真正的加载由 Vim 在 vimrc 执行完之后统一进行。而包里的 ftdetect 规则
  " 要求登记发生在 filetype on 之前（:help packadd），
  " filetype on 写在 options.vim 里，所以 packages.vim 必须先于它。
  "
  " 文件类型识别规则不在这里加载：filetype.vim 在仓库根目录，
  " options.vim 执行 filetype on 时 Vim 会自动读它。
  runtime config/packages.vim
  runtime config/options.vim
  runtime config/keymaps.vim
  runtime config/autocmds.vim

endif
