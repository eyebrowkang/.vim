" config/filetype.vim
" 文件类型识别的补充规则：Ansible 的 YAML、Jinja 模板、Terraform。
" 依赖：无。识别规则和 Neovim 配置的 lua/config/filetype.lua 是同一套。
" 识别出类型之后的局部设置在 config/ftplugin.vim。
"
" 「文件类型」（filetype）是 Vim 给缓冲区贴的一个标签，语法高亮、缩进规则、
" ftplugin 里的局部设置都挂在它上面。识别错了，后面全是错的。
"
" 自查某个文件会被识别成什么：打开它之后 :set filetype?
scriptencoding utf-8

" ====================================================================
" 1. 注册时机
" ====================================================================
" 识别规则就是 BufNewFile / BufRead 自动命令，同一个事件的自动命令按注册顺序执行。
" 内置规则在 filetype on 时注册，下面的规则要排在它们前面，
" 并且用 setfiletype：它只在类型还没定下来时才生效。我们先定了，
" 后面内置的「*.yml → yaml」再 setfiletype 就不起作用。
"
" 所以 vimrc 在 options.vim（里面有 syntax enable 和 filetype on）之前加载本文件。
" 但有的系统级 vimrc（比如 RHEL 系的 /etc/vimrc）在用户配置之前就已经
" 执行过 filetype on 了。这时先关掉，等 options.vim 再打开，内置规则就会重新注册在后面。
" 只在确实开着时才关：从没开过的话，:filetype off 会报 E216。
if exists('did_load_filetypes')
  filetype off
endif

" 规则必须注册在 filetypedetect 组里：下面第 3 节的 :doautocmd filetypedetect
" 只会执行这个组里的规则。
" 代价：手动执行 :filetype off 会清空这个组，之后再 :filetype on，
" 这里的规则就没了，重启 Vim 即可恢复。日常不会这么操作。
augroup filetypedetect

" ====================================================================
" 2. Ansible 的 YAML
" ====================================================================
" Ansible 的 playbook、task、变量文件全是 .yml，光看扩展名分不出来。
" Ansible 自己靠**目录约定**认文件，这里把那套约定翻译成文件类型。
"
" 目标类型是带点号的复合类型 yaml.ansible：Vim 会依次加载 yaml 和 ansible
" 两份 ftplugin、两份语法文件。YAML 的高亮、缩进照常，
" config/ftplugin.vim 再加上 Ansible 特有的那部分。
"
" 自动命令的模式是文件通配符，不是正则：* 能匹配包括 / 在内的任意字符，
" {yml,yaml} 表示两者之一。模式里有 / 时，匹配的是完整路径。
"
" 角色（role）的目录结构。不带 roles/ 前缀，是为了同时覆盖仓库里的角色
" （<项目>/roles/<角色名>/tasks/main.yml）和独立的角色仓库（<仓库>/tasks/main.yml）。
" 代价是非 Ansible 项目里恰好有 tasks/ 或 defaults/ 目录装着 YAML 时会被误判，
" 遇到了就在那个文件里 :setfiletype yaml 改回来。
autocmd BufNewFile,BufRead */tasks/*.{yml,yaml},*/handlers/*.{yml,yaml} setfiletype yaml.ansible
autocmd BufNewFile,BufRead */defaults/*.{yml,yaml},*/vars/*.{yml,yaml} setfiletype yaml.ansible
" 角色的元数据只认 main.yml：collection 的 meta/runtime.yml 是另一套格式。
autocmd BufNewFile,BufRead */meta/main.{yml,yaml} setfiletype yaml.ansible
" 剧本（playbook）：放在 playbooks/ 里、文件名以 playbook 开头、约定俗成的 site.yml
autocmd BufNewFile,BufRead */playbook/*.{yml,yaml},*/playbooks/*.{yml,yaml} setfiletype yaml.ansible
autocmd BufNewFile,BufRead playbook*.{yml,yaml},site.{yml,yaml} setfiletype yaml.ansible
" 清单变量和 YAML 格式的清单。.ini 格式的清单由内置规则识别成 dosini，不用管。
autocmd BufNewFile,BufRead */group_vars/*.{yml,yaml},*/host_vars/*.{yml,yaml} setfiletype yaml.ansible
autocmd BufNewFile,BufRead */inventory/*.{yml,yaml},*/inventories/*.{yml,yaml} setfiletype yaml.ansible
" molecule 的测试场景，整个目录都是 playbook 和 task
autocmd BufNewFile,BufRead */molecule/*.{yml,yaml} setfiletype yaml.ansible

" ====================================================================
" 3. Jinja 模板（.j2 / .jinja2）
" ====================================================================
" Ansible 的模板是「底层语言 + Jinja 语法」的混合体：nginx.conf.j2 里
" 既有 nginx 的配置语法，又有 {{ 变量 }} 和 {% for %}。
" 内置识别对 .j2 没有规则，这类文件是**没有文件类型**的裸文本。
"
" 做法是两层都保住：去掉 .j2 后缀，回头问一次「剩下的部分是什么类型」，
" 把结果和 jinja 拼成复合类型，比如 nginx.conf.j2 → nginx.jinja。
" Vim 自带的 syntax/jinja.vim 本来就是设计成叠加用的：只要前一层不是 jinja，
" 它就在已有的语法上继续添加，效果是底层语法和 Jinja 语法同时有色。
function! s:JinjaOverBase(path) abort
  " :r 去掉最后一级扩展名。nginx.conf.j2 → nginx.conf，main.yml.j2 → main.yml
  let l:base = fnamemodify(a:path, ':p:r')

  " 「剩下的部分是什么类型」靠的是把识别规则对着 base 这个名字重跑一遍，
  " Vim 内置的 *.bak、*~ 这类后缀也是这么处理的。
  " 跑的时候屏蔽 FileType 事件：这一步只是为了读出结果，
  " 不能让 nginx 的 ftplugin 和语法文件先被加载一遍。
  " 少数内置规则会读文件内容来判断，这时读到的是 .j2 文件本身，结果仍然可用。
  let l:saved_ei = &eventignore
  set eventignore+=FileType
  try
    execute 'doautocmd filetypedetect BufRead ' . fnameescape(l:base)
  finally
    let &eventignore = l:saved_ei
  endtry

  " 只取底层类型的第一段。底层自己也可能是复合类型：上面那组规则会把
  " group_vars/all.yml.j2 的底层判成 yaml.ansible，直接拼就成了三段。
  " 而且一个还没渲染的模板，本来也不该被当成 Ansible 文件。
  let l:ft = matchstr(&filetype, '^[^.]*')

  " 底层认不出来（foo.j2），或者是 foo.j2.j2 这种怪东西，就退回单纯的 jinja。
  " 用 let &filetype 而不是 setfiletype：上面那一步已经把类型设成了底层类型，
  " setfiletype 看到「已经设过」就不会再改了。
  let &filetype = (l:ft ==# '' || l:ft ==# 'jinja') ? 'jinja' : l:ft . '.jinja'
endfunction

" 内置已经有 *.jinja → jinja，但没有 .j2 和 .jinja2。
autocmd BufNewFile,BufRead *.j2,*.jinja2 call s:JinjaOverBase(expand('<afile>'))

" ====================================================================
" 4. Terraform（.tf）
" ====================================================================
" 内置规则里 .tf 有歧义：它同时是 TinyFugue（一个 MUD 客户端）的脚本后缀。
" 内置的判断办法是读文件内容，空文件或只写了注释的 main.tf 会被判成 tf。
" 这台机器上不会有 TinyFugue 脚本，所以直接把 .tf 钉死为 terraform。
" .tfvars 内置已经认成 terraform-vars，不用管。
autocmd BufNewFile,BufRead *.tf setfiletype terraform

augroup END
