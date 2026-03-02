local graph = require("./graph")
local create_node = graph.create_node
local assert_stable_scope = graph.assert_stable_scope
local evaluate_node = graph.evaluate_node

local taskLibrary = task

local function runDeferred(callback: () -> ())
	if taskLibrary and taskLibrary.defer then
		taskLibrary.defer(callback)
	else
		callback()
	end
end

local function effect(callback: () -> (), initial_value: any?)
	local node = create_node(assert_stable_scope(), callback :: any, initial_value)

	runDeferred(function()
		if node.owner then
			evaluate_node(node)
		end
	end)
end

return effect
