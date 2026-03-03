local M = {}
local core = require("forest.core")
local config = require("forest.config")

local ui_timer = nil

-- Helper function to generate the text lines
local function get_dashboard_lines()
	local lines = { "", "  Status:" }
	if core.state.is_growing then
		local remaining = (config.options.focus_target_minutes * 60) - core.state.focus_seconds
		-- Prevent negative time if it slightly overshoots before success logic triggers
		if remaining < 0 then
			remaining = 0
		end

		local mins = math.floor(remaining / 60)
		local secs = remaining % 60
		table.insert(lines, string.format("  %s Growing... %02d:%02d left", config.options.icons.growing, mins, secs))
	else
		table.insert(lines, "  No active tree. Type :ForestStart")
	end

	table.insert(lines, "")
	table.insert(lines, "  Forest Size: " .. core.state.trees_planted)

	local forest_visual = "  "
	for _ = 1, core.state.trees_planted do
		forest_visual = forest_visual .. config.options.icons.tree
	end
	table.insert(lines, forest_visual)

	return lines
end

function M.open_dashboard()
	local buf = vim.api.nvim_create_buf(false, true)

	local width = 45
	local height = 10
	local ui = vim.api.nvim_list_uis()[1]

	local opts = {
		relative = "editor",
		width = width,
		height = height,
		anchor = "NE",
		col = ui.width - 1,
		row = 1,
		style = "minimal",
		border = "rounded",
		title = " 🌲 Your Forest 🌲 ",
		title_pos = "center",
	}

	local win = vim.api.nvim_open_win(buf, true, opts)

	-- Add this line to make the window transparent!
	-- Adjust the number (0-100) to change how see-through it is.
	vim.api.nvim_set_option_value("winblend", 20, { win = win })

	-- Function to safely update the buffer
	local function update_buffer()
		if not vim.api.nvim_buf_is_valid(buf) then
			return
		end

		vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, get_dashboard_lines())
		vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
	end

	-- Draw it immediately the first time
	update_buffer()

	-- Start a timer to redraw it every second
	ui_timer = vim.uv.new_timer()
	ui_timer:start(
		1000,
		1000,
		vim.schedule_wrap(function()
			if not vim.api.nvim_win_is_valid(win) then
				if ui_timer then
					ui_timer:stop()
					ui_timer:close()
					ui_timer = nil
				end
				return
			end
			update_buffer()
		end)
	)

	-- Press 'q' to close the floating window
	vim.keymap.set("n", "q", function()
		vim.api.nvim_win_close(win, true)
	end, { buffer = buf, silent = true })

	-- Clean up the timer when the window is closed (via 'q' or other methods)
	vim.api.nvim_create_autocmd("WinClosed", {
		pattern = tostring(win),
		callback = function()
			if ui_timer then
				ui_timer:stop()
				ui_timer:close()
				ui_timer = nil
			end
		end,
		once = true,
	})
end

return M
