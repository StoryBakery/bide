local graph = require("./graph")
local create_node = graph.create_node
local push_scope = graph.push_scope
local pop_scope = graph.pop_scope
local destroy_node = graph.destroy

local refs = {}

local function root<T...>(fn: (destroy: () -> ()) -> T...): T...
	local node = create_node(false, false, false)

	refs[node] = true -- prevent gc of root node

	local destroy = function()
		if not refs[node] then
			error "root already destroyed"
		end
		refs[node] = nil
		destroy_node(node)
	end

	push_scope(node)

	local result = { pcall(fn, destroy) }

	pop_scope()

	if not result[1] then
		destroy()
		error(`error while running root():\n\n{tostring(result[2])}`, 0)
	end

	return unpack(result :: any, 2)
end

return root
