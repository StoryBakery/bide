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

local function effect(callback: () -> ())
	-- Ignore graph's previous-value argument and do not cache callback return values.
	local wrappedCallback = function()
		callback()
		return nil
	end

	local node = create_node(assert_stable_scope(), wrappedCallback, nil)

	runDeferred(function()
		if node.owner then
			evaluate_node(node)
		end
	end)
end

return effect
