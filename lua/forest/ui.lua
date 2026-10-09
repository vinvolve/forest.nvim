local M = {}
local core = require("forest.core")
local config = require("forest.config")

local ui_timer = nil

local function generate_forest_grid(total_trees)
	if total_trees == 0 then
		return {}
	end

	local grids_per_row = 2
	local block_lines = {}
	local current_tree = 0

	while current_tree < total_trees do
		local grid_idx = math.floor(current_tree / 9)
		local pos_in_grid = current_tree % 9
		local row_in_grid = math.floor(pos_in_grid / 3) + 1

		local block_idx = math.floor(grid_idx / grids_per_row)
		local grid_in_block = grid_idx % grids_per_row

		local base_line = block_idx * 3
		for i = 1, 3 do
			if not block_lines[base_line + i] then
				block_lines[base_line + i] = "  "
			end
		end

		if pos_in_grid == 0 and grid_in_block > 0 then
			for i = 1, 3 do
				block_lines[base_line + i] = block_lines[base_line + i] .. "   "
			end
		end

		block_lines[base_line + row_in_grid] = block_lines[base_line + row_in_grid] .. config.options.icons.tree
		current_tree = current_tree + 1
	end

	local result = {}
	for i, line in ipairs(block_lines) do
		table.insert(result, line)
		if i % 3 == 0 and i ~= #block_lines then
			table.insert(result, "")
		end
	end

	return result
end

-- Helper function to generate the text lines
local function get_dashboard_lines(is_minimal)
	local lines = {}
	if core.state.is_growing then
		local remaining = (config.options.focus_target_minutes * 60) - core.state.focus_seconds
		if remaining < 0 then
			remaining = 0
		end

		local mins = math.floor(remaining / 60)
		local secs = remaining % 60
		
		local total_seconds = config.options.focus_target_minutes * 60
		local progress = core.state.focus_seconds / total_seconds
		if progress > 1 then progress = 1 end
		local stages = config.options.icons.stages or { "🌱" }
		local stage_index = math.floor(progress * #stages) + 1
		if stage_index > #stages then stage_index = #stages end
		local current_icon = stages[stage_index]

		if is_minimal then
			table.insert(lines, string.format(" %s %02d:%02d ", current_icon, mins, secs))
		else
			table.insert(lines, string.format("  %s %02d:%02d", current_icon, mins, secs))
		end
	else
		if is_minimal then
			table.insert(lines, "  No active tree  ")
		else
			table.insert(lines, "  No active tree")
		end
	end

	if not is_minimal then
		table.insert(lines, "")
		table.insert(lines, string.format("  🌳 %d this week", core.state.trees_planted))
		table.insert(lines, "")

		local forest_lines = generate_forest_grid(core.state.trees_planted)
		for _, line in ipairs(forest_lines) do
			table.insert(lines, line)
		end
	end

	return lines
end

M.win_is_minimal = false

function M.open_dashboard(is_minimal)
	if M.win and vim.api.nvim_win_is_valid(M.win) then
		local was_minimal = M.win_is_minimal
		vim.api.nvim_win_close(M.win, true)
		M.win = nil
		if was_minimal == is_minimal then
			return
		end
	end

	M.win_is_minimal = is_minimal
	local buf = vim.api.nvim_create_buf(false, true)

	local initial_lines = get_dashboard_lines(is_minimal)
	
	local width = is_minimal and 16 or 26
	local height = is_minimal and 1 or math.max(6, #initial_lines + 2)
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
		title = is_minimal and "" or " Forest ",
		title_pos = "center",
	}

	local win = vim.api.nvim_open_win(buf, true, opts)
	M.win = win

	-- Add this line to make the window transparent!
	-- Adjust the number (0-100) to change how see-through it is.
	vim.api.nvim_set_option_value("winblend", 20, { win = win })

	-- Function to safely update the buffer
	local function update_buffer()
		if not vim.api.nvim_buf_is_valid(buf) then
			return
		end

		local lines = get_dashboard_lines(is_minimal)
		if vim.api.nvim_win_is_valid(win) then
			local new_height = is_minimal and 1 or math.max(6, #lines + 2)
			vim.api.nvim_win_set_height(win, new_height)
			if is_minimal and #lines > 0 then
				local max_w = 12
				for _, l in ipairs(lines) do
					if vim.fn.strdisplaywidth(l) > max_w then
						max_w = vim.fn.strdisplaywidth(l)
					end
				end
				vim.api.nvim_win_set_width(win, math.max(16, max_w + 2))
			end
		end

		vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
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
			M.win = nil
			if ui_timer then
				ui_timer:stop()
				ui_timer:close()
				ui_timer = nil
			end
		end,
		once = true,
	})
end

function M.close_dashboard()
	if M.win and vim.api.nvim_win_is_valid(M.win) then
		vim.api.nvim_win_close(M.win, true)
		M.win = nil
	end
end

return M
