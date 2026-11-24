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
| Vim | 以 Debian 13 自带的 9.1.1230 为准。8.2 和 9.0 能正常启动，部分功能不可用，见[低版本兼容](#低版本兼容) |
| 平台 | macOS 与 Linux 通用 |
| 配置路径 | `~/.vim`（Vim 依次找 `~/.vimrc`、`~/.vim/vimrc`，用找到的第一个，所以 `~/.vimrc` 不能存在） |
| 状态数据 | `~/.local/state/vim/`：swap、undo、backup、viminfo、netrw 历史，遵守 `$XDG_STATE_HOME` |
| 字体 | 不需要 Nerd Font |

## 安装

```bash
git clone git@git.utlas.de:eyebrowkang/.vim.git ~/.vim
```

不需要其他步骤。状态目录在第一次启动时自动创建。

可选的外部命令，**没有也不影响启动**：

| 命令 | 用途 | 缺了会怎样 |
| --- | --- | --- |
| `rg` | `:grep` 改用 ripgrep | 退回系统的 `grep` |
| `ansible-doc` | Ansible 文件里 `K` 查模块文档 | `K` 退回 `:Man` |
| `base64` | Vim 9.1 之前的版本做 OSC 52 编码 | Vim 9.1 自带编码函数，用不到它 |

## 目录结构

```
~/.vim
├── vimrc                  入口：编码 → leader → 按顺序加载 config/
├── config/
│   ├── packages.vim       启用 Vim 自带的可选包：matchit、comment、editorconfig、hlyank
│   ├── options.vim        选项、状态栏、配色、filetype 开关
│   ├── keymaps.vim        全局按键
│   └── autocmds.vim       自动命令：恢复光标、q 关闭辅助窗口、sops 临时文件保护
├── filetype.vim           文件类型补充规则：Ansible YAML、Jinja 模板、Terraform
├── ftplugin/
│   └── ansible.vim        Ansible 文件的局部设置：gf 路径、K 查文档
└── autoload/vimrc/
    └── osc52.vim          通过 OSC 52 写系统剪贴板，第一次用到时才加载
```

`filetype.vim`、`ftplugin/`、`autoload/` 都是 Vim 的约定目录，Vim 会在需要时自己去找，
不需要在 `vimrc` 里引用。

## 加载顺序

```
vimrc
  ├── set encoding=utf-8      # 必须最先：决定后面所有文件里的中文怎么读
  ├── if 1 ... endif          # 没有 +eval 的精简版 Vim 跳过下面全部内容
  │   ├── let g:mapleader     # leader 必须在所有映射之前，全仓库只设这一次
  │   └── runtime config/packages.vim → options.vim → keymaps.vim → autocmds.vim
  └── （vimrc 执行完）Vim 加载 packadd! 登记的自带包和 plugin/
```

`packages.vim` 排在最前面，和 Neovim 把插件放在最后正好相反：
`packadd!` 只是把包登记进 `'runtimepath'`，而包里的 ftdetect 规则要求登记发生在
`filetype on` 之前，`filetype on` 写在 `options.vim` 里。详见 `vimrc` 第 4 节。

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
- 插入模式的 `<C-a>` / `<C-e>` 是这边独有的。

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

没有 `+eval` 的精简版（Debian 的 vim-tiny、救援系统里的 vi）会跳过整份配置，退化成干净的 vi。

已在 Vim 8.2.3995（Ubuntu 22.04）、9.0.1378（Debian 12）、9.1.1230（Debian 13）上验证过启动和 OSC 52 复制。

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
