<p align="center">
  <h1 align="center">🚀 Dev Environment Setup</h1>
  <p align="center">
    One-command setup for a unified <strong>Alacritty + tmux + Neovim</strong> development environment — themed with Catppuccin Mocha, powered by MesloLGS Nerd Font.
  </p>
  <p align="center">
    <img src="https://img.shields.io/badge/macOS-supported-000000?style=flat-square&logo=apple&logoColor=white" alt="macOS" />
    <img src="https://img.shields.io/badge/Linux-supported-FCC624?style=flat-square&logo=linux&logoColor=black" alt="Linux" />
    <img src="https://img.shields.io/badge/theme-Catppuccin%20Mocha-b4befe?style=flat-square&logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld0JveD0iMCAwIDI0IDI0Ij48cGF0aCBmaWxsPSIjYjRiZWZlIiBkPSJNMTIgMkM2LjQ4IDIgMiA2LjQ4IDIgMTJzNC40OCAxMCAxMCAxMCAxMC00LjQ4IDEwLTEwUzE3LjUyIDIgMTIgMnoiLz48L3N2Zz4=&logoColor=white" alt="Catppuccin Mocha" />
    <img src="https://img.shields.io/badge/editor-Neovim-57A143?style=flat-square&logo=neovim&logoColor=white" alt="Neovim" />
    <img src="https://img.shields.io/badge/license-MIT-blue?style=flat-square" alt="License" />
  </p>
</p>

---

## ✨ What's Inside

Three terminal tools, one cohesive experience:

| Tool | Role |
| :--- | :--- |
| **[Alacritty](https://alacritty.org/)** | GPU-accelerated terminal emulator — fast, minimal, cross-platform |
| **[tmux](https://github.com/tmux/tmux)** | Terminal multiplexer — sessions, windows, panes |
| **[Neovim](https://neovim.io/)** | Hyperextensible text editor — LSP, Treesitter, Telescope |

What makes them feel like **one tool**:

- 🎨 **Catppuccin Mocha** — identical color palette across all three configs
- 🔤 **MesloLGS Nerd Font** — consistent icons and glyphs everywhere
- 📊 **Unified Status Bar** — [vim-tpipeline](https://github.com/vimpostor/vim-tpipeline) merges Neovim's lualine into tmux's status bar
- 🧭 **Seamless Navigation** — [vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator) lets `Ctrl-h/j/k/l` move across tmux panes _and_ Neovim splits
- 📋 **Shared Clipboard** — yank in Neovim or tmux copy mode → system clipboard
- ⌨️ **[Shortcut Guide](SHORTCUTS.md)** — complete cheat sheet for tmux & Neovim keybindings

---

## 📸 Screenshots

> _Screenshots coming soon — showing the unified terminal experience across Alacritty, tmux, and Neovim with Catppuccin Mocha._

---

## 📋 Prerequisites

Before running the installer, make sure you have:

- **git** installed
- **macOS** or **Linux** (Ubuntu/Debian, Fedora, or Arch)
- **SSH key** configured for GitHub — [guide](https://docs.github.com/en/authentication/connecting-to-github-with-ssh) _(required for cloning the Neovim config repo)_

---

## ⚡ Quick Start

```bash
git clone git@github.com:rakeshkandhi/dev-env-setup.git
cd dev-env-setup
./install.sh
```

That's it. One command installs and configures everything.

---

## 📖 Step-by-Step Installation Guide

### 1. Clone this repository

```bash
git clone git@github.com:rakeshkandhi/dev-env-setup.git
cd dev-env-setup
```

### 2. Run the installer

```bash
./install.sh
```

### 3. What each step does

The install script performs the following in order:

| Step | Description |
| :--- | :--- |
| **OS Detection** | Auto-detects macOS or Linux distro (Ubuntu/Debian, Fedora, Arch) and selects the correct package manager |
| **Dependencies** | Installs core tools via `brew` / `apt` / `dnf` / `pacman`: Neovim, tmux, ripgrep, fd, lazygit, and more |
| **Fonts** | Downloads and installs **MesloLGS Nerd Font** from the [nerd-fonts](https://github.com/ryanoasis/nerd-fonts) releases |
| **Neovim** | Clones [`rakeshkandhi/nvim`](https://github.com/rakeshkandhi/nvim) to `~/.config/nvim` (with HTTPS fallback) — Lazy.nvim auto-installs all plugins on first launch |
| **tmux** | Symlinks tmux config to `~/.config/tmux/`, installs TPM, and auto-installs plugins non-interactively |
| **Alacritty** | Symlinks Alacritty config to `~/.config/alacritty/` |
| **Shell** | Configures `EDITOR=nvim`, `VISUAL=nvim`, `alias v=nvim`, and `alias t=tmux` in `~/.zshrc` / `~/.bashrc` |

### 4. Post-install steps

After the script completes:

1. **Restart your terminal** (or source your shell rc file)
2. **Open Neovim** — plugins auto-install via Lazy.nvim on first launch

---

## 🔄 Step-by-Step Update Guide

Already installed? Keep everything in sync when configs change.

### 1. Navigate to this repo

```bash
cd /path/to/dev-env-setup
```

### 2. Run the updater

```bash
./install.sh update
```

### 3. What happens during an update

| Step | Description |
| :--- | :--- |
| **Self-update** | Pulls the latest changes for this repo (`git pull`) |
| **Neovim config** | Pulls the latest Neovim config (`git pull` in `~/.config/nvim`) |
| **TPM & Plugins** | Updates TPM and auto-updates tmux plugins via `update_plugins all` |
| **Symlinks** | Re-verifies symlinks for tmux and Alacritty configs |
| **Shell & Deps** | Re-applies shell aliases and updates dependencies if needed |

### 4. Post-update steps

1. **Reload tmux config** — press `prefix + r` or restart tmux
2. **Open Neovim** — Lazy.nvim will show if plugins need updating (`:Lazy update`)

---

## 🎯 Selective Install / Update

Don't need everything? Target specific components:

```bash
# Install only a specific component
./install.sh --only nvim       # Only setup Neovim
./install.sh --only tmux       # Only setup tmux
./install.sh --only alacritty  # Only setup Alacritty
./install.sh --only shell      # Only setup shell environment & aliases
./install.sh --only fonts      # Only install fonts
./install.sh --only deps       # Only install dependencies

# Skip dependency installation
./install.sh --no-deps

# Exclude Alacritty installation and config porting
./install.sh --no-alacritty   # (aliases: --skip-alacritty, --exclude-alacritty)

# Exclude shell environment & aliases setup
./install.sh --no-shell       # (aliases: --skip-shell, --exclude-shell)

# Preview what would happen without making changes
./install.sh --dry-run

# Update only a specific component
./install.sh update --only nvim   # Update only Neovim config
```

> **Note on Alacritty**: If the Alacritty configuration is missing during installation and `--no-alacritty` is not passed, the installer will interactively prompt whether to **(s)kip** or **(i)nstall** Alacritty configuration and binary.

---

## 🔗 Key Integrations

### Unified Status Bar — vim-tpipeline

Instead of two status bars (tmux + Neovim's lualine), **vim-tpipeline** merges them into one:

| Context | What the status bar shows |
| :--- | :--- |
| **Inside Neovim** | tmux renders lualine content — mode, filename, diagnostics, git branch |
| **In the shell** | tmux shows its own bar — session name, windows, git branch, clock |

The result: a clean, single status bar that adapts to context.

### Seamless Navigation — vim-tmux-navigator

`Ctrl-h/j/k/l` moves between tmux panes **and** Neovim splits seamlessly. No mental context-switching, no different keybindings — just move in the direction you want.

```
  ┌──────────┬──────────┐
  │  Neovim  │  Neovim  │
  │  Split 1 │  Split 2 │  ← Ctrl-l / Ctrl-h between splits
  ├──────────┼──────────┤
  │  tmux    │  tmux    │  ← Ctrl-j / Ctrl-k between panes
  │  pane 3  │  pane 4  │
  └──────────┴──────────┘
```

### Shared Clipboard

Copying works everywhere, pasting works anywhere:

| Action | Result |
| :--- | :--- |
| Yank in Neovim (`y`) | → system clipboard (`unnamedplus`) |
| Yank in tmux copy mode | → system clipboard (`pbcopy` / `xclip`) |
| Paste | `Cmd+V` (macOS) or `Ctrl+Shift+V` (Linux) |

### Catppuccin Mocha Theme

A consistent color palette across all three tools:

| Color | Hex | Usage |
| :--- | :--- | :--- |
| Base | `#1E1E2E` | Background |
| Text | `#CDD6F4` | Foreground text |
| Blue | `#89B4FA` | Keywords, links |
| Mauve | `#CBA6F7` | Statements, tags |
| Green | `#A6E3A1` | Strings, success |
| Red | `#F38BA8` | Errors, deletions |
| Peach | `#FAB387` | Numbers, warnings |
| Surface 0 | `#313244` | UI borders, line numbers |

---

## ⌨️ Keybinding Cheatsheet

### tmux — prefix: `Ctrl-a`

| Key | Action |
| :--- | :--- |
| `prefix + -` | Split pane horizontally |
| `prefix + \` | Split pane vertically |
| `prefix + H/J/K/L` | Resize pane in direction |
| `prefix + r` | Reload tmux config |
| `prefix + I` | Install TPM plugins |
| `prefix + U` | Update TPM plugins |
| `Ctrl-h/j/k/l` | Navigate panes (+ Neovim splits) |
| `Shift-H` | Previous window |
| `Shift-L` | Next window |

### Neovim — leader: `Space`

| Key | Action |
| :--- | :--- |
| `Space + ff` | Find files (Telescope) |
| `Space + fg` | Live grep (Telescope) |
| `Space + fb` | Buffers (Telescope) |
| `Shift-H` | Previous buffer |
| `Shift-L` | Next buffer |
| `gd` | Go to definition |
| `gr` | Go to references |
| `K` | Hover documentation |
| `Space + ca` | Code action |
| `Space + rn` | Rename symbol |
| `Ctrl-h/j/k/l` | Navigate splits (+ tmux panes) |

---

## 📁 Directory Structure

```
dev-env-setup/
├── install.sh              # Main installer / updater
├── README.md
├── LICENSE
├── alacritty/
│   └── alacritty.toml      # Alacritty configuration
├── tmux/
│   ├── tmux.conf           # tmux configuration
│   └── themes/
│       └── catppuccin.conf # Catppuccin Mocha for tmux
└── scripts/
    ├── detect_os.sh        # OS & distro detection
    ├── install_deps.sh     # Dependency installation
    ├── install_fonts.sh    # MesloLGS Nerd Font installer
    ├── setup_nvim.sh       # Neovim config setup
    ├── setup_tmux.sh       # tmux config & TPM setup
    └── setup_alacritty.sh  # Alacritty config setup
```

---

## 📍 Config Locations After Install

| Tool | Config Path | Source |
| :--- | :--- | :--- |
| Alacritty | `~/.config/alacritty/` | Symlink → this repo's `alacritty/` |
| tmux | `~/.config/tmux/` | Symlink → this repo's `tmux/` |
| Neovim | `~/.config/nvim/` | Git clone from [`rakeshkandhi/nvim`](https://github.com/rakeshkandhi/nvim) |

> **Why symlinks?** Editing configs in the repo automatically updates the live config. No copying, no drift.

---

## 🔧 Troubleshooting

<details>
<summary><strong>Colors look wrong or washed out</strong></summary>

Ensure your terminal supports true color (24-bit). Run this test:

```bash
printf "\x1b[38;2;255;100;0mTrueColor Test\x1b[0m\n"
```

If the text appears **orange**, true color is working. If not:
- Make sure you're using **Alacritty** (it supports true color out of the box)
- Verify `TERM` is set to `xterm-256color` or `alacritty`
- In tmux, check that `default-terminal` is set to `tmux-256color`

</details>

<details>
<summary><strong>Icons/glyphs not rendering (□ or ?)</strong></summary>

The MesloLGS Nerd Font must be set as your terminal font:
- **Alacritty**: This is handled automatically by the config
- **Other terminals**: Manually set the font to `MesloLGS Nerd Font` in your terminal's preferences
- Verify the font is installed: `fc-list | grep -i meslo` (Linux) or check Font Book (macOS)

</details>

<details>
<summary><strong>tmux plugins not working</strong></summary>

1. Make sure TPM is installed: `ls ~/.tmux/plugins/tpm`
2. Inside tmux, press `Ctrl-a + I` (capital I) to install plugins
3. If TPM itself is missing, re-run: `./install.sh --only tmux`

</details>

<details>
<summary><strong>Neovim plugins not installing</strong></summary>

1. Open Neovim and run `:Lazy` to open the plugin manager
2. Press `I` to install missing plugins or `U` to update
3. If issues persist, remove the plugin cache and restart:
   ```bash
   rm -rf ~/.local/share/nvim/lazy
   nvim  # Lazy.nvim will re-install everything
   ```

</details>

<details>
<summary><strong>vim-tmux-navigator not working</strong></summary>

- Ensure you're running Neovim **inside** tmux
- Verify the tmux-side navigator plugin is installed: `prefix + I`
- Check that `Ctrl-h/j/k/l` aren't intercepted by your terminal emulator

</details>

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).

---

<p align="center">
  <sub>Built with ☕ by <a href="https://github.com/rakeshkandhi">rakeshkandhi</a></sub>
</p>