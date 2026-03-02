local branch = require("./branch")
local effect = require("./effect")
local flags = require("./flags")
local signal = require("./signal")
local timeout = require("./timeout")()

type Array<T> = { T }
type Map<K, V> = { [K]: V }
type SignalAccessor<T> = signal.SignalAccessor<T>
type SignalSetter<T> = signal.SignalSetter<T>

local function values<K, V, Obj>(
	input: SignalAccessor<Map<K, V>>,
	component: (V, SignalAccessor<K>, SignalAccessor<boolean>) -> (Obj, ...number)
): SignalAccessor<Array<Obj>>
	local updateCount = 0
	local scopes = {} :: Map<V, {
		destroy: () -> (),
		object: Obj,
		index: K?,
		setIndex: SignalSetter<K>,
		count: number,
		delay: number,
		present: SignalAccessor<boolean>,
		setPresent: SignalSetter<boolean>,
		timeout: { cancel: boolean }?,
	}>

	local output, setOutput = signal({} :: Array<Obj>)
	local function updateOutput()
		local objects = table.create(4) :: Array<Obj>

		for _, scope in scopes do
			objects[#objects + 1] = scope.object
		end

		setOutput(objects)
	end

	effect(function()
		local data = input()

		local count = updateCount
		updateCount += 1

		local childrenNeedUpdate = false -- set to true if a scope is created or destroyed

		if flags.strict then -- check for duplicate values
			local map = {}
			for _, v in data do
				if map[v] then
					error("input passed to `values()` contains duplicate values", 0)
				end
				map[v] = true
			end
		end

		-- create or update scopes
		for i, v in data do
			local scope = scopes[v]

			if scope == nil then -- create new scope and create component
				local index, setIndex = signal(i)
				local present, setPresent = signal(false)

				local delay = nil :: number?
				local destroy, object = branch(function()
					local childObject, childDelay = component(v, index, present)
					delay = childDelay
					return childObject
				end)

				setPresent(true)

				childrenNeedUpdate = true

				scopes[v] = {
					destroy = destroy,
					object = object,
					index = i,
					setIndex = setIndex,
					count = count,
					delay = delay or 0,
					present = present,
					setPresent = setPresent,
					timeout = nil,
				}
			else -- update scope
				scope.count = count

				if (scope.index :: any) ~= (i :: any) then
					if scope.timeout then -- value is in input table again; cancel destruction
						scope.timeout.cancel = true
						scope.timeout = nil
						scope.setPresent(true)
					end

					scope.index = i
					scope.setIndex(i)
				end
			end
		end

		-- destroy scopes
		for v, scope in scopes do
			if scope.count < count then -- if count is not latest then value is no longer in the input table
				scope.setPresent(false)

				if scope.delay == 0 then
					scope.destroy()
					scopes[v] = nil
					childrenNeedUpdate = true
				else
					scope.index = nil -- set to nil for the `scope.index ~= i` check
					if scope.timeout == nil then
						scope.timeout = timeout(
							scope.delay,
							function() -- todo: possible redundant updates
								scope.destroy()
								scopes[v] = nil
								updateOutput()
							end
						)
					end
				end
			end
		end

		if childrenNeedUpdate then
			updateOutput()
		end
	end)

	return output
end

return values
