# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
