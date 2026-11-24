" config/autocmds.vim
" 自动命令：在 Vim 触发某个事件时自动执行一段逻辑。
" 依赖：无。
" 按键：help / quickfix / man 窗口里的 q（缓冲区局部）。
"
" 写法：每组自动命令放在一个 augroup 里，开头先 autocmd! 清空这个组。
" 这样重新 :source 本文件时，同一条自动命令不会被重复注册成好几份。
" 事件列表见 :help autocmd-events。
"
" 复制高亮没有写在这里：它由 Vim 自带的 hlyank 包提供（config/packages.vim）。
scriptencoding utf-8

" ====================================================================
" 1. 打开文件时恢复上次光标停留的位置
" ====================================================================
" '" 是 Vim 自动维护的标记：上次离开这个文件时光标所在的位置。
" 它存放在 viminfo 文件里，所以重启之后依然有效。
"
" 跳过的情况：
"   gitcommit / gitrebase  每次都应该从第一行开始写，上次的位置没有意义
"   buftype 非空           终端、帮助、quickfix 这类特殊缓冲区
"   标记越界               文件在外部被截短了，上次的行号已经不存在
" g`" 跳过去但不记入跳转列表；zv 是落点正好在折叠里时把折叠展开。
function! s:RestoreCursor() abort
  if &filetype =~# '^git\%(commit\|rebase\)$' || &buftype !=# ''
    return
  endif
  let l:line = line("'\"")
  if l:line >= 1 && l:line <= line('$')
    execute 'normal! g`"zv'
  endif
endfunction

augroup vimrc_restore_cursor
  autocmd!
  autocmd BufReadPost * call s:RestoreCursor()
augroup END

" ====================================================================
" 2. 辅助窗口按 q 直接关闭
" ====================================================================
" 查看帮助文档、man 手册、quickfix 时，按 q 就能关掉，不用敲 :q<CR>。
"   nobuflisted  从 :ls / :bnext 的列表里摘掉，别污染缓冲区切换
"   <buffer>     映射只对这个缓冲区生效，不影响别处的 q（录制宏）
augroup vimrc_close_with_q
  autocmd!
  autocmd FileType help,man,qf
        \ setlocal nobuflisted |
        \ nnoremap <buffer> <silent> q :close<CR>
augroup END

" ====================================================================
" 3. sops edit 的临时文件：不留明文痕迹
" ====================================================================
" `sops edit secrets.enc.yaml` 的流程是：把内容解密到一个临时文件，
" 用 $EDITOR 打开它，编辑器退出后重新加密写回原文件，再删掉临时文件。
" sops 只管删它自己的临时文件，管不着 Vim 另外写到别处的东西。
" 本配置默认会在这几个地方留下明文：
"   swap         编辑期间持续写进状态目录的 swap/，崩溃后残留
"   undofile     每次 :w 把整棵撤销树写进 undo/，永不删除
"   writebackup  保存时临时复制一份到 backup/，正常情况写完即删，崩溃时残留
"   viminfo      复制/删除过的寄存器内容、搜索和命令历史，退出时写盘
" 所以识别出这类缓冲区后，把它们都关掉。
"
" 识别靠路径：sops 的临时文件固定是 <临时目录>/<一串数字>/<原文件名>，
" 比如 /tmp/1434508211/secrets.enc.yaml。那串数字是 Go 的 os.MkdirTemp
" 生成的随机目录名。临时目录 sops 取的是 $TMPDIR，没有就是 /tmp。
" 误判的代价只是某个文件没有 swap 和撤销历史，所以宁可宽一点。
" 和 Neovim 配置里的同名规则保持一致。
function! s:IsSopsTempfile(path) abort
  let l:tmpdir = empty($TMPDIR) ? '/tmp' : substitute($TMPDIR, '/\+$', '', '')
  " macOS 的 $TMPDIR 在 /var/folders/... 下，而 /var 是 /private/var 的软链接。
  " 两种写法都可能出现在缓冲区名里，所以两个都比一下。
  for l:dir in [l:tmpdir, resolve(l:tmpdir)]
    " stridx 做纯字符串的前缀比较，避免临时目录里的 . 之类被当成正则符号。
    if stridx(a:path, l:dir . '/') == 0 && a:path[len(l:dir) + 1 :] =~# '^\d\+/[^/]\+$'
      return 1
    endif
  endfor
  return 0
endfunction

" 必须是 BufReadPre：这时文件内容还没读进来，swap 文件里也还没有任何内容。
" 等到 BufReadPost 再关，明文可能已经进过一次 swap。
function! s:ProtectSopsTempfile() abort
  if !s:IsSopsTempfile(expand('<afile>:p'))
    return
  endif
  " 这两个是缓冲区局部选项，只影响这个文件。
  setlocal noswapfile noundofile
  " writebackup 和 viminfo 是全局选项，没法只排除一个文件，只能整个进程都关掉。
  " 可以接受：sops edit 会为这个文件单独启动一个 Vim，退出就结束，
  " 代价只是这一次会话的历史和寄存器不保存。
  set nowritebackup
  set viminfo=
endfunction

augroup vimrc_sops_tempfile
  autocmd!
  autocmd BufReadPre * call s:ProtectSopsTempfile()
augroup END

" ====================================================================
" 4. 切回 Vim 时检查文件是否在外部被改过
" ====================================================================
" 'autoread' 只决定「发现外部改动后要不要自动重读」，它不会自己去发现。
" Neovim 在获得焦点时会检查一次，Vim 要靠下面这条：
" 从别的 tmux 窗格、别的终端标签切回来时（FocusGained），
" 以及切换缓冲区时（BufEnter），执行一次 :checktime。
" FocusGained 需要终端支持焦点事件，tmux 里还要 set -g focus-events on。
" silent! 是因为命令行窗口（q:）里不允许执行 :checktime，会报 E11。
augroup vimrc_checktime
  autocmd!
  autocmd FocusGained,BufEnter * silent! checktime
augroup END
