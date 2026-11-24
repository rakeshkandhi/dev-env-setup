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
-- Pane Navigation (Neovim passthrough, works with smart-splits.nvim)
-- ==============================================================================

-- True when the focused block is running vim or nvim.
local function is_vim(ctx)
	local fg = foreground(ctx)
	if not fg then
		return false
	end
	-- Check both fg.name and the basename of fg.argv0
	for _, s in ipairs({ fg.name or "", (fg.argv0 or ""):match("[^/]*$") }) do
		if s:match("^n?vim") then
			return true
		end
	end
	return false
end

for key, direction in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
	rex.bind("ctrl+" .. key, function(ctx)
		if is_vim(ctx) then
			return false -- let Neovim handle it
		end
		rex.session.focus_direction({ direction = direction })
		return true
	end)
end

-- ==============================================================================
-- File Picker (fzf popup -> editor)
-- ==============================================================================
-- Opens scripts/rex-find in a floating pane, in the focused pane's directory.
-- editor: "nvim" edits inside the popup; "code -g" opens VS Code and closes it.
local picker = {
	key = "cmd+p",
	editor = "code -g",
	script = HOME .. "/code/dev-env-setup/scripts/rex-find",
	bounds = { 0.1, 0.1, 0.8, 0.8 }, -- x, y, w, h as fractions of the window
}

rex.action({
	name = "find_file",
	title = "Find File (fzf)",
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
					command = { "env", "REX_PICKER_EDITOR=" .. picker.editor, picker.script },
				},
			}),
		})
	end,
})

rex.bind(picker.key, "find_file")

-- ==============================================================================
-- Remote Hosts
-- ==============================================================================
rex.host({
	label = "sett",
	endpoint = "http://sett:7297",
})
