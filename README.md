# Vim 配置

一份不用任何第三方插件的 Vim 配置，和 Neovim 配置（`git@git.utlas.de:eyebrowkang/nvim.git`）
搭配使用。

两边分工不同：Neovim 偏 IDE，功能丰富、样式美观；Vim 只做一个纯粹的编辑器，
要稳定可靠、克隆下来就能用，在任何机器上都表现一致。
所以这里只用 Vim 自带的功能和自带的可选包，没有插件管理器，也不需要联网下载任何东西。

写法沿用 Neovim 配置的风格：按职责拆文件、分节编号、每个配置项都有中文注释，
说明它做什么、为什么这么设。两边共有的行为（按键、选项、文件类型规则）尽量保持一致，
在两个编辑器之间切换时不用换一套手感。

## 环境

| 项 | 值 |
| --- | --- |
| Vim | 以 Debian 13 自带的 9.1.1230 为准。8.0 到 9.0 能正常启动，部分功能不可用，见[低版本兼容](#低版本兼容) |
| 平台 | macOS 与 Linux 通用 |
| 配置路径 | `~/.vim`（Vim 依次找 `~/.vimrc`、`~/.vim/vimrc`，用找到的第一个，所以 `~/.vimrc` 不能存在） |
| 状态数据 | `~/.local/state/vim/`：swap、undo、backup、viminfo、netrw 历史，遵守 `$XDG_STATE_HOME` |
| 字体 | 不需要 Nerd Font |

## 安装

```bash
git clone git@git.utlas.de:eyebrowkang/.vim.git ~/.vim
```

不需要其他步骤。状态目录在第一次启动时自动创建。

### 单文件版（陌生服务器）

CI 会把整个仓库拼成一个独立的 `vimrc`，每次 push 到 `main` 都会更新 S3 public 桶里的
`vim/vimrc`，公开地址是 <https://public.static.utlas.de/vim/vimrc>
（`https://static.utlas.de/public/vim/vimrc` 指向同一个文件）。在服务器上二选一：

```bash
# 长期使用：放成 ~/.vimrc
curl -fsSL https://public.static.utlas.de/vim/vimrc -o ~/.vimrc

# 临时使用：配置文件不落盘，退出就没了（bash / zsh 的进程替换）
vim -u <(curl -fsSL https://public.static.utlas.de/vim/vimrc) 要编辑的文件
```

更新到最新版就是重新执行一遍 curl。上传时设了 5 分钟缓存，刚 push 完可能还拿到旧版，
看文件头的来源 commit 就能分辨。

单文件和仓库是同一份代码：`scripts/bundle-vimrc.sh` 只是把 `vimrc` 里的每一行
`runtime config/xxx.vim` 原地替换成那个文件的内容。文件头写着来源 commit，
`head -5 ~/.vimrc` 就能看到拿到的是哪一版。

注意：

- `~/.vimrc` 优先于 `~/.vim/vimrc`。本机这种克隆了仓库的机器上不要再放 `~/.vimrc`。
- 两种方式都会在 `~/.local/state/vim/` 留下 swap、撤销历史和 viminfo。
  在别人的机器上编辑过敏感文件，用完可以把这个目录删掉。
- `sudo vim` 读的是 root 的配置；`sudoedit` 用的是你自己的，推荐用它编辑系统文件。

本地构建：

```bash
scripts/bundle-vimrc.sh > output/vimrc
```

可选的外部命令，**没有也不影响启动**：

| 命令 | 用途 | 缺了会怎样 |
| --- | --- | --- |
| `rg` | `:grep` 改用 ripgrep | 退回系统的 `grep` |
| `ansible-doc` | Ansible 文件里 `K` 查模块文档 | `K` 退回 `:Man` |
| `base64` | Vim 9.1 之前的版本做 OSC 52 编码 | Vim 9.1 自带编码函数，用不到它 |

## 目录结构

```
~/.vim
├── vimrc                  入口：编码 → 关闭 vi 兼容 → leader → 按顺序加载 config/
├── config/
│   ├── packages.vim       启用 Vim 自带的可选包：matchit、comment、editorconfig、hlyank
│   ├── filetype.vim       文件类型补充规则：Ansible YAML、Jinja 模板、Terraform
│   ├── options.vim        选项、状态栏、配色、filetype 开关
│   ├── ftplugin.vim       按文件类型的局部设置：Ansible 的 gf 路径、K 查文档
│   ├── keymaps.vim        全局按键
│   ├── clipboard.vim      通过 OSC 52 写系统剪贴板，以及 <leader>y 系列按键
│   └── autocmds.vim       自动命令：恢复光标、q 关闭辅助窗口、sops 临时文件保护
├── scripts/
│   ├── bundle-vimrc.sh    拼成单文件版
│   └── test-vimrc.sh      冒烟测试（仓库或单文件）
├── tests/smoke.vim        冒烟测试的检查项
└── .forgejo/workflows/    CI：测试、打包，main 分支上传 S3
```

没有用 Vim 的 `filetype.vim`、`ftplugin/`、`autoload/` 这些约定目录：
单文件版里没有目录，所有代码都由 `vimrc` 显式加载，仓库和单文件才能是同一份代码。

## 加载顺序

```
vimrc
  ├── set encoding=utf-8      # 必须最先：决定后面所有文件里的中文怎么读
  ├── if 1 ... endif          # 没有 +eval 的精简版 Vim 跳过下面全部内容
  │   ├── set nocompatible    # vim -u 启动时 Vim 不会自动关掉 vi 兼容
  │   ├── let g:mapleader     # leader 必须在所有映射之前，全仓库只设这一次
  │   └── runtime config/packages.vim → filetype.vim → options.vim → ftplugin.vim
  │                      → keymaps.vim → clipboard.vim → autocmds.vim
  └── （vimrc 执行完）Vim 加载 packadd! 登记的自带包
```

顺序以 `options.vim` 为界，它里面的 `syntax enable` 和 `filetype plugin indent on`
会启用文件类型识别：

- `packages.vim` 必须在它之前：`packadd!` 只是把包登记进 `'runtimepath'`，
  包里的 ftdetect 规则要求登记发生在 `filetype on` 之前。这和 Neovim 把插件放在最后正好相反。
- `filetype.vim` 必须在它之前：自定义识别规则要比内置规则先注册才能生效。
- `ftplugin.vim` 必须在它之后：局部设置要排在 Vim 自己的 ftplugin 后面执行，
  否则会被当成上一个类型的残留撤销掉。

详见 `vimrc` 第 5 节。

## 按键总览

leader 键是**空格**，和 Neovim 一致。

本配置定义的按键：

| 按键 | 模式 | 用途 |
| --- | --- | --- |
| `<leader>y{motion}` | 普通 | 复制到系统剪贴板（OSC 52），如 `<leader>yiw` |
| `<leader>yy` / `<leader>Y` | 普通 | 复制当前行 / 复制到行尾到系统剪贴板 |
| `<leader>y` | 可视 | 复制选区到系统剪贴板 |
| `<C-方向键>` | 普通 | 调整窗口大小 |
| `J` / `K` | 可视 | 选中的行整块下移 / 上移 |
| `<` / `>` | 可视 | 缩进后保持选中，可以连按 |
| `*` / `#` | 可视 | 向后 / 向前搜索选中的文本（可含空格、符号、跨行） |
| `<C-a>` / `<C-e>` | 插入 | 跳到行首 / 行尾 |
| `q` | help、man、quickfix 窗口 | 关闭窗口 |

和 Neovim 一样、但 Vim 原本没有的按键（Neovim 里是内置的，这里补上）：

| 按键 | 用途 |
| --- | --- |
| `Y` | 复制到行尾（和 `D`、`C` 一致） |
| `<C-l>` | 取消搜索高亮、刷新 diff、重绘屏幕 |
| `&` | 重复上一次 `:s`，带上原来的标志 |
| `<C-u>` / `<C-w>`（插入） | 删除前先断开撤销，按 `u` 只恢复删掉的部分 |
| `[q` `]q` `[Q` `]Q` | quickfix 上一条 / 下一条 / 第一条 / 最后一条 |
| `[l` `]l` `[L` `]L` | location list，同上 |
| `[b` `]b` `[B` `]B` | 缓冲区，同上 |
| `[t` `]t` `[T` `]T` | 标签栈，同上 |
| `[a` `]a` `[A` `]A` | 参数列表，同上 |
| `gc{motion}` / `gcc` / 可视 `gc` | 切换注释（自带 comment 包） |
| `K` | 用 `:Man` 在 Vim 窗口里查手册（Ansible 文件里改用 ansible-doc） |

自带包和 man 插件附带的按键：`%` 在 `if`/`endif` 等配对关键字间跳转（matchit）；
`ic` / `ac` 注释文本对象（comment）；`<leader>K` 查光标下单词的手册（man 插件）。

和 Neovim 不同的地方：

- **没有 `<leader>p` / `<leader>P`**：OSC 52 读剪贴板要终端额外授权，多数终端默认禁止。
  粘贴用终端的粘贴键（Ctrl+Shift+V / Cmd+V）即可，Vim 能识别括号粘贴模式，
  插入模式下粘贴不会被自动缩进打乱。
- **`Q` 保持 Vim 原义**（进入 Ex 模式）：Neovim 的 `Q` 是重放上一个录制的宏，语义不同，没有模拟。

## 系统剪贴板

Debian 的 `vim` 包没有编译 `+clipboard`（`:echo has('clipboard')` 是 0），
`"+` 寄存器不存在，`"+y` 会静默地退化成普通的 `y`。
所以复制走 OSC 52：Vim 往终端输出一段转义序列，由终端把内容放进系统剪贴板。
整条链路在终端里完成，本地、SSH、tmux 里都能用，不需要 xclip 这类外部命令。

需要满足：

- 终端支持 OSC 52：Ghostty、iTerm2、kitty、WezTerm、Windows Terminal 都支持
- 在 tmux 里：`set -g set-clipboard on`

复制成功不会有额外提示；复制了 3 行以上时 Vim 自己会报「N lines yanked」。
如果复制后剪贴板里没有内容，按 Neovim 配置仓库 `docs/clipboard-ssh.md` 的顺序排查，两边是同一套机制。

## Ansible 与 Jinja 模板

规则和 Neovim 配置的 `lua/config/filetype.lua` 相同：

- Ansible 约定目录下的 YAML（`tasks/`、`handlers/`、`group_vars/`、`playbooks/`……）
  识别成 `yaml.ansible`。YAML 的高亮、缩进照常，另外 `gf` 能跳到角色的
  `files/` 和 `templates/`，`K` 用 `ansible-doc` 查模块。
- `nginx.conf.j2` 识别成 `nginx.jinja`：nginx 语法和 Jinja 语法叠加显示。
  认不出底层类型的 `.j2` 就是 `jinja`。
- `.tf` 一律是 `terraform`，空的 `main.tf` 不会被误判成 TinyFugue 脚本。

打开文件后 `:set filetype?` 可以确认识别结果。被误判时用 `:setfiletype yaml` 改回来。

## 低版本兼容

低于 9.1 的 Vim 能正常启动、不报错，缺的功能静默跳过：

| 功能 | 需要的版本 | 更低版本的表现 |
| --- | --- | --- |
| habamax 配色 | 9.0 | 退回 desert |
| comment、editorconfig、hlyank 包 | 9.1 | 没有 `gc` 注释、不读 `.editorconfig`、复制不闪烁 |
| diff 的 linematch | 9.1.1009 | 普通的 diff 对齐 |
| 命令行补全弹出菜单 | 8.2.4325 | 横向的 wildmenu |
| OSC 52 复制 | 8.2.0083 | 提示版本太低，不复制 |
| Jinja 叠加 nginx 语法 | 9.0 | 更早的 Vim 不认识 nginx 文件，`nginx.conf.j2` 只有 Jinja 高亮 |

没有 `+eval` 的精简版（Debian 的 vim-tiny、救援系统里的 vi）会跳过整份配置，退化成干净的 vi。

仓库和单文件版都在这些系统上跑过冒烟测试（`scripts/test-vimrc.sh`）：

| 系统 | Vim |
| --- | --- |
| Rocky Linux 8 | 8.0.1763 |
| Ubuntu 20.04 | 8.1.2269 |
| Rocky Linux 9（`/etc/vimrc` 会提前开启 filetype） | 8.2.2637 |
| Debian 12 | 9.0.1378 |
| Ubuntu 24.04（CI） | 9.1.0016 |
| Debian 13 | 9.1.1230 |

## 约定

- **不用第三方插件**，也不装插件管理器。需要的功能先找 Vim 自带的：
  `$VIMRUNTIME/pack/dist/opt/` 下的可选包、`$VIMRUNTIME/ftplugin/` 里的命令。
  确实需要写的，写在本仓库里，保持几十行以内。IDE 类的功能交给 Neovim。
- **所有配置项必须有注释**，写清楚它做什么、为什么选这个值。刻意不设置的选项也要说明。
  注释只描述当前配置，不记录修改历史，那是 git 的职责。
- **和 Neovim 保持一致**：两边都有的行为（按键、选项、文件类型规则）改一边时，看看另一边是否也要改。
  Vim 和 Neovim 默认值不同的地方，以 Neovim 的为准，在注释里标注「Neovim 默认」。
- **用传统 Vim script 写**，不用 vim9script：前者在 8.x 上也能运行。
  新版本才有的功能用 `exists()`、`has()` 或 `silent!` 兜底。
- **文件头**写明仓库内路径、用途、依赖、按键；内容按编号分节，改编号前先查有没有别处引用。
- **每个含中文的文件都写 `scriptencoding utf-8`**。
- **`config/` 下的文件要能安全地拼接**：单文件版会把它们拼成一个脚本。
  不用 `:finish`，不用 autoload 名字的函数，`s:` 变量和函数名不能和别的文件重复。
- 改完跑一遍测试：

  ```bash
  scripts/test-vimrc.sh                                         # 仓库
  scripts/bundle-vimrc.sh > output/vimrc && scripts/test-vimrc.sh output/vimrc   # 单文件
  ```

## 调试常用命令

```vim
:messages                     " 回看刷过去的消息
:verbose set shiftwidth?      " 查某个选项当前值，以及是被哪个文件设的
:verbose map <leader>y        " 查某个映射是被哪个文件定义的
:scriptnames                  " 列出已加载的所有脚本，确认文件有没有被读到
:set runtimepath?             " 查自带包是否已登记
:echo synIDattr(synID(line('.'), col('.'), 1), 'name')  " 光标处的语法高亮组
```

启动过程排查：

```bash
vim -V15/tmp/vim-debug.log    # 详细的启动日志
vim --startuptime /tmp/vim-startup.log
vim --clean                   # 不加载任何配置，确认问题是不是配置引起的
vim --noplugin                # 加载 vimrc，但不加载插件和自带包
```
