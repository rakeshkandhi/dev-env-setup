# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased] - 2026-08-19 01:29:00 +0530

### Added
- **Yank git branch** (`Ctrl-a g`, `tmux/tmux.conf`): copies the git branch of the active pane's directory to the system clipboard and the tmux paste buffer, with a status-line confirmation. 
- **Yank current path** (`Ctrl-a y`): tmux-yank's path yank moved from `Y` to `y`, replacing its command-line yank.
- **`.env` → Shell Filetype** (`~/.config/nvim/lua/config/autocmds.lua`): Added autocmd so `.env`, `.env.local`, `.env.production`, `.env.development`, etc. open with `sh` filetype — enabling `bashls` LSP, Treesitter shell highlighting, `conform.nvim` formatting, `shellcheck` linting, and correct `#` comments.

### Fixed
- **Stale statusline pinned to an old theme** (`scripts/setup_tmux.sh`, `~/.config/nvim/lua/config/pack.lua`): running sessions kept showing the pre-`82abb12` status bar (time, date, hostname) no matter how often `tmux.conf` was re-sourced. `vim-tpipeline`'s `g:tpipeline_restore` snapshots `status-left`/`status-right` when Neovim starts and writes the snapshot back on exit with `tmux set` — no `-g`, so it lands as a *session-local* option that shadows the global one this config sets. Restore is now off (the theme already renders Neovim's statusline via `#{pane_title}`), and `setup_tmux.sh` clears any leftover session-local values, skipping sessions where Neovim is currently running.
- **Clipboard now works over SSH** (`scripts/tmux_copy.sh`, `tmux/tmux.conf`): yanking used to fail with `xclip: Can't open display` on a headless or SSH session — `Ctrl-a g` surfaced it as a `returned 1` error, while copy-mode `y` and `Ctrl-a y` failed silently. Every copy now goes through one helper that writes the tmux buffer and emits an OSC 52 escape sequence (reaching the clipboard of the machine you're sitting at), then falls back to a native tool only when a display is actually reachable.
- **`scripts/setup_nvim.sh`** — `install.sh` no longer fails at "Setup Neovim Config" when `~/.config/nvim` has local changes (typically `lazy-lock.json` after a plugin update): the pull now uses `--autostash` and reports a clear error if it still cannot rebase.

### Changed
- **`tmux/tmux.conf`** — Clipboard command (`pbcopy` / `xclip`) is now stored once in the `@clipboard` user option and shared by all clipboard bindings.
- **`SHORTCUTS.md`** — Restored and fully expanded with all previously missing shortcuts:
  - Dashboard startup keys (`u`, `f`, `r`, `t`)
  - `which-key` popup (`Space ?` and any `Space` prefix)
  - `Alt-Shift-F` manual format + auto-format-on-save table (per language)
  - Auto-lint triggers and per-filetype linter list
  - Treesitter-aware comment shortcuts (`gcc`, `gc`, `gcA`, `gco`, `gcO`)
  - fzf `Ctrl-u` / `Ctrl-d` preview scroll
  - Full config behaviours table (relative numbers, `scrolloff`, persistent undo, smart search, `auto_install`, `.env` filetype, trackpad scroll)
- **`EXTENSIONS.md`** — Gap-filled with accurate, config-sourced details:
  - Added `mason-tool-installer.nvim` row (auto-installs `stylua`, `prettier`, `ruff`, `eslint_d`, `cspell`)
  - Updated `mason-lspconfig.nvim` row with actual server list
  - Updated `conform.nvim` row with actual formatters per filetype
  - Updated `nvim-lint` row with actual linters per filetype
  - Updated `nvim-ts-context-commentstring` row with concrete shortcut examples

---

## [Unreleased / Pending Changes] - 2026-08-19 01:10:00 +0530

### Added
- **Starship Prompt Support (Linux)**: Added `scripts/setup_starship.sh` and Catppuccin Mocha prompt theme `starship/starship.toml`. Symlinks configuration to `~/.config/starship.toml`.
- **fzf Integration & Helper Utilities**:
  - `vf`: Fuzzy-find files with live preview (`bat` or `cat`) and open selection in Neovim.
  - `fcd`: Fuzzy-find directories with `ls -la` preview and auto-cd.
  - `fkill`: Interactive fuzzy process selector with multi-kill capabilities.
  - Tab completion for `cd **` and `kill **`.
  - Custom Catppuccin Mocha palette formatting for fzf UI.
- **Master Installer (`install.sh`) Integration**: Fully integrated `starship` into `install.sh` with `--only starship`, `--no-starship`, and `--skip-starship` support.
- **Changelog & Version Logging**: Created `CHANGELOG.md` to track repository release history, changes, and timestamps.
- **Extension & Plugin Architecture Guide**: Created [`EXTENSIONS.md`](file:///Users/rakeshkandhi/code/personal/dev-env-setup/EXTENSIONS.md) documenting all installed Tmux & Neovim plugins, workflow benefits, and inter-tool efficiency synergies.
- **Tmux Sessionizer Workflow Utility**: Added [`scripts/tmux_sessionizer.sh`](file:///Users/rakeshkandhi/code/personal/dev-env-setup/scripts/tmux_sessionizer.sh) (`ta` shell alias & `Ctrl-a f` in tmux) for zero-keystroke fuzzy switching between project sessions.

### Changed
- **Linux Distribution Detection (`scripts/detect_os.sh`)**: Enhanced Linux distro resolution to auto-detect Ubuntu derivatives (Pop!_OS, Linux Mint, Elementary OS, Zorin OS, KDE Neon, etc.) via `/etc/os-release` `ID` and `ID_LIKE` scanning.
- **Shell Installer (`scripts/setup_shell.sh`)**: Refactored rc file block management using `upsert_rc_block` for clean updating without duplicate blocks, targeting `~/.zshrc` on macOS and `~/.bashrc` on Linux.
- **Documentation**: Updated `README.md` and restructured [`SHORTCUTS.md`](file:///Users/rakeshkandhi/code/personal/dev-env-setup/SHORTCUTS.md) into a high-density, concise quick-reference cheat sheet categorized by navigation, tmux, Neovim, and shell/fzf commands.

---

## [v1.0.0] - 2026-08-11

### [4a6e779] - 2026-08-11 23:46:18 +0530
- **feat**: Add Alacritty skip/install options (`--no-alacritty`), shell setup script, and workflow installer improvements.

### [1c6ab18] - 2026-08-11 23:33:20 +0530
- **docs**: Update `SHORTCUTS.md` with Mac Option-as-Alt tips and optimization guidelines.

### [e82f759] - 2026-08-11 23:32:26 +0530
- **perf**: Optimize Homebrew dependency checks, tmux cursor shapes, status-interval settings, and Alacritty Option-as-Alt binding.

### [9413db7] - 2026-08-11 23:26:26 +0530
- **docs**: Add `SHORTCUTS.md` cheat sheet for Neovim and tmux.

### [f28d078] - 2026-08-11 23:12:53 +0530
- **feat**: Complete initial dev environment setup repository structure, configs (Neovim, tmux, Alacritty), and master installer.

### [4678675] - 2026-08-11 21:55:14 +0530
- **init**: Initial repository commit.
