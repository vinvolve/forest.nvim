if vim.g.loaded_forest == 1 then
	return
end
vim.g.loaded_forest = 1

vim.api.nvim_create_user_command("ForestStart", function()
	require("forest.core").start()
	require("forest.ui").open_dashboard(true)
end, {})
vim.api.nvim_create_user_command("ForestStop", function()
	require("forest.core").stop(false)
end, {})
vim.api.nvim_create_user_command("ForestDashboard", function()
	require("forest.ui").open_dashboard(false)
end, {})
vim.api.nvim_create_user_command("ForestDashboardClose", function()
	require("forest.ui").close_dashboard()
end, {})
