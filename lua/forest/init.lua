local M = {}

function M.setup(opts)
	require("forest.config").setup(opts)

	-- Track user activity globally
	local group = vim.api.nvim_create_augroup("ForestActivityTracker", { clear = true })
	vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "InsertCharPre" }, {
		group = group,
		callback = function()
			require("forest.core").register_activity()
		end,
	})
end

return M
