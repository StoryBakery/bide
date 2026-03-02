local graph = require("./graph")
local create_signal_node = graph.create_signal_node
local push_scope_as_child_of = graph.push_scope_as_child_of
local update_descendants = graph.update_descendants

export type SignalAccessor<T> = () -> T
export type SignalSetter<T> = (T | ((T) -> T)) -> T
export type SignalOptions<T> = {
	equals: boolean | ((T, T) -> boolean)?,
}

type EqualsFn<T> = (T, T) -> boolean

local function signal<T>(
	initialValue: T,
	options: SignalOptions<T>?
): (SignalAccessor<T>, SignalSetter<T>)
	local node = create_signal_node(initialValue)
	local equals = if options then options.equals else nil

	local function getValue(): T
		push_scope_as_child_of(node)
		return node.cache
	end

	local function isEqual(previous: T, nextValue: T): boolean
		if equals ~= nil then
			if equals == false then
				return false
			end

			if type(equals) == "function" then
				return ((equals :: any) :: EqualsFn<T>)(previous, nextValue)
			end

			return (previous :: any) == (nextValue :: any)
		end

		return (previous :: any) == (nextValue :: any)
			and (type(nextValue) ~= "table" or table.isfrozen(nextValue))
	end

	local function setValue(nextValue: T | ((T) -> T)): T
		local previous = node.cache :: T
		local nextResolvedValue = if type(nextValue) == "function"
			then ((nextValue :: any) :: (T) -> T)(previous)
			else nextValue :: T

		if isEqual(previous, nextResolvedValue) then
			return nextResolvedValue
		end

		node.cache = nextResolvedValue
		update_descendants(node)
		return nextResolvedValue
	end

	return getValue, setValue
end

return signal
