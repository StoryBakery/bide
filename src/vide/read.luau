type function read(value: type)
	return value
end

local function read<T>(value: T): read<T>
	return if type(value) == "function" then (value :: any)() else value
end

return read
