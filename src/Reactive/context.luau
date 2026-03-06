local graph = require("./graph")
type Node<T> = graph.Node<T>
local create_node = graph.create_node
local get_scope = graph.get_scope
local push_scope = graph.push_scope
local pop_scope = graph.pop_scope
local set_context = graph.set_context

type ContextId = any

export type ContextProviderProps<T> = {
	value: T,
	children: any,
}

export type Context<T> = {
	id: ContextId,
	Provider: <TReturn>(props: ContextProviderProps<T>) -> TReturn,
	defaultValue: T,
}

local nil_symbol = newproxy()

local function read_context_value<T>(
	scope: Node<unknown>?,
	contextId: ContextId
): (boolean, T?)
	while scope do
		local contextValues = scope.context

		if contextValues ~= false then
			local value = (contextValues :: { [any]: unknown })[contextId]

			if value ~= nil then
				return true, if value ~= nil_symbol then ((value :: any) :: T) else nil
			end
		end

		local owner = scope.owner
		if owner == false then
			scope = nil
		else
			scope = owner :: Node<unknown>
		end
	end

	return false, nil
end

local function createContext<T>(defaultValue: T?): Context<T?>
	local contextId = newproxy()
	local context = {
		id = contextId,
		defaultValue = defaultValue,
	} :: Context<T?>

	context.Provider = function<TReturn>(props: ContextProviderProps<T?>): TReturn
		if type(props) ~= "table" then
			error("attempt to set context with invalid provider props", 0)
		end

		local scope = get_scope()
		if scope == nil then
			error("attempt to set context outside of a reactive scope", 0)
		end

		local new_scope = create_node(scope, false, false)
		set_context(new_scope, context.id, if props.value == nil then nil_symbol else props.value)

		push_scope(new_scope)

		local ok, result
		if type(props.children) == "function" then
			ok, result = pcall(props.children :: (...any) -> any)
		else
			ok = true
			result = props.children
		end

		pop_scope()

		if not ok then
			error(`error while running context provider:\n\n{tostring(result)}`, 0)
		end

		return result
	end

	return context
end

local function useContext<T>(context: Context<T>): T
	if type(context) ~= "table" then
		error("attempt to use context with an invalid context object", 0)
	end

	local isSet, value = read_context_value(get_scope(), context.id)
	if isSet then
		return (value :: any) :: T
	end

	return (context.defaultValue :: any) :: T
end

return {
	createContext = createContext,
	useContext = useContext,
}
