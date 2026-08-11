# ⌨️ Neovim + tmux Cheat Sheet & Shortcuts Guide

This guide covers all keybindings for your unified **Alacritty + tmux + Neovim** setup.

---

## 🎯 Master Controls

| Core Concept | Binding | Description |
|---|---|---|
| **tmux Prefix** | `Ctrl-a` | Remapped from `Ctrl-b` for easy one-hand access |
| **Neovim Leader** | `Space` | Spacebar is the leader key for commands |

---

## 🔄 1. Seamless Pane Navigation (tmux ↔ Neovim)

You do **not** need to use different shortcuts whether you are in tmux or inside Neovim. The keys below automatically switch between tmux panes AND Neovim split windows seamlessly.

| Shortcut | Action | Scope |
|---|---|---|
| `Ctrl-h` | Move focus **Left** | tmux pane or Neovim split |
| `Ctrl-j` | Move focus **Down** | tmux pane or Neovim split |
| `Ctrl-k` | Move focus **Up** | tmux pane or Neovim split |
| `Ctrl-l` | Move focus **Right** | tmux pane or Neovim split |

---

## 🖥️ 2. tmux Session & Detach Controls

### Detaching & Re-attaching
When running inside tmux (with or without Neovim open):

| Shortcut / Command | Action |
|---|---|
| `Ctrl-a d` | **Detach from tmux session** (leaves Neovim & terminal jobs running in background) |
| `tmux a` or `tmux attach` | **Re-attach** to your last active tmux session |
| `tmux a -t <name>` | **Re-attach** to a specific named session |
| `tmux ls` | List all running tmux background sessions |
| `tmux new -s <name>` | Create a new named session |
| `tmux kill-session -t <name>` | Kill a background session |

---

## 🪟 3. tmux Window & Pane Management

### Managing Windows (Tabs inside tmux)

| Shortcut | Action |
|---|---|
| `Ctrl-a c` | **Create** a new window (opens in current working directory) |
| `Ctrl-a ,` | **Rename** current window |
| `Ctrl-a 1` .. `9` | **Switch directly** to window 1–9 |
| `Ctrl-a n` / `Ctrl-a p` | Switch to **Next / Previous** window |
| `Ctrl-a &` | **Close** current window |

> 💡 **Auto Folder Naming**: Windows are automatically titled after your current project directory name (e.g. `dev-env-setup`, `nvim`, `api`).

### Managing Panes (Splits inside tmux)

| Shortcut | Action |
|---|---|
| `Ctrl-a \` | **Split Vertically** (Left / Right) in current path |
| `Ctrl-a -` | **Split Horizontally** (Top / Bottom) in current path |
| `Ctrl-a z` | **Toggle Zoom** (Maximize active pane fullscreen / restore) |
| `Ctrl-a x` | **Close / Kill** active pane |
| `Ctrl-a H` | Resize pane 5 units **Left** |
| `Ctrl-a J` | Resize pane 5 units **Down** |
| `Ctrl-a K` | Resize pane 5 units **Up** |
| `Ctrl-a L` | Resize pane 5 units **Right** |

---

## 📋 4. Copy Mode & Clipboard (tmux & Neovim)

Both tmux and Neovim are configured to share your OS system clipboard (**macOS `pbcopy` / Linux `xclip`**).

### tmux Copy Mode (Vim style)

| Shortcut | Action |
|---|---|
| `Ctrl-a [` | **Enter Copy Mode** |
| `h` / `j` / `k` / `l` | Move cursor in copy mode |
| `w` / `b` | Move word forward / backward |
| `0` / `$` | Jump to start / end of line |
| `/` | Search forward in scrollback |
| `v` | Start **Visual Selection** |
| `y` | **Yank selection** to system clipboard & exit copy mode |
| `Mouse Drag` | Drag select text to automatically yank to system clipboard |
| `Ctrl-a ]` | Paste from tmux copy buffer |
| `Cmd + V` (Mac) / `Ctrl+Shift+V` (Linux) | Paste anywhere from system clipboard |

### Neovim Clipboard

- Any yank in Neovim (`y`, `yy`, `yiw`, etc.) automatically goes to your **system clipboard** (`clipboard = "unnamedplus"`).
- You can paste into Neovim with `p` / `P` from system clipboard.

---

## ⚡ 5. Neovim Keybindings (Leader = `Space`)

### Telescope Fuzzy Finder

| Shortcut | Action |
|---|---|
| `Space ff` | Find Files in project |
| `Space fg` | Live Grep search across text |
| `Space fb` | Search active Buffers |
| `Space fh` | Search Help tags |
| `Space fk` | Search all Keymaps |
| `Space fc` | Search Neovim Commands |
| `Space fw` | Grep for word under cursor |

### Buffer Navigation (Top Tab Bar)

| Shortcut | Action |
|---|---|
| `Shift + H` | Go to **Previous Buffer** |
| `Shift + L` | Go to **Next Buffer** |
| `Space bp` | Toggle Pin buffer |
| `Space bo` | Close all **Other** buffers |
| `Space bl` | Close buffers to the **Left** |
| `Space br` | Close buffers to the **Right** |
| `Space bP` | Delete all non-pinned buffers |

### Code Navigation & LSP

| Shortcut | Action |
|---|---|
| `gd` | Go to **Definition** |
| `gr` | Go to **References** |
| `gi` | Go to **Implementation** |
| `gt` | Go to **Type Definition** |
| `K` | Display **Hover Documentation** |
| `Space rn` | **Rename** symbol across workspace |
| `Space ca` | Trigger **Code Action** (Quick Fix / CSpell fix) |
| `gl` | Open diagnostic float window |
| `[d` / `]d` | Jump to **Previous / Next Diagnostic** |
| `Alt + Left` / `Alt + Right` | Jump backward / forward in jump list (`C-o` / `C-i`) |

### Line & Selection Manipulation

| Shortcut | Action | Mode |
|---|---|---|
| `Alt + j` | Move line / selection **Down** | Normal, Insert, Visual |
| `Alt + k` | Move line / selection **Up** | Normal, Insert, Visual |
| `<Esc>` | Clear search highlights (`nohlsearch`) | Normal |

> 💡 **Mac Users**: `option_as_alt = "Both"` is enabled in Alacritty, so your Mac Option key acts natively as `Alt` for `Alt+j` and `Alt+k`.

### Git Integration (Gitsigns & Telescope)

| Shortcut | Action |
|---|---|
| `]h` / `[h` | Jump to **Next / Previous Hunk** |
| `Space hs` | Stage hunk |
| `Space hr` | Reset hunk |
| `Space hp` | Preview hunk inline |
| `Space hb` | Git blame line |
| `Space hy` | **Copy Git blame commit hash** for current line to clipboard |
| `Space tb` | Toggle inline Git blame |
| `Space gc` | Browse Git Commits in Telescope |
| `Space gb` | Browse Git Branches in Telescope |
| `Space gs` | Browse Git Status in Telescope |

---

## 🔌 6. TPM (Tmux Plugin Manager) Commands

Inside tmux:

| Shortcut | Action |
|---|---|
| `Ctrl-a I` | **Install** new plugins listed in `tmux.conf` |
| `Ctrl-a U` | **Update** existing tmux plugins |
| `Ctrl-a Alt-u` | Remove / clean unlisted plugins |
| `Ctrl-a r` | **Reload** tmux configuration |

---

## 🚀 7. Config Optimizations Included

- 🟢 **macOS Option Key Support**: `option_as_alt = "Both"` in Alacritty enables native `Alt+j`/`Alt+k` line shifting on Mac.
- 🏷️ **Dynamic Folder Titles**: tmux tabs auto-rename to your current directory name.
- █/│ **Dynamic Cursor Shapes**: Neovim automatically toggles between Solid Block `█` (Normal) and Thin Beam `│` (Insert) inside tmux.
- 📊 **Single Status Bar**: `vim-tpipeline` embeds Neovim status into tmux and restores the tmux bar cleanly on exit.
