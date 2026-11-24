" tests/smoke.vim
" 冒烟测试：在已加载配置的 Vim 里检查关键行为，结果逐行写进 $SMOKE_OUT。
" 依赖：由 scripts/test-vimrc.sh 准备好的 $FIXTURES 目录和环境变量，不要直接运行。
"
" 每条检查写一行 ok 或 FAIL，脚本最后写 done。
" 只检查 Vim 8.0 及以上都应该成立的行为；只在新版本上才有的功能按版本判断。
scriptencoding utf-8

let s:out = []

function! s:Check(name, ok, detail) abort
  call add(s:out, (a:ok ? 'ok   ' : 'FAIL ') . a:name . (a:ok ? '' : '  -- ' . a:detail))
endfunction

" ====================================================================
" 1. 启动
" ====================================================================
" silent! 兜底的失败会写进 v:errmsg 但不会显示，老版本上有是正常的。
" 只在目标版本（Debian 13 的 9.1.1230）及以上检查：那里每个功能都应该存在。
if has('patch-9.1.1230')
  call s:Check('启动无报错', v:errmsg ==# '', v:errmsg)
endif
let s:msgs = filter(split(execute('messages'), "\n"), 'v:val =~# ''\<E\d\+:''')
call s:Check('消息里没有错误', empty(s:msgs), string(s:msgs))
call s:Check('nocompatible', !&compatible, '&compatible=' . &compatible)
let s:want_colors = v:version >= 900 ? 'habamax' : 'desert'
call s:Check('配色', get(g:, 'colors_name', '') ==# s:want_colors, get(g:, 'colors_name', ''))
call s:Check('状态目录', &directory ==# $HOME . '/.local/state/vim/swap//', &directory)
call s:Check('leader 映射', maparg('<Space>y', 'n') =~# 'VimrcOsc52Operator', maparg('<Space>y', 'n'))

" ====================================================================
" 2. 文件类型
" ====================================================================
let g:smoke_filetype_events = 0
augroup smoke
  autocmd!
  autocmd FileType * let g:smoke_filetype_events += 1
augroup END

for [s:file, s:want] in [
      \ ['roles/web/tasks/main.yml', 'yaml.ansible'],
      \ ['group_vars/all.yml', 'yaml.ansible'],
      \ ['site.yml', 'yaml.ansible'],
      \ ['meta/runtime.yml', 'yaml'],
      \ ['plain.yml', 'yaml'],
      \ ['app.py.j2', 'python.jinja'],
      \ ['group_vars/all.yml.j2', 'yaml.jinja'],
      \ ['foo.j2', 'jinja'],
      \ ['main.tf', 'terraform'],
      \ ]
  let g:smoke_filetype_events = 0
  execute 'edit ' . fnameescape($FIXTURES . '/' . s:file)
  call s:Check('filetype ' . s:file, &filetype ==# s:want && g:smoke_filetype_events == 1,
        \ &filetype . ' FileType×' . g:smoke_filetype_events)
endfor

" Ansible 局部设置：gf 路径、撤销清单
execute 'edit ' . fnameescape($FIXTURES . '/roles/web/tasks/main.yml')
call s:Check('ansible path', &l:path =~# 'roles/web/files' && &l:path =~# '^\.,,', &l:path)
call s:Check('ansible undo', get(b:, 'undo_ftplugin', '') =~# 'path<', get(b:, 'undo_ftplugin', ''))
set filetype=yaml
call s:Check('ansible 撤销后 path 恢复', &path !~# 'roles/web/files', &path)

" ====================================================================
" 3. 按键
" ====================================================================
execute 'edit ' . fnameescape($FIXTURES . '/text.txt')

" OSC 52：无名寄存器要有内容；终端输出由 test-vimrc.sh 检查。
" 没有 echoraw()（8.2.0083 之前）时配置只提示版本太低，告诉 test-vimrc.sh 跳过输出检查。
call feedkeys("gg0\<Space>yiw", 'xt')
call s:Check('<leader>yiw', @" ==# 'hello', @")
if !exists('*echoraw')
  call add(s:out, 'skip-osc52')
endif

" 可视 *：按字面搜索选区，并且不改动无名寄存器。
let @" = 'KEEP'
call feedkeys("gg0wv6l*", 'xt')
call s:Check('可视 * 模式', @/ ==# '\Vfoo.bar', @/)
call s:Check('可视 * 位置', line('.') == 3, 'line ' . line('.'))
call s:Check('可视 * 不改寄存器', @" ==# 'KEEP', @")

" 插入 <C-a> / <C-e>
call feedkeys("2G05li\<C-a>A\<C-e>Z\<Esc>", 'xt')
call s:Check('插入 <C-a>/<C-e>', getline(2) ==# '  Asecond lineZ', getline(2))

" ====================================================================
" 4. sops 临时文件（放在最后：它会清空全局的 viminfo）
" ====================================================================
execute 'edit ' . fnameescape($SOPS_FILE)
call s:Check('sops 无 swap', !&l:swapfile, '&swapfile=' . &l:swapfile)
call s:Check('sops 无 undofile', !&l:undofile, '&undofile=' . &l:undofile)
call s:Check('sops 无 viminfo', &viminfo ==# '', &viminfo)

call add(s:out, 'done')
call writefile(s:out, $SMOKE_OUT)
qall!
