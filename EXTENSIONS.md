# 🔌 Extensions & Plugin Architecture Guide

This document provides a comprehensive analysis of all **tmux** and **Neovim** plugins, extensions, and integrations configured in this environment. It details what each extension does, how it powers developer workflows, and how it dramatically increases terminal efficiency.

---

## 🛠️ 1. Tmux Extensions & Plugins (TPM)

Tmux is managed via **TPM (Tmux Plugin Manager)**. Plugins are defined in [`tmux/tmux.conf`](file:///Users/rakeshkandhi/code/personal/dev-env-setup/tmux/tmux.conf) and automatically installed during setup.

### 🧩 Plugin Inventory

| Plugin                 | Repository                                                                            | Purpose                                                                                                                   |
| :--------------------- | :------------------------------------------------------------------------------------ | :------------------------------------------------------------------------------------------------------------------------ |
| **TPM**                | [`tmux-plugins/tpm`](https://github.com/tmux-plugins/tpm)                             | Plugin manager for tmux — enables non-interactive installation, updates, and clean lifecycle management.                  |
| **tmux-sensible**      | [`tmux-plugins/tmux-sensible`](https://github.com/tmux-plugins/tmux-sensible)         | Applies universal, community-agreed defaults (increases history limit, reduces key repeat delays, enables UTF-8).         |
| **tmux-resurrect**     | [`tmux-plugins/tmux-resurrect`](https://github.com/tmux-plugins/tmux-resurrect)       | Saves and restores complete tmux environments (sessions, layout ratios, active paths, open windows, and pane scrollback). |
| **tmux-continuum**     | [`tmux-plugins/tmux-continuum`](https://github.com/tmux-plugins/tmux-continuum)       | Continuous background auto-saving of tmux sessions every 15 minutes and automatic restoration when tmux starts.           |
| **vim-tmux-navigator** | [`christoomey/vim-tmux-navigator`](https://github.com/christoomey/vim-tmux-navigator) | Allows seamless `Ctrl+h/j/k/l` navigation across tmux split panes and Neovim splits without mode switches.                |
| **tmux-yank**          | [`tmux-plugins/tmux-yank`](https://github.com/tmux-plugins/tmux-yank)                 | Copies selection directly to the OS system clipboard (`pbcopy` on macOS, `xclip` on Linux).                               |
| **tmux-sessionizer**   | Custom shell utility ([`scripts/tmux_sessionizer.sh`](file:///Users/rakeshkandhi/code/personal/dev-env-setup/scripts/tmux_sessionizer.sh)) | Fuzzy-finds project directories via fzf and creates or attaches dedicated project tmux sessions in zero keystrokes.       |

---

### 🚀 Workflow & Efficiency Benefits (Tmux)

#### 1. Zero Context Loss Across Reboots (`tmux-resurrect` + `tmux-continuum`)

- **Workflow Impact**: When your machine restarts or terminal closes, you normally lose all pane layouts, running commands, and working directory contexts across multiple projects.
- **Efficiency Boost**:
  - Automatically saves the layout state every 15 minutes.
  - Automatically restores your exact multi-window, multi-pane setup when opening tmux.
  - Preserves scrollback buffers so historical command outputs remain searchable.
  - **Manual Shortcuts**: `Prefix + Ctrl-s` (Save state), `Prefix + Ctrl-r` (Restore state).

#### 2. Fluid Pane & Editor Navigation (`vim-tmux-navigator`)

- **Workflow Impact**: Eliminates the mental friction of remembering whether your cursor is in a Neovim split or a tmux pane.
- **Efficiency Boost**:
  - `Ctrl-h` → Move Left
  - `Ctrl-j` → Move Down
  - `Ctrl-k` → Move Up
  - `Ctrl-l` → Move Right
  - Seamlessly jumps from a Neovim code editor pane into a neighboring terminal runner pane using the exact same keystrokes.

#### 3. Native Clipboard Integration (`tmux-yank` & Vi Copy Mode)

- **Workflow Impact**: Allows selecting text in terminal copy mode (`Prefix + [`) using standard Vim keys (`v` to select, `y` to yank) and pasting directly into external applications (browsers, Slack, docs).
- **Efficiency Boost**: No mouse dragging or raw terminal copy distortion; full keyboard control over text copying.

---

## ⚡ 2. Neovim Extensions & Plugins (Lazy.nvim)

Neovim plugins are managed by **Lazy.nvim** in the [`rakeshkandhi/nvim`](https://github.com/rakeshkandhi/nvim) configuration repo.

---

### 📂 A. Session, Navigation & Telemetry

| Extension / Plugin              | Purpose                                                                        | Workflow Impact & Efficiency                                                                                    |
| :------------------------------ | :----------------------------------------------------------------------------- | :-------------------------------------------------------------------------------------------------------------- |
| **`telescope.nvim`**            | Interactive fuzzy finder for files, live grep, git logs, and LSP symbols.      | Instant file navigation (`Space + f f`) and global code searching (`Space + f g`) without touching a file tree. |
| **`telescope-fzf-native.nvim`** | C-compiled fzf algorithm for Telescope sorting.                                | Delivers microsecond fuzzy searching over 100,000+ files.                                                       |
| **`vim-tpipeline`**             | Embeds Neovim statusline directly into tmux status bar.                        | Saves 1 full row of vertical screen space per Neovim window for maximal code visibility.                        |
| **`dashboard-nvim`**            | Fast splash screen with recent files and session shortcuts.                    | Rapid project re-entry on launch.                                                                               |
| **`which-key.nvim`**            | Popup keybinding helper displaying available shortcuts as you type `<Leader>`. | Zero guesswork for rare commands; eliminates cheat sheet lookup time.                                           |

---

### 💡 B. Language Server Protocol (LSP), Completion & Snippets

| Extension / Plugin | Purpose | Workflow Impact & Efficiency |
| :--- | :--- | :--- |
| **`mason.nvim`** | Package manager for LSP servers, linters, and formatters. | Single-command UI (`:Mason`) to install/update/remove any language tool. |
| **`mason-lspconfig.nvim`** | Bridges Mason with Neovim's native LSP. Auto-installs: `pyright`, `ts_ls`, `html`, `cssls`, `tailwindcss`, `jsonls`, `yamlls`, `bashls`, `clangd`, `lua_ls`, `cspell_ls`. | LSP servers present on first launch — zero manual setup. |
| **`mason-tool-installer.nvim`** | Auto-installs formatters and linters via Mason on startup. Manages: `stylua`, `prettier`, `ruff`, `eslint_d`, `cspell`. | Formatters and linters are always present without manual `brew`/`npm` installs. |
| **`nvim-lspconfig`** | Configures native Neovim LSP clients. | Real-time diagnostics, hover docs (`K`), go-to-definition (`gd`), workspace rename (`Space rn`). |
| **`nvim-cmp`** | Blazingly fast autocompletion engine. | Intelligent completions as you type from LSP, buffer, file paths, and command line. |
| **`cmp-nvim-lsp` / `cmp-buffer` / `cmp-path` / `cmp-cmdline`** | Completion sources for LSP symbols, buffer words, file paths, and Vim `:` commands. | Context-aware completions across every editing surface. |
| **`LuaSnip` & `friendly-snippets`** | Snippet engine + 400+ language snippet library. | Expand boilerplate (functions, loops, React components) with `Tab`. |

---

### 🔍 C. Syntax Parsing, Formatting & Linting

| Extension / Plugin | Purpose | Workflow Impact & Efficiency |
| :--- | :--- | :--- |
| **`nvim-treesitter`** | Incremental AST parser (`auto_install = true`). | Precise syntax highlighting and correct indentation for any language opened. |
| **`conform.nvim`** | Async auto-formatter. Formats on save **and** on `Alt-Shift-F`. Formatters: `lua → stylua`, `js/ts/jsx/tsx → prettier`, `json/jsonc → prettier`. | Zero-effort consistent formatting; never manually run a formatter again. |
| **`nvim-lint`** | Async linter triggered on save, buffer enter, and leaving insert mode. Linters: `python → ruff`, `js/ts/jsx/tsx → eslint_d`. | Linting feedback appears without blocking the editor or running commands. |
| **`nvim-ts-context-commentstring`** | Treesitter-aware comment string detection. | `gcc` / `gc` uses the correct comment style per context — `//` in JSX, `#` in shell, `--` in Lua, even inside embedded languages. |

---

### 🌿 D. Git & Visual Enhancements

| Extension / Plugin          | Purpose                                                             | Workflow Impact & Efficiency                                                                                            |
| :-------------------------- | :------------------------------------------------------------------ | :---------------------------------------------------------------------------------------------------------------------- |
| **`gitsigns.nvim`**         | Inline git diff gutter signs & hunk management.                     | View added/modified lines in the margin, preview diff hunks (`Space + h p`), and stage/undo hunks directly in buffer.   |
| **`undotree`**              | Visual branch tree for persistent undo history (`Space + u`).       | Inspect historical edit branches and revert back to any past state even after closing Neovim or restarting the machine. |
| **`bufferline.nvim`**       | Top tab bar for open buffers with file icons.                       | Easily jump between active buffers (`Shift-H` / `Shift-L`).                                                             |
| **`lualine.nvim`**          | Statusline displaying mode, git branch, diagnostics, and file info. | Instant visual feedback on workspace and git status.                                                                    |
| **`catppuccin`**            | Unified Catppuccin Mocha color palette.                             | Reduces eye strain with high-contrast, comfortable colors across all terminal tools.                                    |
| **`indent-blankline.nvim`** | Visual indentation guides.                                          | Instantly recognize block scope boundaries in deeply nested code.                                                       |
| **`nvim-autopairs`**        | Auto-closes brackets, parens, and quotes.                           | Eliminates syntax errors from missing closing symbols.                                                                  |

---

## 🔁 3. Inter-Tool Synergy & Efficiency Matrix

The primary efficiency advantage of this setup stems from how these individual extensions interact to form a unified, keyboard-driven environment:

```
┌─────────────────────────────────────────────────────────────────┐
│                      Alacritty Terminal                         │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                     tmux Session                          │  │
│  │  ┌─────────────────────────┬───────────────────────────┐  │  │
│  │  │  Neovim (Buffer 1)      │  Terminal / CLI Runner    │  │  │
│  │  │   • Treesitter Highlight│   • fzf (vf / fcd / fkill)│  │  │
│  │  │   • LSP Autocomplete    │   • Starship Prompt       │  │  │
│  │  │   • Gitsigns / UndoTree │                           │  │  │
│  │  └───────────────▲─────────┴─────────────▲─────────────┘  │  │
│  │                  │  Ctrl+h/j/k/l Nav     │                │  │
│  │                  └───────────────────────┘                │  │
│  │  Statusline: Catppuccin Mocha (vim-tpipeline merged)       │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### 🎯 Key Inter-Tool Synergies

1. **Shared Navigation Protocol**: `Ctrl-h`, `Ctrl-j`, `Ctrl-k`, `Ctrl-l` work across both Neovim splits and tmux panes transparently via `vim-tmux-navigator`.
2. **Unified Catppuccin Mocha Theme**: Alacritty, tmux, Neovim, fzf, and Starship prompt all share the exact same Catppuccin Mocha palette for zero visual clutter.
3. **Screen Real Estate Optimization**: `vim-tpipeline` merges Neovim's statusline directly into the tmux status bar, providing an additional line of code viewing area.
4. **Persistent Workspace Memory**: `tmux-continuum` auto-saves your exact layout every 15 minutes, while `undotree` inside Neovim remembers your exact edit history across reboots.
5. **System Clipboard Sharing**: Copying text anywhere (in tmux copy mode or Neovim buffers) automatically syncs with the macOS/Linux system clipboard.
