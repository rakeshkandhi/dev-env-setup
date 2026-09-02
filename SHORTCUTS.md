# ⌨️ Neovim + tmux Shortcuts & Reference Guide

Complete keybinding reference for the **Alacritty + tmux + Neovim + fzf** setup.

| Tool | Master Key |
| :--- | :--- |
| **tmux Prefix** | `Ctrl-a` _(remapped from Ctrl-b)_ |
| **Neovim Leader** | `Space` |

---

## 🔄 1. Seamless Navigation (tmux ↔ Neovim)

The same keys work identically in tmux panes **and** Neovim splits — no mode switching needed.

| Shortcut | Action |
| :--- | :--- |
| `Ctrl-h` | Move focus **Left** |
| `Ctrl-j` | Move focus **Down** |
| `Ctrl-k` | Move focus **Up** |
| `Ctrl-l` | Move focus **Right** |

---

## 🖥️ 2. tmux Sessions

### Detach & Re-attach

| Shortcut / Command | Action |
| :--- | :--- |
| `Ctrl-a d` | **Detach** from tmux (leaves all processes running in background) |
| `tmux a` | **Re-attach** to last active session |
| `tmux a -t <name>` | Re-attach to a **specific named** session |
| `tmux ls` | **List** all running background sessions |
| `tmux new -s <name>` | Create a new named session |
| `tmux kill-session -t <name>` | Kill a specific session |

### Session State (tmux-resurrect)

| Shortcut | Action |
| :--- | :--- |
| `Ctrl-a Ctrl-s` | **Save** full session layout & pane state |
| `Ctrl-a Ctrl-r` | **Restore** saved session layout on startup |

> 💡 `tmux-continuum` auto-saves every 15 minutes and auto-restores on tmux start.

---

## 🪟 3. tmux Windows & Panes

### Windows (Tabs)

| Shortcut | Action |
| :--- | :--- |
| `Ctrl-a f` | **Tmux Sessionizer** — fuzzy-find project folder & switch/create session |
| `Ctrl-a c` | **Create** new window (opens in current working directory) |
| `Ctrl-a ,` | **Rename** current window |
| `Ctrl-a 1` .. `9` | **Jump** directly to window 1–9 |
| `Ctrl-a n` / `Ctrl-a p` | Switch to **Next / Previous** window |
| `Ctrl-a &` | **Close** current window |

> 💡 Windows auto-rename to your current directory name (e.g. `dev-env-setup`, `nvim`, `api`).

### Panes (Splits)

| Shortcut | Action |
| :--- | :--- |
| `Ctrl-a \` | **Split Vertically** (Left / Right) — opens in current path |
| `Ctrl-a -` | **Split Horizontally** (Top / Bottom) — opens in current path |
| `Ctrl-a z` | **Toggle Zoom** — maximise active pane / restore |
| `Ctrl-a x` | **Close / Kill** active pane |
| `Ctrl-a H` | Resize pane **Left** by 5 units |
| `Ctrl-a J` | Resize pane **Down** by 5 units |
| `Ctrl-a K` | Resize pane **Up** by 5 units |
| `Ctrl-a L` | Resize pane **Right** by 5 units |

### TPM Plugin Management

| Shortcut | Action |
| :--- | :--- |
| `Ctrl-a I` | **Install** new plugins listed in `tmux.conf` |
| `Ctrl-a U` | **Update** existing tmux plugins |
| `Ctrl-a Alt-u` | **Remove** / clean unlisted plugins |
| `Ctrl-a r` | **Reload** `tmux.conf` in place |

---

## 📋 4. Copy Mode & Clipboard

Both tmux and Neovim sync with the **OS system clipboard** (`pbcopy` on macOS / `xclip` on Linux). Over SSH, tmux falls back to an **OSC 52** escape sequence so yanks still reach the clipboard of the machine you're sitting at.

### tmux Copy Mode (Vi-style)

| Shortcut | Action |
| :--- | :--- |
| `Ctrl-a [` | **Enter Copy Mode** |
| `h` / `j` / `k` / `l` | Move cursor |
| `w` / `b` | Move word forward / backward |
| `0` / `$` | Jump to start / end of line |
| `/` | Search forward in scrollback |
| `v` | Start **Visual Selection** |
| `y` | **Yank** selection → system clipboard & exit |
| `Mouse Drag` | Auto-yank drag selection to system clipboard |
| `Ctrl-a ]` | Paste from tmux copy buffer |
| `Ctrl-a g` | **Yank git branch** of the active pane's directory → system clipboard & tmux buffer |
| `Ctrl-a y` | **Yank current path** of the active pane → system clipboard & tmux buffer |
| `Cmd+V` (Mac) / `Ctrl+Shift+V` (Linux) | Paste from system clipboard anywhere |

### Neovim Clipboard

- Any yank (`y`, `yy`, `yiw`, `V y`, etc.) automatically lands in the **system clipboard** (`clipboard = "unnamedplus"`).
- Paste into Neovim with `p` / `P` directly from system clipboard.

---

## ⚡ 5. Neovim Keybindings (Leader = `Space`)

### 🚀 Dashboard (on Neovim startup)

| Key | Action |
| :--- | :--- |
| `u` | Update all plugins (`:Lazy update`) |
| `f` | Find files (Telescope) |
| `r` | Recent files (Telescope oldfiles) |
| `t` | Search text (Live Grep) |

### 🔭 Telescope — Fuzzy Finder

| Shortcut | Action |
| :--- | :--- |
| `Space ff` | **Find Files** in project (ignores `node_modules`, `dist`, `.git`, lock files, etc.) |
| `Space fg` | **Live Grep** — search text across all project files |
| `Space fw` | **Grep word** under cursor across project |
| `Space fb` | **Search Buffers** — switch between open files |
| `Space fd` | **Diagnostics** — list all LSP errors/warnings |
| `Space fs` | **Document Symbols** — list functions/vars in current file |
| `Space fS` | **Workspace Symbols** — list symbols across entire project |
| `Space fh` | **Help Tags** — search Neovim documentation |
| `Space fk` | **Keymaps** — search all active keybindings |
| `Space fc` | **Commands** — search Neovim commands |

> 💡 Inside Telescope file picker: `Ctrl-y` (Insert mode) or `y` (Normal mode) copies the selected file path to clipboard.

### 📂 Buffer Navigation (Top Tab Bar)

| Shortcut | Action |
| :--- | :--- |
| `Shift-H` | Go to **Previous Buffer** |
| `Shift-L` | Go to **Next Buffer** |
| `Space bp` | **Toggle Pin** current buffer |
| `Space bo` | Close all **Other** buffers |
| `Space bl` | Close all buffers to the **Left** |
| `Space br` | Close all buffers to the **Right** |
| `Space bP` | Close all **non-pinned** buffers |

### 🧠 Code Navigation & LSP

| Shortcut | Action |
| :--- | :--- |
| `gd` | **Go to Definition** (Telescope picker) |
| `gr` | **Go to References** (Telescope picker) |
| `gi` | **Go to Implementation** |
| `gt` | **Go to Type Definition** |
| `K` | **Hover Documentation** (rounded float window) |
| `Space rn` | **Rename** symbol across entire workspace |
| `Space ca` | **Code Action** / Quick Fix / CSpell word fix |
| `Space q` | Open **Diagnostic List** in location list |
| `gl` | Open **Diagnostic Float** for current line |
| `[d` / `]d` | Jump to **Previous / Next Diagnostic** |
| `Alt + ←` | **Jump Back** in jump list (`C-o`) |
| `Alt + →` | **Jump Forward** in jump list (`C-i`) |

> 💡 LSP servers auto-installed by Mason: `pyright`, `ts_ls`, `html`, `cssls`, `tailwindcss`, `jsonls`, `yamlls`, `bashls`, `clangd`, `lua_ls`, `cspell_ls`.

### ✍️ Autocompletion (nvim-cmp)

| Shortcut | Action |
| :--- | :--- |
| `Ctrl-Space` | **Trigger** completion menu manually |
| `Tab` | Select **next** completion item |
| `Shift-Tab` | Select **previous** completion item |
| `Enter` | **Confirm** selected completion |
| `Ctrl-e` | **Dismiss / abort** completion menu |

### 🖊️ Formatting & Linting

| Shortcut / Trigger | Action |
| :--- | :--- |
| `Alt-Shift-F` | **Manually format** current document |
| _On save_ | **Auto-format**: `lua` → `stylua` · `js/ts/jsx/tsx` → `prettier` · `json/jsonc` → `prettier` |
| _On save / enter / leave insert_ | **Auto-lint**: `python` → `ruff` · `js/ts/jsx/tsx` → `eslint_d` |

### 💬 Comments (Treesitter-aware)

| Shortcut | Action | Mode |
| :--- | :--- | :--- |
| `gcc` | Toggle **line comment** | Normal |
| `gc` | Toggle **comment** on selection | Visual |
| `gcA` | Add comment at **end of line** | Normal |
| `gco` / `gcO` | Add comment **below / above** current line | Normal |

> 💡 Context-aware via `nvim-ts-context-commentstring` — uses `//` inside JSX, `/* */` in CSS, `#` in shell, `--` in Lua, etc.

### ✏️ Line & Selection Editing

| Shortcut | Action | Mode |
| :--- | :--- | :--- |
| `Alt-j` | Move line / selection **Down** | Normal, Insert, Visual |
| `Alt-k` | Move line / selection **Up** | Normal, Insert, Visual |
| `<Esc>` | Clear **search highlights** (`nohlsearch`) | Normal |

> 💡 **Mac Users**: `option_as_alt = "Both"` is set in Alacritty — your Mac `Option` key acts as `Alt` for `Alt+j` / `Alt+k`.

### 🔑 which-key

| Shortcut | Action |
| :--- | :--- |
| `Space ?` | Show **all buffer-local keymaps** in a popup |
| _Any `Space` prefix_ | which-key popup appears automatically showing available continuations |

### 🌿 Git Integration (Gitsigns & Telescope)

| Shortcut | Action |
| :--- | :--- |
| `]h` / `[h` | Jump to **Next / Previous Git Hunk** |
| `Space hs` | **Stage hunk** (also works on visual selection) |
| `Space hr` | **Reset hunk** (also works on visual selection) |
| `Space hS` | **Stage entire buffer** |
| `Space hR` | **Reset entire buffer** |
| `Space hu` | **Undo** last staged hunk |
| `Space hp` | **Preview hunk** in float window |
| `Space hi` | **Preview hunk inline** |
| `Space hb` | **Full Git blame** for current line |
| `Space hy` | **Copy commit hash** of blame for current line to clipboard |
| `Space hd` | **Diff this** file against HEAD |
| `Space tb` | **Toggle** inline Git blame on current line |
| `Space gc` | **Browse Git Commits** in Telescope |
| `Space gb` | **Browse Git Branches** in Telescope |
| `Space gs` | **Browse Git Status** in Telescope |

### ⏪ Undo History (Undotree)

| Shortcut | Action |
| :--- | :--- |
| `Space u` | **Toggle Undotree** — visual branch tree of all edit history |

> 💡 Undotree persists undo history **across sessions** — recover changes from days ago even after closing Neovim.

---

## 🔍 6. Shell — fzf & Aliases

### Shell Aliases

| Command | Action |
| :--- | :--- |
| `v` | Open Neovim (`nvim`) |
| `t` | Open tmux |
| `ta` | **Tmux Sessionizer** — fuzzy-find project folder & switch/create session |

### fzf Key Bindings (everywhere in the shell)

| Shortcut | Action |
| :--- | :--- |
| `Ctrl-T` | Fuzzy-find **files** with live preview → paste path to command line |
| `Ctrl-R` | Fuzzy-search **command history** |
| `Alt-C` | Fuzzy-find **directory** → `cd` into it |
| `Ctrl-u` / `Ctrl-d` | Scroll fzf **preview pane** up / down |

### fzf Tab Completion (`**`)

| Example | Action |
| :--- | :--- |
| `cd **<Tab>` | Fuzzy-complete a directory, then `cd` |
| `kill **<Tab>` | Fuzzy-pick a process to kill |
| `v **<Tab>` / `nvim **<Tab>` | Fuzzy-complete a file, then open in Neovim |

### Shell Helper Functions

| Command | Action |
| :--- | :--- |
| `vf` | Fuzzy-find file(s) with live preview → open in Neovim |
| `vf <query>` | Same, but start with a pre-filtered query |
| `fcd` | Fuzzy-find a directory → `cd` into it |
| `fcd <path>` | Same, searching under a specific `<path>` |
| `fbr` | Fuzzy-find a git branch (local + remote) → check it out; already checked out in another worktree? switches there instead |
| `fwt` | Fuzzy-switch between existing git worktrees (path + branch shown) |
| `fwa` | Fuzzy-pick a branch → create a worktree for it and `cd` in |
| `fwa <branch>` | Same, for a specific (existing or brand-new) branch |
| `fwr` | Fuzzy-pick a worktree (never the main one) → remove it |
| `fwr -f` | Same, but force-remove even with uncommitted changes |
| `fkill` | Fuzzy-pick process(es) → `kill -9` them |
| `fkill 15` | Same, but send `SIGTERM` (`kill -15`) |

> 💡 **Multi-select**: In `vf` and `fkill`, press `Tab` to mark multiple items, then `Enter` to act on all.

---

## 🚀 7. Configuration Highlights & Behaviours

| Feature | Detail |
| :--- | :--- |
| **macOS Option Key** | `option_as_alt = "Both"` in Alacritty → `Alt+j`/`Alt+k` work natively |
| **Dynamic Window Titles** | tmux tabs auto-rename to current directory name |
| **Cursor Shape Sync** | Block `█` in Normal mode, Beam `│` in Insert — synced through tmux |
| **Unified Status Bar** | `vim-tpipeline` embeds Neovim's lualine directly into tmux's status bar |
| **Session Persistence** | `tmux-continuum` auto-saves every 15 min; `tmux-resurrect` restores on start |
| **Clipboard Sync** | tmux copy mode + Neovim yanks both write to OS system clipboard |
| **Relative Line Numbers** | `relativenumber = true` — jump distances shown instantly beside every line |
| **Scroll Context** | `scrolloff = 8` — always 8 lines of context above/below cursor |
| **Persistent Undo** | `undofile = true` — undo history survives closing Neovim |
| **Smart Search** | `ignorecase` + `smartcase` — case-insensitive unless you type a capital |
| **Treesitter Auto-install** | `auto_install = true` — parsers install automatically for any new filetype |
| **Code Spell Check** | `cspell_ls` LSP flags misspellings as diagnostics — fix via `Space ca` |
| **Spellcheck in prose** | Spell check auto-enabled for `markdown`, `text`, `gitcommit` buffers |
| **`.env` → shell filetype** | `.env`, `.env.local`, `.env.production` etc. open with `sh` syntax & LSP |
| **Trackpad Scroll in Neovim** | Mouse scroll wheel / trackpad moves cursor line by line in Normal mode |
