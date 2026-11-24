# AGENTS.md

## Contract

- Audience: coding agents. Use terse technical English.
- Treat other repository files as human-facing. Use concise Chinese for prose
  and Vim script comments.
- User instructions override this file. Record only durable repository rules.
- Goal: a plain, stable editor config that works right after `git clone` into
  `~/.vim`. Every configuration choice has an explainable purpose and trade-off.
- Target: Debian 13 Vim 9.1.1230 (`-clipboard`, `+terminal`, Huge). Must start
  without visible errors on 8.2+ and skip everything on `-eval` builds.
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
3. `g:mapleader` / `g:maplocalleader` = space, only here, before any map.
4. `runtime config/packages.vim -> options.vim -> keymaps.vim -> autocmds.vim`.
   `packages.vim` must precede `options.vim`: `packadd!` must happen before
   `filetype on` / `syntax enable` for package ftdetect scripts.

Convention-loaded files, never sourced from `vimrc`: `filetype.vim` (sourced by
`filetype on` before `$VIMRUNTIME/filetype.vim`; use `setfiletype`),
`ftplugin/*.vim`, `autoload/vimrc/*.vim` (namespace `vimrc#`; avoid bare
`osc52#`, which collides with Vim's later bundled package).

## Cross-file contracts

- `filetype.vim` mirrors nvim `lua/config/filetype.lua`: Ansible paths ->
  `yaml.ansible`; `.j2`/`.jinja2` -> base type's first component + `.jinja`
  via `doautocmd filetypedetect BufRead <base>` with `FileType` in
  `eventignore`; `.tf` -> `terraform`.
- `ftplugin/ansible.vim`: runs after `ftplugin/yaml.vim`; do not check
  `b:did_ftplugin`; buffer-local only; append to `b:undo_ftplugin`.
  `'path'` is global-local: build from `&path`, write `&l:path`.
- Vim lacks `+clipboard`; `"+y` silently degrades to `y` and `TextYankPost`
  reports `regname ''`. `<leader>y` uses `vimrc#osc52#Operator()` (opfunc).
  Do not add `<leader>p`.
- Visual `*`/`#` yank with `noautocmd` so hlyank does not flash; restore `"`.
- sops tempfile protection (`config/autocmds.vim` section 3) must stay on
  `BufReadPre` and disable swap, undofile, writebackup, viminfo.

## Validation

No test framework or linter. Run Vim in a pty with an isolated state dir and
write results to a file (`-es` skips terminal behavior):

```bash
export XDG_STATE_HOME=/tmp/vt/state
cat > /tmp/vt/smoke.vim <<'EOF'
call writefile(['err=[' . v:errmsg . ']', execute('messages')], '/tmp/vt/smoke.out')
qa!
EOF
COLORTERM=truecolor TERM=tmux-256color script -qc 'vim -S /tmp/vt/smoke.vim' /dev/null >/dev/null
cat /tmp/vt/smoke.out
```

- `v:errmsg` may contain expected `silent!` failures only on older Vim.
- Keys: `call feedkeys("\<Space>yiw", 'xt')` inside the `-S` script.
- OSC 52: `script -q -c '...' out.raw`, then
  `grep -aoE $'\e\\]52;c;[A-Za-z0-9+/=]*' out.raw` and base64-decode.
- Filetypes: `:edit` sample paths, assert `&filetype`, count `FileType` events.
- `-eval`: `vim.tiny -u ~/.vim/vimrc` must show no errors.
- Older Vim: `docker run` with `ubuntu:22.04` (8.2) or `debian:bookworm`
  (9.0), mount `~/.vim` read-only. `debian:bullseye` security repo is gone.
- Rendering: `tmux -L <sock> new-session -d -x 100 -y 12 vim ...`, then
  `tmux -L <sock> capture-pane -p`.

## Docs

- `README.md` owns environment, layout, keymap tables, compatibility table,
  conventions. Update it with any keymap/option/compat change.
- File header: repository-relative path, purpose, dependencies, keymaps.
  Numbered sections; check references (`第 N 节`) before renumbering.
- Comments describe current state, not history; prose near 80 columns.
