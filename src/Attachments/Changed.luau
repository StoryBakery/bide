--[=[
	@class Changed

	인스턴스 프로퍼티 변경을 구독하는 attachment입니다.
]=]

local function connectChangedSignal(instance: Instance, property: string, callback: () -> ())
	local okMethod, getPropertyChangedSignal = pcall(function()
		return (instance :: any).GetPropertyChangedSignal
	end)

	if okMethod and type(getPropertyChangedSignal) == "function" then
		return getPropertyChangedSignal(instance, property):Connect(callback)
	end

	local okSignal, changedSignal = pcall(function()
		return (instance :: any).Changed
	end)

	if not okSignal or typeof(changedSignal) ~= "RBXScriptSignal" then
		error(`instance does not support changed signal for property "{property}"`, 2)
	end

	return changedSignal:Connect(function(changedProperty)
		if changedProperty == property then
			callback()
		end
	end)
end

local function Changed<T>(property: string, callback: (T) -> ())
	return function(instance: Instance)
		local conn = connectChangedSignal(instance, property, function()
			callback((instance :: any)[property])
		end)

		callback((instance :: any)[property])

		return function()
			conn:Disconnect()
		end
	end
end

return Changed
