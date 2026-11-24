-- ==============================================================================
-- Rex Multiplexer Configuration
-- ==============================================================================

local HOME = os.getenv("HOME")
local TERMINAL = "com.superlogical.terminal"

-- Foreground process of the terminal block a key was pressed in (or nil).
local function foreground(ctx)
	if not (ctx and ctx.block_id) then
		return nil
	end
	local proc = rex.block.call(TERMINAL, "process", { block_id = ctx.block_id })
	return proc and proc.foreground
end

-- ==============================================================================
-- Pane Navigation (Neovim / tmux passthrough)
-- ==============================================================================
-- Ctrl-h/j/k/l moves between Rex panes, except when the focused block runs
-- Neovim (smart-splits.nvim crosses back into Rex itself) or tmux (its own
-- vim-tmux-navigator bindings handle tmux panes and the Neovim inside them).

-- True when the focused block is running vim, nvim or tmux.
local function passes_through(ctx)
	local fg = foreground(ctx)
	if not fg then
		return false
	end
	-- Check both fg.name and the basename of fg.argv0
	for _, s in ipairs({ fg.name or "", (fg.argv0 or ""):match("[^/]*$") }) do
		if s:match("^n?vim") or s:match("^tmux") then
			return true
		end
	end
	return false
end

for key, direction in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
	rex.bind("ctrl+" .. key, function(ctx)
		if passes_through(ctx) then
			return false -- let Neovim / tmux handle it
		end
		rex.session.focus_direction({ direction = direction })
		return true
	end)
end

-- ==============================================================================
-- File Picker (fzf popup -> editor)
-- ==============================================================================
-- Opens rex-find (scripts/rex-find, symlinked to ~/.local/bin by
-- setup_rex.sh) in a floating pane, in the focused pane's directory.
-- "nvim" edits inside the popup; "code -g" opens VS Code and closes the popup.
local picker = {
	script = HOME .. "/.local/bin/rex-find",
	bounds = { 0.1, 0.1, 0.8, 0.8 }, -- x, y, w, h as fractions of the window
	-- One entry per shortcut: action name, key, title, editor command.
	editors = {
		{ name = "find_file", key = "cmd+p", title = "Find File in VS Code", editor = "code -g" },
		{ name = "find_file_vim", key = "cmd+o", title = "Find File in Neovim", editor = "nvim" },
	},
}

for _, e in ipairs(picker.editors) do
	rex.action({
		name = e.name,
		title = e.title,
		run = function(ctx)
			local fg = foreground(ctx)
			rex.session.new_layer({
				bounds = picker.bounds,
				focus = true,
				layout = rex.layout.block({
					flavor = TERMINAL .. ".shell",
					label = "find",
					options = {
						cwd = (fg and fg.cwd) or HOME,
						command = { "env", "REX_PICKER_EDITOR=" .. e.editor, picker.script },
					},
				}),
			})
		end,
	})
	rex.bind(e.key, e.name)
end

-- ==============================================================================
-- Remote Hosts
-- ==============================================================================
rex.host({
	label = "sett",
	endpoint = "http://sett:7297",
})
