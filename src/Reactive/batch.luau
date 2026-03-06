local flags = require("./flags")
local graph = require("./graph")

local function batch<T...>(setter: () -> T...): T...
	local already_batching = flags.batch
	local from = 0

	if not already_batching then
		flags.batch = true
		from = graph.get_update_queue_length()
	end

	local result = { pcall(setter) }
	local ok = result[1]
	local err = result[2]

	if not already_batching then
		flags.batch = false
		graph.flush_update_queue(from)
	end

	if not ok then
		error(`error occured while batching updates: {tostring(err)}`, 0)
	end

	return unpack(result :: any, 2)
end

return batch
