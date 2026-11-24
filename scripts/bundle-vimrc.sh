#!/bin/bash
# 把仓库组合成一个独立的 vimrc 单文件，用于陌生服务器上快速取用。
# 用法：scripts/bundle-vimrc.sh > output/vimrc
#
# 做法和 vimrc 的约定一一对应：vimrc 里每一行 `runtime config/xxx.vim`
# 原地替换成 config/xxx.vim 的内容，其他行原样输出。
# 所以仓库和单文件走的是同一份代码，测仓库就等于测单文件。
# config/ 下的文件要能被安全地拼接，约束见 AGENTS.md。
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
VIMRC="$REPO_ROOT/vimrc"

# 来源版本写进文件头，服务器上 head 一下就知道拿到的是哪一版。
# CI 里由 workflow 传入 12 位 commit；本地构建时从 git 读取，有未提交改动会标上 -dirty。
REVISION=${BUNDLE_REVISION:-$(git -C "$REPO_ROOT" describe --always --dirty 2>/dev/null || echo unknown)}
# 发布地址只用来填文件头的用法说明。CI 从仓库变量 VIMRC_URL 传入，没有就留占位符。
URL=${BUNDLE_URL:-<地址>}

inline_config() {
    local name="$1"
    local path="$REPO_ROOT/config/$name"

    if [ ! -f "$path" ]; then
        echo "ERROR: $path not found" >&2
        exit 1
    fi
    # finish 会结束「当前脚本」。拼成单文件后，当前脚本就是整个 vimrc，
    # 一个文件里的提前返回会把后面所有配置都跳过。
    if grep -nE '^[[:space:]]*fini(sh)?([[:space:]]|$)' "$path" >&2; then
        echo "ERROR: config/$name uses :finish, which would end the whole bundle" >&2
        exit 1
    fi

    echo ""
    echo "\" ####################################################################"
    echo "\" config/$name"
    echo "\" ####################################################################"
    # scriptencoding 在文件开头声明一次就够了，vimrc 自己那一行会保留。
    sed '/^scriptencoding /d' "$path"
}

cat <<EOF
" Vim 配置（单文件版）
" 由 scripts/bundle-vimrc.sh 从 git@git.utlas.de:eyebrowkang/.vim.git 生成，不要直接修改。
" 来源版本：$REVISION
"
" 用法：
"   curl -fsSL $URL -o ~/.vimrc
"       长期使用。~/.vimrc 优先于 ~/.vim/vimrc，原来的配置会被盖过。
"   vim -u <(curl -fsSL $URL) 文件
"       临时使用，配置文件不落盘（bash / zsh 的进程替换）。
" 两种方式都会创建 ~/.local/state/vim/，存放 swap、撤销历史和 viminfo。

EOF

while IFS= read -r line; do
    if [[ "$line" =~ ^[[:space:]]*runtime[[:space:]]+config/([A-Za-z0-9_.-]+\.vim)[[:space:]]*$ ]]; then
        inline_config "${BASH_REMATCH[1]}"
        continue
    fi
    if [[ "$line" =~ ^[[:space:]]*runtime ]]; then
        echo "ERROR: unsupported runtime line in vimrc: $line" >&2
        exit 1
    fi
    printf '%s\n' "$line"
done < "$VIMRC"
