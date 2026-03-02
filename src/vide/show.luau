local derive = require("./derive")
local effect = require("./effect")
local signal = require("./signal")
local switch = require("./switch")

type Array<T> = { T }
type SignalAccessor<T> = signal.SignalAccessor<T>

local function show<T, Obj>(
	input: SignalAccessor<T?>,
	component: (SignalAccessor<T>, SignalAccessor<boolean>) -> (Obj, ...number),
	fallback: ((SignalAccessor<boolean>) -> (Obj, ...number))?
): SignalAccessor<nil | Obj | Array<Obj>>
	local filteredInput, setFilteredInput = signal(nil :: T?)

	effect(function()
		local value = input()
		if value then
			setFilteredInput(value)
		end
	end)

	local inputIsTruthy = derive(function()
		return not not input()
	end)

	return switch(inputIsTruthy) {
		[true] = function(present)
			return component(filteredInput :: any, present)
		end,
		[false] = fallback :: any,
	}
end

return show
