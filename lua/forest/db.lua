local M = {}

local data_path = vim.fn.stdpath("data") .. "/forest.json"

local function read_db()
	local f = io.open(data_path, "r")
	if not f then
		return { total_trees = 0, history = {} }
	end

	local content = f:read("*a")
	f:close()

	if content == "" then
		return { total_trees = 0, history = {} }
	end

	local ok, data = pcall(vim.json.decode, content)
	if not ok or type(data) ~= "table" then
		return { total_trees = 0, history = {} }
	end

	data.total_trees = data.total_trees or 0
	data.history = data.history or {}
	return data
end

local function write_db(data)
	local f = io.open(data_path, "w")
	if not f then
		vim.notify("Forest: Failed to save progress to " .. data_path, vim.log.levels.ERROR)
		return
	end
	f:write(vim.json.encode(data))
	f:close()
end

function M.get_total_trees()
	local data = read_db()
	return data.total_trees
end

function M.add_tree(duration_minutes, time_start, time_end)
	local data = read_db()
	data.total_trees = data.total_trees + 1
	
	table.insert(data.history, {
		time_start = time_start,
		time_end = time_end,
		duration_minutes = duration_minutes
	})
	
	write_db(data)
end
function M.get_weekly_trees()
	local data = read_db()
	if not data.history then return 0 end

	local now = os.time()
	local t = os.date("*t", now)
	local days_since_monday = (t.wday + 5) % 7
	local midnight = os.time({year=t.year, month=t.month, day=t.day, hour=0, min=0, sec=0})
	local start_of_week = midnight - (days_since_monday * 24 * 60 * 60)

	local count = 0
	for _, record in ipairs(data.history) do
		if record.time_end and record.time_end >= start_of_week then
			count = count + 1
		end
	end
	return count
end
return M
