local graph = require("./graph")
type Node<T> = graph.Node<T>
local get_scope = graph.get_scope

local function untrack<T>(getter: () -> T): T
	local scope = get_scope()

	if scope then
		-- sources are only tracked if the node in scope has an effect
		local scopeEffect = scope.effect
		scope.effect = false

		local ok, result = pcall(getter)

		scope.effect = scopeEffect

		if not ok then
			error(tostring(result), 0)
		end

		return result :: T
	else
		return getter()
	end
end

return untrack
