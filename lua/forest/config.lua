local M = {}

M.options = {
	focus_target_minutes = 5,
	max_idle_seconds = 100,
	icons = {
		growing = "🌱",
		tree = "🌳",
		dead = "🥀",
	},
}

function M.setup(user_opts)
	M.options = vim.tbl_deep_extend("force", M.options, user_opts or {})
end

return M
