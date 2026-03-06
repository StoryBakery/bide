local graph = require("./graph")
local create_node = graph.create_node
local push_scope_as_child_of = graph.push_scope_as_child_of
local assert_stable_scope = graph.assert_stable_scope
local evaluate_node = graph.evaluate_node

export type MemoOptions<T> = {
	equals: boolean | ((T, T) -> boolean)?,
}

local function derive<T>(accessor: (...any) -> T, initialValue: T?, options: MemoOptions<T>?): () -> T
	local equals = if options then options.equals else nil
	local hasValue = false

	local function evaluateMemo(previousValue: T?): T
		local nextValue = accessor(previousValue)

		if hasValue then
			if equals ~= false then
				if type(equals) == "function" then
					if (((equals :: any) :: (any, any) -> boolean)(previousValue, nextValue)) then
						return previousValue :: any
					end
				elseif previousValue == nextValue then
					return previousValue :: any
				end
			end
		end

		hasValue = true
		return nextValue
	end

	local node = create_node(assert_stable_scope(), evaluateMemo :: any, initialValue)

	evaluate_node(node)

	return function()
		push_scope_as_child_of(node)
		return node.cache
	end
end

return derive
