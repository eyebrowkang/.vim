# AGENTS.md

## Contract

- Audience: coding agents. Use terse technical English.
- Treat other repository files as human-facing. Use concise Chinese for prose
  and Vim script comments.
- User instructions override this file. Record only durable repository rules.
- Goal: a plain, stable editor config that works right after `git clone` into
  `~/.vim`. Every configuration choice has an explainable purpose and trade-off.
- Target: Debian 13 Vim 9.1.1230 (`-clipboard`, `+terminal`, Huge). Must start
  without visible errors on 8.0+ (servers: RHEL 8 ships 8.0) and skip
  everything on `-eval` builds.
- Two delivery forms, one code path: the repo cloned to `~/.vim`, and a
  single-file `vimrc` built by `scripts/bundle-vimrc.sh` for unfamiliar servers
  (`~/.vimrc` or `vim -u <(curl ...)`). CI publishes it from `main`.
- Companion repo: `~/.config/nvim` (Neovim, IDE-like). Shared behavior (keymaps,
  options, filetype rules, sops protection) mirrors it; read its `AGENTS.md`
  and the corresponding file before changing shared behavior.

## Hard rules

- No third-party plugins, no plugin manager, no vendored colorschemes, no
  network at startup. Use `$VIMRUNTIME/pack/dist/opt/*` packages and runtime
  ftplugins first; keep any hand-written helper small.
- Legacy Vim script only, not `vim9script` (8.x compatibility). Guard newer
  features with `exists('*fn')`, `exists('+opt')`, `has()`, or `silent!`.
- Every file with non-ASCII text starts with `scriptencoding utf-8`.
- State lives under `${XDG_STATE_HOME:-~/.local/state}/vim/`; never write
  swap/undo/backup/viminfo/netrw files into the repository.
- Where Vim and Neovim defaults differ, follow Neovim and mark it
  「Neovim 默认」 in the comment.

## Startup

Keep `vimrc` in this order:

1. `set encoding=utf-8` then `scriptencoding utf-8`.
2. Everything else inside `if 1 ... endif` (skipped by `-eval` builds).
3. `if &compatible | set nocompatible | endif`: `vim -u FILE` does not reset
   `compatible`, and line continuations break without it.
4. `g:mapleader` / `g:maplocalleader` = space, only here, before any map.
5. `runtime config/packages.vim -> filetype.vim -> options.vim -> ftplugin.vim
   -> keymaps.vim -> clipboard.vim -> autocmds.vim`. `options.vim` runs
   `syntax enable` + `filetype plugin indent on`:
   - `packages.vim` before it: `packadd!` must precede `filetype on` for
     package ftdetect scripts.
   - `filetype.vim` before it: custom `setfiletype` rules must be registered
     before the built-in ones. It runs `filetype off` first when a system vimrc
     already enabled detection (RHEL `/etc/vimrc`).
   - `ftplugin.vim` after it: its `FileType` autocmds must run after Vim's
     ftplugin loader, which executes the previous `b:undo_ftplugin` and would
     otherwise undo them.

No Vim convention directories (root `filetype.vim`, `ftplugin/`, `autoload/`,
`plugin/`): the bundle has no directories, so `vimrc` loads all code explicitly.

## Bundle constraints

`scripts/bundle-vimrc.sh` replaces each `runtime config/<name>.vim` line with
the file content and drops `scriptencoding` lines. Every `config/*.vim` must be
safe to concatenate into one script:

- No `:finish` (it would end the whole bundle); the script rejects it.
- No autoload-named functions (`foo#bar()`): defining them outside their
  autoload file is E746. Use prefixed globals (`VimrcOsc52Copy`) when
  `'operatorfunc'` needs them (s: functions fail there before 8.2.3619);
  otherwise `s:` functions.
- `s:` variables and functions must be unique across all config files;
  `unlet` temporary `s:` variables.
- Only `runtime config/...` lines in `vimrc`; other `runtime` lines are rejected.

## Cross-file contracts

- `config/filetype.vim` mirrors nvim `lua/config/filetype.lua`: Ansible paths
  -> `yaml.ansible`; `.j2`/`.jinja2` -> base type's first component + `.jinja`
  via `doautocmd filetypedetect BufRead <base>` with `FileType` in
  `eventignore`; `.tf` -> `terraform`.
- `config/ftplugin.vim` mirrors nvim `ftplugin/*.lua` as `FileType` autocmds
  (pattern `ansible,*.ansible`); buffer-local only; append to
  `b:undo_ftplugin`. `'path'` is global-local: build from `&path`, write
  `&l:path`.
- Vim lacks `+clipboard`; `"+y` silently degrades to `y` and `TextYankPost`
  reports `regname ''`. `<leader>y` uses `VimrcOsc52Operator()` (opfunc) in
  `config/clipboard.vim`. Do not add `<leader>p`.
- Visual `*`/`#` yank with `noautocmd` so hlyank does not flash; restore `"`.
- sops tempfile protection (`config/autocmds.vim` section 3) must stay on
  `BufReadPre` and disable swap, undofile, writebackup, viminfo.

## Validation

```bash
shellcheck scripts/*.sh
scripts/test-vimrc.sh                   # repo, linked as an isolated ~/.vim
scripts/bundle-vimrc.sh > output/vimrc
scripts/test-vimrc.sh output/vimrc      # bundle: ~/.vimrc, vim -u <(...), pre-enabled filetype
```

- `scripts/test-vimrc.sh` runs Vim under `script` (pty) in an isolated `HOME`
  with fixtures, executes `tests/smoke.vim`, and checks OSC 52 output in the raw
  pty log. Add a check to `tests/smoke.vim` for every behavior change; gate
  version-dependent expectations (`has('patch-...')`, `exists('*fn')`).
- A visible error leaves Vim at a hit-enter prompt; the 60 s `timeout` turns
  that into a failure.
- Older Vim, same script, repo mounted read-only:

  ```bash
  docker run --rm -v ~/.vim:/repo:ro rockylinux:8 bash -c \
    'dnf install -y vim-enhanced util-linux >/dev/null && cd /tmp && /repo/scripts/test-vimrc.sh'
  ```

  Images: `rockylinux:8` (8.0), `ubuntu:20.04` (8.1), `rockylinux:9` (8.2, real
  `/etc/vimrc` enables filetype), `debian:bookworm` (9.0), `ubuntu:24.04`
  (9.1.0016, CI). `debian:bullseye` security repo is gone.
- `-eval`: `vim.tiny -u ~/.vim/vimrc` must show no errors.
- Rendering: `tmux -L <sock> new-session -d -x 100 -y 12 vim ...`, then
  `tmux -L <sock> capture-pane -p`.

## CI and publishing

- `.forgejo/workflows/vimrc.yml`: every push runs shellcheck, repo test,
  bundle, bundle test; `main` also uploads `output/vimrc` to
  `s3://$S3_BUCKET/vim/vimrc` (`text/plain`, `max-age=300`).
- Repo settings required: Actions enabled; variables `S3_ENDPOINT`,
  `S3_BUCKET`, `VIMRC_URL` (public URL, only fills the bundle header); secrets
  `S3_ACCESS_KEY`, `S3_SECRET_KEY`. Never handle the secret values locally.

## Docs

- `README.md` owns environment, layout, single-file usage, keymap tables,
  compatibility table, conventions. Update it with any keymap/option/compat
  change.
- File header: repository-relative path, purpose, dependencies, keymaps.
  Numbered sections; check references (`第 N 节`) before renumbering.
- Comments describe current state, not history; prose near 80 columns.
