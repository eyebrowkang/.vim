#!/bin/bash
# 冒烟测试：在隔离的 HOME 里启动 Vim，跑 tests/smoke.vim，检查结果和 OSC 52 输出。
# 用法：
#   scripts/test-vimrc.sh              测试仓库本身（仓库链接成隔离 HOME 下的 ~/.vim）
#   scripts/test-vimrc.sh output/vimrc 测试打包出的单文件，三种启动方式各跑一遍：
#                                      ~/.vimrc、vim -u <(cat 文件)、系统 vimrc 已开 filetype
# 依赖：vim、util-linux 的 script（提供伪终端，Vim 的终端行为才和真实使用一致）、base64。
# 只支持 Linux：macOS 的 script 参数不同。
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
BUNDLE=${1:-}
if [ -n "$BUNDLE" ]; then
    BUNDLE=$(cd "$(dirname "$BUNDLE")" && pwd)/$(basename "$BUNDLE")
fi

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# ---- 测试用的文件 ----
export FIXTURES="$WORK/fixtures"
mkdir -p "$FIXTURES"/roles/web/{tasks,files,templates} "$FIXTURES"/group_vars "$FIXTURES"/meta
touch "$FIXTURES"/roles/web/tasks/main.yml "$FIXTURES"/group_vars/all.yml "$FIXTURES"/group_vars/all.yml.j2 \
    "$FIXTURES"/site.yml "$FIXTURES"/meta/runtime.yml "$FIXTURES"/plain.yml "$FIXTURES"/foo.j2 "$FIXTURES"/main.tf
printf 'print("{{ name }}")\n' > "$FIXTURES/app.py.j2"
printf 'hello foo.bar world\n  second line\nx foo.bar y\n' > "$FIXTURES/text.txt"

# sops 的临时文件长这样：<临时目录>/<一串数字>/<原文件名>
export TMPDIR="$WORK/tmp"
mkdir -p "$TMPDIR/1434508211"
export SOPS_FILE="$TMPDIR/1434508211/secrets.enc.yaml"
printf 'a: 1\n' > "$SOPS_FILE"

export TERM=xterm-256color COLORTERM=truecolor
unset XDG_STATE_HOME VIMINIT

failed=0

# run_case <名字> <在伪终端里执行的命令>
run_case() {
    local name="$1" cmd="$2"
    export HOME="$WORK/home-$name" SMOKE_OUT="$WORK/$name.out"
    mkdir -p "$HOME"
    case "$name" in
        repo) ln -s "$REPO_ROOT" "$HOME/.vim" ;;
        home | system-filetype) cp "$BUNDLE" "$HOME/.vimrc" ;;
    esac

    # timeout：配置出错时 Vim 会停在 Press ENTER 提示上，不加超时就会一直卡住。
    if ! timeout 60 script -qec "$cmd" "$WORK/$name.raw" < /dev/null > /dev/null; then
        echo "FAIL [$name] vim 没有正常退出（报错提示卡住，或超时）"
        failed=1
        return
    fi
    if [ ! -f "$SMOKE_OUT" ] || ! grep -qx 'done' "$SMOKE_OUT"; then
        echo "FAIL [$name] smoke.vim 没有跑完"
        failed=1
        return
    fi
    grep -vxE 'done|skip-osc52' "$SMOKE_OUT" | sed "s/^/[$name] /" || true
    if grep -q '^FAIL' "$SMOKE_OUT"; then
        failed=1
    fi
    if grep -qx 'skip-osc52' "$SMOKE_OUT"; then
        echo "[$name] skip OSC 52 输出（Vim 低于 8.2，配置不支持）"
        return
    fi

    # OSC 52：终端输出里要有一段 ESC ] 52 ; c ; <base64>，解码后是 smoke.vim 复制的 hello。
    local copied
    copied=$(grep -aoE $'\e\\]52;c;[A-Za-z0-9+/=]*' "$WORK/$name.raw" | head -1 | sed 's/.*;c;//' | base64 -d 2> /dev/null || true)
    if [ "$copied" = hello ]; then
        echo "[$name] ok   OSC 52 输出"
    else
        echo "[$name] FAIL OSC 52 输出  -- 解码结果：'$copied'"
        failed=1
    fi
}

SMOKE="$REPO_ROOT/tests/smoke.vim"
cd "$FIXTURES"
vim --version | grep -E "^(VIM - |Included patches)"
if [ -z "$BUNDLE" ]; then
    run_case repo "vim -S '$SMOKE'"
else
    run_case home "vim -S '$SMOKE'"
    run_case dash-u "bash -c \"vim -u <(cat '$BUNDLE') -S '$SMOKE'\""
    # RHEL 系的 /etc/vimrc 会在用户配置之前执行 filetype on 和 syntax on，--cmd 模拟这一步。
    run_case system-filetype "vim --cmd 'filetype plugin indent on' --cmd 'syntax on' -S '$SMOKE'"
fi

if [ "$failed" -ne 0 ]; then
    echo "冒烟测试失败"
    exit 1
fi
echo "冒烟测试通过"
