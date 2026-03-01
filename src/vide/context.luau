local graph = require("./graph")
type Node<T> = graph.Node<T>
local create_node = graph.create_node
local get_scope = graph.get_scope
local push_scope = graph.push_scope
local pop_scope = graph.pop_scope
local set_context = graph.set_context

export type Context<T> = (...any) -> any

local nil_symbol = newproxy()
local count = 0

local function context<T>(...: T): any
	count += 1
	local id = count

	local has_default = select("#", ...) > 0
	local default_value = ...

	local useContext = function(...): any
		local scope: Node<unknown>? = get_scope()

		if select("#", ...) == 0 then -- get
			while scope do
				local ctx = scope.context

				if not ctx then
					local owner = scope.owner
					scope = if owner == false then nil else owner
					continue
				end

				local value = (ctx :: { unknown })[id]

				if value == nil then
					local owner = scope.owner
					scope = if owner == false then nil else owner
					continue
				end

					return if value ~= nil_symbol then value else nil
			end

			if has_default then
				return default_value
			else
				error(
					"attempt to get context when no context is set and no default context is set",
					0
				)
			end
		else -- set
			if not scope then
				return error("attempt to set context outside of a vide scope", 0)
			end

			local value, component = ...
			if type(component) ~= "function" then
				error("attempt to set context with an invalid component callback", 0)
			end

			local new_scope = create_node(scope, false, false)
			set_context(new_scope, id, if value == nil then nil_symbol else value)

			push_scope(new_scope)

			local ok, result = pcall(component :: (...any) -> any)

			pop_scope()

			if not ok then
				error(`error while running context:\n\n{tostring(result)}`, 0)
			end

			return result
		end

	end

	return useContext
end

return context
