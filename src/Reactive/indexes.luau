local branch = require("./branch")
local effect = require("./effect")
local signal = require("./signal")
local timeout = require("./timeout")

type Array<T> = { T }
type Map<K, V> = { [K]: V }
type SignalAccessor<T> = signal.SignalAccessor<T>
type SignalSetter<T> = signal.SignalSetter<T>

local function indexes<K, V, Obj>(
	input: SignalAccessor<Map<K, V>>,
	component: (SignalAccessor<V>, K, SignalAccessor<boolean>) -> (Obj, ...number)
): SignalAccessor<Array<Obj>>
	local updateCount = 0
	local scopes = {} :: Map<K, {
		destroy: () -> (),
		object: Obj,
		value: V?,
		setValue: SignalSetter<V>,
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

		-- create or update scopes
		for i, inputValue in data do
			local scope = scopes[i]

			if scope == nil then -- create new scope and create component
				local value, setValue = signal(inputValue)
				local present, setPresent = signal(false)

				local delay = nil :: number?
				local destroy, object = branch(function()
					local childObject, childDelay = component(value, i, present)
					delay = childDelay
					return childObject
				end)

				setPresent(true)

				childrenNeedUpdate = true

				scopes[i] = {
					destroy = destroy,
					object = object,
					value = inputValue,
					setValue = setValue,
					count = count,
					delay = delay or 0,
					present = present,
					setPresent = setPresent,
					timeout = nil,
				}
			else -- update scope
				scope.count = count

				if (scope.value :: any) ~= (inputValue :: any) then
					if scope.timeout then -- index is in input table again; cancel destruction
						scope.timeout.cancel = true
						scope.timeout = nil
						scope.setPresent(true)
					end

					scope.value = inputValue
					scope.setValue(inputValue)
				end
			end
		end

		-- destroy scopes
		for i, scope in scopes do
			if scope.count < count then -- if count is not latest then index is no longer in the input table
				scope.setPresent(false)

				if scope.delay == 0 then
					scope.destroy()
					scopes[i] = nil
					childrenNeedUpdate = true
				else
					scope.value = nil -- set to nil for the `scope.value ~= v` check
					if scope.timeout == nil then
						scope.timeout = timeout(
							scope.delay,
							function() -- todo: possible redundant updates
								scope.destroy()
								scopes[i] = nil
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

return indexes
