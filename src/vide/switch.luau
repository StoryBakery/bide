local branch = require("./branch")
local effect = require("./effect")
local signal = require("./signal")
local timeout = require("./timeout")()

type Array<T> = { T }
type Map<K, V> = { [K]: V }
type SignalAccessor<T> = signal.SignalAccessor<T>
type SignalSetter<T> = signal.SignalSetter<T>
type Component<T> = (SignalAccessor<boolean>) -> (T, ...number)

local function switch_map<K, Obj>(
	input: SignalAccessor<K>,
	map: Map<K, Component<Obj>>
): SignalAccessor<nil | Obj | Array<Obj>>
	local scopes = {} :: Map<K, {
		destroy: () -> (),
		object: Obj,
		delay: number,
		present: SignalAccessor<boolean>,
		setPresent: SignalSetter<boolean>,
		timeout: { cancel: boolean }?,
	}>

	local output, setOutput = signal(nil :: nil | Obj | Array<Obj>)
	local function updateOutput()
		local objects = {} :: Array<Obj>

		for _, scope in scopes do
			objects[#objects + 1] = scope.object
		end

		setOutput(if objects[2] then objects elseif objects[1] then objects[1] else nil)
	end

	effect(function()
		local key: K? = input()

		-- destroy (or queue destroy) all scopes not associated with the input key
		for k, scope in scopes do
			if (k :: any) == (key :: any) then
				continue
			end

			scope.setPresent(false)

			if scope.delay == 0 then
				scope.destroy()
				scopes[k] = nil
			else
				if scope.timeout == nil then
					scope.timeout = timeout(scope.delay, function()
						scope.destroy()
						scopes[k] = nil
						updateOutput()
					end)
				end
			end
		end

		-- create new scope or abort destruction of existing scope if key exists
		if key ~= nil then
			local scope = scopes[key]

			if scope then
				scope.setPresent(true)

				if scope.timeout then
					scope.timeout.cancel = true
					scope.timeout = nil
				end
			else
				local component = map[key]

				if component ~= nil then
					if type(component) ~= "function" then
						error("map must map a value to a function", 0)
					end

					local present, setPresent = signal(false)

					local delay = nil :: number?
					local destroy, object = branch(function()
						local childObject, childDelay = component(present)
						delay = childDelay
						return childObject
					end)

					setPresent(true)

					scopes[key] = {
						destroy = destroy,
						object = object,
						delay = delay or 0,
						present = present,
						setPresent = setPresent,
						timeout = nil,
					}
				end
			end
		end

		updateOutput()
	end)

	return output
end

local function switch<K, Obj>(
	input: SignalAccessor<K>
): (map: Map<K, Component<Obj>>) -> SignalAccessor<nil | Obj | Array<Obj>>
	return function(map)
		return switch_map(input, map)
	end
end

return switch
