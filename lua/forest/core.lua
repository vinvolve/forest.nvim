local M = {}
local config = require("forest.config")

M.state = {
	timer = nil,
	focus_seconds = 0,
	last_activity = os.time(),
	is_growing = false,
	trees_planted = 0,
}

local function notify(msg)
	vim.notify(msg, vim.log.levels.INFO, { title = "Forest" })
end

function M.register_activity()
	if M.state.is_growing then
		M.state.last_activity = os.time()
	end
end

function M.start()
	if M.state.is_growing then
		notify(config.options.icons.growing .. " You are already growing a tree!")
		return
	end

	M.state.focus_seconds = 0
	M.state.is_growing = true
	M.state.last_activity = os.time()
	notify(
		config.options.icons.growing
			.. " Seed planted! Focus for "
			.. config.options.focus_target_minutes
			.. " minutes."
	)

	M.state.timer = vim.uv.new_timer()
	M.state.timer:start(
		1000,
		1000,
		vim.schedule_wrap(function()
			if not M.state.is_growing then
				return
			end

			local idle_time = os.difftime(os.time(), M.state.last_activity)
			if idle_time > config.options.max_idle_seconds then
				M.stop(true)
				return
			end

			M.state.focus_seconds = M.state.focus_seconds + 1
			if M.state.focus_seconds >= (config.options.focus_target_minutes * 60) then
				M.success()
			end
		end)
	)
end

function M.success()
	M.state.is_growing = false
	if M.state.timer then
		M.state.timer:stop()
		M.state.timer:close()
		M.state.timer = nil
	end
	M.state.trees_planted = M.state.trees_planted + 1
	notify(config.options.icons.tree .. " Tree fully grown! Total: " .. M.state.trees_planted)
end

function M.stop(withered)
	if not M.state.is_growing then
		return
	end
	M.state.is_growing = false
	if M.state.timer then
		M.state.timer:stop()
		M.state.timer:close()
		M.state.timer = nil
	end

	if withered then
		notify(config.options.icons.dead .. " You lost focus. Your tree withered.")
	else
		notify("🪓 You chopped down the sapling.")
	end
end

return M
