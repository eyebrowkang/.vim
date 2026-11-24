" autoload/vimrc/osc52.vim
" 通过 OSC 52 转义序列把文本写进系统剪贴板。
" 依赖：终端支持 OSC 52（Ghostty、iTerm2、kitty、WezTerm、Windows Terminal 等都支持）；
"       在 tmux 里还需要 set -g set-clipboard on。
" 按键：在 config/keymaps.vim 第 3 节定义，本文件只提供函数。
"
" 原理：程序往终端输出一段 ESC ] 52 ; c ; <base64 内容> BEL，
" 终端收到后把解码出的内容放进系统剪贴板。整条链路都是终端在处理，
" 所以 SSH 到远端机器里也一样能复制到本地：远端的 Vim 只是在往屏幕上打字。
" tmux 开了 set-clipboard 后会接住这段序列，存进自己的缓冲区并转发给外层终端。
" 完整的链路和排查方法见 Neovim 配置仓库的 docs/clipboard-ssh.md，两边是同一套机制。
"
" autoload 的意思是：Vim 启动时不读这个文件，
" 第一次调用 vimrc#osc52#... 函数时才按函数名找到并加载它（:help autoload）。
" 函数名里的 vimrc# 是目录、osc52# 是文件名，必须和路径对应。
" 没有直接叫 osc52#：Vim 9.1 后来的版本自带一个同名的 osc52 包，避免冲突。
scriptencoding utf-8

" ====================================================================
" 1. 发送
" ====================================================================
" lines：字符串列表，每项是一行。多行之间用换行连接，最后一行后面不加换行。
" 刻意不给整行复制补结尾换行：复制一条命令粘贴进 shell 时，
" 结尾带换行会让它直接执行，没有机会再看一眼。
function! vimrc#osc52#Copy(lines) abort
  " 没有 echoraw()（8.2.0083 之前）就没有办法绕过 Vim 的屏幕绘制直接写终端。
  if !exists('*echoraw')
    echohl ErrorMsg | echomsg 'OSC 52 复制需要 Vim 8.2 或更新的版本' | echohl None
    return
  endif

  " base64 编码。Vim 9.1 自带 base64_encode()，其他版本调用系统的 base64 命令：
  " macOS 和 Linux 的 base64 输出都会每 76 列折一次行，用 tr 去掉换行就是同一结果。
  if exists('*base64_encode') && exists('*str2blob')
    let l:encoded = base64_encode(str2blob(a:lines))
  else
    let l:encoded = system('base64 | tr -d "\n"', join(a:lines, "\n"))
    if v:shell_error
      echohl ErrorMsg | echomsg 'OSC 52 复制失败：base64 命令出错' | echohl None
      return
    endif
  endif

  " \e]52;c; 开头，\x07（BEL）结尾。c 表示写入系统剪贴板（clipboard）。
  " echoraw 原样输出，不经过 Vim 的屏幕刷新，也不会在屏幕上留下痕迹。
  call echoraw("\e]52;c;" . l:encoded . "\x07")
endfunction

" ====================================================================
" 2. 操作符（让 <leader>y 能接任意动作）
" ====================================================================
" Vim 自定义操作符的标准写法（:help :map-operator）：
"   不带参数调用时  设置 'operatorfunc' 并返回 g@，这次按键就变成「等一个动作」
"   带参数调用时    Vim 在动作完成后回调本函数，参数是动作的类型
" 这样 <leader>yiw、<leader>yap、<leader>y3j 都能用，而且 . 能重复。
function! vimrc#osc52#Operator(...) abort
  if a:0 == 0
    set operatorfunc=vimrc#osc52#Operator
    return 'g@'
  endif

  " '[ 和 '] 两个标记是动作覆盖范围的起点和终点。
  " 按动作类型重新选中这一段并复制：line 是整行、block 是列块、char 是普通字符范围。
  " selection 临时改成 inclusive，保证终点那个字符也被包含进来。
  let l:saved_selection = &selection
  let &selection = 'inclusive'
  try
    if a:1 ==# 'line'
      normal! '[V']y
    elseif a:1 ==# 'block'
      execute "normal! `[\<C-v>`]y"
    else
      normal! `[v`]y
    endif
  finally
    let &selection = l:saved_selection
  endtry

  call vimrc#osc52#Copy(getreg('"', 1, 1))
endfunction
