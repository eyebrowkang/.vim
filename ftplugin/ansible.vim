" ftplugin/ansible.vim
" 只对 Ansible 的 YAML 生效的局部设置。
" 依赖：可选的 ansible-doc 命令（K 查模块文档）。
" 按键：gf 跳到 files/ 和 templates/ 下的文件；K 查光标下的模块。
"
" ftplugin/ 是 Vim 的约定：缓冲区的 filetype 定下来之后，
" Vim 会在 'runtimepath' 里找 ftplugin/<类型>.vim 并执行。
" 这里所有设置都必须是**缓冲区局部**的（setlocal），否则打开一个 Ansible 文件
" 就会把设置泄漏到之后打开的所有文件上。
"
" 复合类型会逐段加载：filetype.vim 产生的 yaml.ansible 会先执行
" Vim 自带的 ftplugin/yaml.vim（缩进和注释符），再执行本文件。
" 所以这里不检查 b:did_ftplugin：yaml 那份已经设过它了，检查的话本文件永远不会执行。
"
" b:undo_ftplugin 是配套的约定：文件类型被改掉时（:setfiletype yaml）
" Vim 会执行这个字符串里的命令，把本文件做的改动撤销回去。
scriptencoding utf-8

" ====================================================================
" 1. gf 跳到 files/ 和 templates/
" ====================================================================
" Ansible 的 task 里引用文件只写文件名，不写路径：
"     - ansible.builtin.template:
"         src: nginx.conf.j2          ← 实际在 <角色>/templates/nginx.conf.j2
"     - ansible.builtin.copy:
"         src: id_rsa.pub             ← 实际在 <角色>/files/id_rsa.pub
" gf（跳到光标下的文件）查的是 'path' 选项，把这两个目录加进去就能直接跳过去。
"
" 只有身处 tasks/ 或 handlers/ 时，上一级才是角色根目录，src: 也只会出现在这两处。
let s:dir = expand('%:p:h')
if fnamemodify(s:dir, ':t') =~# '^\%(tasks\|handlers\)$'
  let s:role = fnamemodify(s:dir, ':h')
  " 追加而不是覆盖：全局值 ".,," 里的当前文件目录和当前工作目录也都还有用。
  " 'path' 是「全局-局部」选项，缓冲区局部值一开始是空的（表示沿用全局值），
  " 所以要从 &path（当前生效的值）出发拼接，再写进局部值 &l:path。
  " 直接往 &l:path 后面追加会得到 ",<目录>"，全局值就丢了。
  " escape 是必需的：'path' 用逗号分隔、空格另有含义，路径里有空格不转义就会被切开。
  for s:sub in ['/files', '/templates']
    let &l:path = &path . ',' . escape(s:role . s:sub, ' ,\')
  endfor
  unlet s:role s:sub
endif
unlet s:dir

" ====================================================================
" 2. K 用 ansible-doc 查模块文档
" ====================================================================
" 'keywordprg' 是「按 K 时把光标下的词交给谁去查」，全局设成了 :Man。
" 在 Ansible 文件里换成 ansible-doc。值以冒号开头表示一条 Ex 命令：
" :terminal 开一个分屏终端跑它，++close 表示按 q 退出分页器后自动关掉这个窗口。
" 没有 +terminal 的 Vim 直接调用外部命令，暂时切出全屏显示。
" 没装 ansible 时保持全局设置，K 至少还能查 man。
"
" 没有把 . 加进 'iskeyword'：那样 K 能抓到 ansible.builtin.copy 这样的全名，
" 但同一个选项也决定 w / b / * 的词边界，整篇文件的光标移动都会变样。
" ansible-doc 认短名字，光抓到 copy 也查得出来。
if executable('ansible-doc')
  if has('terminal')
    setlocal keywordprg=:terminal\ ++close\ ansible-doc
  else
    setlocal keywordprg=ansible-doc
  endif
endif

" ====================================================================
" 撤销清单
" ====================================================================
" setlocal 选项< 表示恢复成全局值。前面 ftplugin/yaml.vim 已经写过一份，
" 所以要接在后面而不是覆盖掉；只在确实已有内容时才加 | 分隔符。
let s:undo = 'setlocal path< keywordprg<'
let b:undo_ftplugin = exists('b:undo_ftplugin') && b:undo_ftplugin !=# ''
      \ ? b:undo_ftplugin . ' | ' . s:undo
      \ : s:undo
unlet s:undo
