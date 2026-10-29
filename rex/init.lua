-- ==============================================================================
-- Rex Multiplexer Configuration
-- ==============================================================================
-- Seamless navigation integration with Neovim (smart-splits.nvim)

-- Helper to check if the active terminal block is running Neovim
local function is_vim(ctx)
	local proc = rex.block.call("com.superlogical.terminal", "process", { block_id = ctx.block_id })
	local fg = proc and proc.foreground
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

-- Directional pane navigation with Vim passthrough
for key, direction in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
	rex.bind("ctrl+" .. key, function(ctx)
		if is_vim(ctx) then
			return false
		end
		rex.session.focus_direction({ direction = direction })
		return true
	end)
end
