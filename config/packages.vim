" config/packages.vim
" 启用 Vim 自带的可选包（$VIMRUNTIME/pack/dist/opt/）。
" 依赖：无。这些包随 Vim 一起安装，不需要下载，也不算第三方插件。
" 按键：gc{motion} / gcc / 可视 gc 注释；文本对象 ic / ac；% 在配对关键字间跳转。
"
" 本配置不使用任何第三方插件，也不装插件管理器：Vim 的定位是一个
" 克隆下来就能用、在任何机器上表现都一样的纯编辑器。IDE 类的功能交给 Neovim。
"
" packadd! 带感叹号：只把包加进 'runtimepath'，等 vimrc 执行完、
" Vim 进入正常的插件加载阶段时，再和其他插件一起加载（:help load-plugins）。
" 好处是 vim --noplugin 能把它们和其他插件一起跳过，排查问题时有用。
" 这也是本文件要在 filetype on 之前加载的原因，见 vimrc 第 5 节。
"
" 每个包都是 Vim 某个版本之后才有的，版本更老时 packadd 会报 E919；
" 8.0 之前连 packadd 命令都没有，报的是 E492。
" silent! 让这两种情况都静默失败：少了这个功能，其他一切照常。
" 不用 if !has('packages') | finish | endif 提前返回：单文件版里本文件被拼进
" 一个大文件，finish 会把后面的全部配置一起跳过。
scriptencoding utf-8

" ====================================================================
" 1. matchit：% 在配对的关键字之间跳转
" ====================================================================
" 原生的 % 只认括号。matchit 让它也认 if / else / endif、
" HTML 的 <div> / </div>、shell 的 case / esac 等。
" Neovim 默认就加载了它，Vim 要手动启用。
silent! packadd! matchit

" ====================================================================
" 2. comment：gc 注释切换（Vim 9.1 起自带）
" ====================================================================
" 和 Neovim 内置的注释按键相同：
"   gcc       注释 / 取消注释当前行（可以带数字：3gcc）
"   gc{motion} 对一个范围操作，比如 gcap 注释整段、gcj 注释两行
"   gc        可视模式下对选区操作
" 另外提供文本对象 ic / ac（注释的内部 / 整体），比如 dac 删掉一整块注释。
" 注释符号取自各语言 ftplugin 设置的 'commentstring'。
silent! packadd! comment

" ====================================================================
" 3. editorconfig：读取项目的 .editorconfig（Vim 9.1 起自带）
" ====================================================================
" 项目根目录放一个 .editorconfig，缩进、编码、行尾、行宽就自动生效。
" Neovim 默认开启，Vim 要手动启用。和 Neovim 一样，这是项目级配置的首选方式。
"
" 行为差异：.editorconfig 里写了 max_line_length 时，Vim 版本除了设置
" 'textwidth'，还会用 'colorcolumn' 画一条竖线标出行宽，Neovim 版本只设 textwidth。
" 保留这个默认行为，提醒行宽在哪里是有用的。
silent! packadd! editorconfig

" ====================================================================
" 4. hlyank：复制时高亮被复制的区域（Vim 9.1 起自带）
" ====================================================================
" 让刚复制的文本闪一下，明确告诉你「刚才到底复制了哪些内容」。
" 对应 Neovim 配置里调用 vim.hl.on_yank() 的那条自动命令。
"   hlyank_hlgroup   用哪个高亮组来闪。IncSearch 是增量搜索的高亮，够醒目（默认值）
"   hlyank_duration  持续毫秒数。默认 300，这里和 Neovim 配置一致用 150，大约一眨眼
let g:hlyank_hlgroup = 'IncSearch'
let g:hlyank_duration = 150
silent! packadd! hlyank

" ====================================================================
" 没有启用的自带包
" ====================================================================
"   nohlsearch  停止移动光标一段时间后自动取消搜索高亮。和 Neovim 的习惯不同，
"               那边是按 <C-l> 手动取消，这里也一样（config/keymaps.vim 第 4 节）
"   cfilter     :Cfilter 过滤 quickfix 列表。需要时 :packadd cfilter 临时加载
"   netrw       不在这里：它是默认加载的 start 包，不需要 packadd
"   termdebug   在 Vim 里调试 gdb 程序，属于 IDE 功能，交给 Neovim
