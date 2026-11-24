" config/keymaps.vim
" 全局快捷键。
" 依赖：autoload/vimrc/osc52.vim（第 3 节的系统剪贴板）。
" 按键：<C-方向键> 调整窗口；可视 J/K/</>；<leader>y/yy/Y；
"       插入 <C-a>/<C-e>；可视 * / #；对齐 Neovim 默认的 Y、<C-l>、&、
"       插入 <C-u>/<C-w>、[q ]q 等方括号系列。
"
" 映射命令的写法：
"   nnoremap / xnoremap / inoremap  分别是普通 / 可视 / 插入模式，
"   noremap 表示不递归：右边的按键按 Vim 原本的含义执行，不会再触发别的映射。
"   <silent> 不在命令行回显执行的命令。
" 用 "x" 系列而不是 "v" 系列：v 同时包含 Select 模式，
" 在 Select 模式下按可打印字符应当是「替换选中内容」，不该被映射劫持。
"
" 保持克制：Vim 自带的按键能做到的就不再映射一遍（:help index 列出全部内置按键）。
scriptencoding utf-8

" ====================================================================
" 1. 窗口尺寸调整
" ====================================================================
" 用 Ctrl + 方向键调整分屏大小，和 Neovim 配置相同。
" 选 Ctrl 而不是 Alt：Alt 在终端里的传递最不可靠，Ctrl + 方向键各终端表现一致。
nnoremap <silent> <C-Up> :resize +2<CR>
nnoremap <silent> <C-Down> :resize -2<CR>
nnoremap <silent> <C-Left> :vertical resize -2<CR>
nnoremap <silent> <C-Right> :vertical resize +2<CR>

" ====================================================================
" 2. 可视模式增强
" ====================================================================
" 整块上下移动选中的行
"   :m '>+1  把选区移动到「选区最后一行的下一行」之后
"   gv       重新选中刚才那块（:m 之后选区会丢失）
"   =        对选区重新做一次自动缩进
xnoremap <silent> J :m '>+1<CR>gv=gv
xnoremap <silent> K :m '<-2<CR>gv=gv

" 连续缩进：缩进后自动重新选中，可以连着按 < 或 >
xnoremap < <gv
xnoremap > >gv

" ====================================================================
" 3. 系统剪贴板（OSC 52）
" ====================================================================
" 和 Neovim 配置的按键完全相同，用法和原生的 y / yy / Y 一一对应：
"   <leader>y{motion}  复制一个范围，如 <leader>yiw、<leader>yap
"   <leader>yy         复制当前行（可以带数字：3<leader>yy 复制 3 行）
"   <leader>Y          复制到行尾
"   <leader>y          在可视模式下 = 复制选中区域
" 内容会进 Vim 的无名寄存器（p 能粘贴），同时通过 OSC 52 交给终端写进系统剪贴板。
"
" 为什么不能直接写成 "+y：这个 Vim 没有 +clipboard，见 config/options.vim 第 7 节。
" 实现在 autoload/vimrc/osc52.vim，第一次按下时才加载。
"
" 没有映射 <leader>p / <leader>P：OSC 52 读剪贴板需要终端额外授权，
" 多数终端默认禁止（防止程序偷看剪贴板）。粘贴请用终端的粘贴键。
nnoremap <expr> <leader>y vimrc#osc52#Operator()
nnoremap <expr> <leader>yy vimrc#osc52#Operator() . '_'
nnoremap <expr> <leader>Y vimrc#osc52#Operator() . '$'
xnoremap <silent> <leader>y y:<C-u>call vimrc#osc52#Copy(getreg('"', 1, 1))<CR>

" ====================================================================
" 4. 插入模式下跳到行首 / 行尾
" ====================================================================
" Emacs 风格，shell 和大多数输入框里也是这两个键。
" 代价：覆盖了 Vim 内置的 i_CTRL-A（再插入一次上次输入的内容）
" 和 i_CTRL-E（插入下一行同一列的字符），这两个日常几乎用不到。
"   <C-o>^  临时回到普通模式执行一次 ^（行首第一个非空字符），然后回到插入模式
"   <End>   直接移到行尾
" 两者都不会结束这次插入，所以 . 重复和 u 撤销仍然把整次输入算作一个动作。
inoremap <C-a> <C-o>^
inoremap <C-e> <End>

" ====================================================================
" 5. 对齐 Neovim 的默认映射
" ====================================================================
" 下面这些在 Neovim 里是开箱自带的（:help default-mappings），Vim 没有。
" 补上它们，两个编辑器之间切换时手指不用换一套习惯。

" Y 复制到行尾，和 D、C 保持一致。Vim 原本的 Y 等于 yy，是历史遗留。
nnoremap Y y$

" <C-l> 重绘屏幕时顺便取消搜索高亮、刷新 diff。
" 搜索完满屏黄色时按一下就清掉，下次搜索又会亮。
nnoremap <silent> <C-l> :nohlsearch<Bar>diffupdate<CR><C-l>

" & 重复上一次 :s 替换，并且带上当时的标志（比如 g）。
" Vim 原本的 & 会丢掉标志，上次是 :s/a/b/g，这次就只替换一个。
nnoremap & :&&<CR>

" 插入模式下 <C-u>（删到行首）和 <C-w>（删掉前一个词）之前先断开撤销序列。
" 不断开的话，删错了按 u 会把这次插入的内容全部撤销，而不只是恢复删掉的那段。
inoremap <C-u> <C-g>u<C-u>
inoremap <C-w> <C-g>u<C-w>

" 方括号系列：[ 往前、] 往后，第二个键决定在什么列表里跳。
"   q  quickfix（:grep、:make 的结果）    l  location list
"   b  缓冲区                             t  标签栈        a  参数列表
" 小写跳一条（可以带数字，3]q 往后跳 3 条），大写跳到第一条 / 最后一条。
" 用循环生成，是因为五组映射的形状完全相同，逐行写出来反而看不出规律。
for [s:key, s:prev, s:next, s:first, s:last] in [
      \ ['q', 'cprevious', 'cnext', 'cfirst', 'clast'],
      \ ['l', 'lprevious', 'lnext', 'lfirst', 'llast'],
      \ ['b', 'bprevious', 'bnext', 'bfirst', 'blast'],
      \ ['t', 'tprevious', 'tnext', 'tfirst', 'tlast'],
      \ ['a', 'previous', 'next', 'first', 'last'],
      \ ]
  " v:count1 是按键前输入的数字，没输入时为 1。
  execute printf("nnoremap <silent> [%s :<C-u>execute v:count1 . '%s'<CR>", s:key, s:prev)
  execute printf("nnoremap <silent> ]%s :<C-u>execute v:count1 . '%s'<CR>", s:key, s:next)
  execute printf("nnoremap <silent> [%s :<C-u>%s<CR>", toupper(s:key), s:first)
  execute printf("nnoremap <silent> ]%s :<C-u>%s<CR>", toupper(s:key), s:last)
endfor
unlet s:key s:prev s:next s:first s:last

" 没有补的 Neovim 默认映射：
"   gc / gcc 注释   由 Vim 自带的 comment 包提供（config/packages.vim 第 2 节）
"   Q               Neovim 里是「重放上一个录制的宏」，Vim 里是进入 Ex 模式。
"                   两者语义不同，用 @@ 模拟会在细节上不一致，不如不碰
"   [d ]d <C-w>d    诊断跳转，Vim 里没有语言服务器
"   [<Space>        在上方 / 下方插入空行，用 o<Esc> / O<Esc> 即可

" ====================================================================
" 6. 可视模式下 * / # 搜索选中的文本
" ====================================================================
" Neovim 0.10 起内置了这个行为，Vim 里可视模式的 * 只是「搜索光标下的词」。
" 选中一段任意文本（可以带空格、符号、跨行），按 * 向后找、按 # 向前找。
"
" 实现：先把选区复制出来拼成搜索模式，再用 // 发起一次搜索。
"   \V      very nomagic，后面除了反斜杠全部按字面匹配，不用逐个转义 . * [ 等
"   escape  只需要转义反斜杠和搜索方向的分隔符（/ 或 ?）
"   \n      跨行选区的换行要写成 \n 才能匹配
" 用 // 而不是 /<CR>：后者会沿用上一次搜索的偏移量（比如 /foo/e），
" 前者明确表示「不带偏移」。
function! s:VisualSearch(cmdtype) abort
  " 复制会覆盖无名寄存器，用完要还原，不能让 * 偷偷改掉你等下要粘贴的内容。
  let l:saved = getreg('"', 1, 1)
  let l:saved_type = getregtype('"')
  " noautocmd：这次复制只是中间步骤，不要触发 hlyank 的闪烁。
  noautocmd normal! gvy
  let l:lines = map(getreg('"', 1, 1), {_, line -> escape(line, a:cmdtype . '\')})
  call setreg('"', l:saved, l:saved_type)
  let @/ = '\V' . join(l:lines, '\n')
  " 加进搜索历史，之后在 / 里按上箭头能找回来，和普通搜索一样。
  call histadd(a:cmdtype, @/)
endfunction

xnoremap <silent> * :<C-u>call <SID>VisualSearch('/')<CR>//<CR>
xnoremap <silent> # :<C-u>call <SID>VisualSearch('?')<CR>??<CR>
