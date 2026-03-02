type SignalAccessor<T> = () -> T
type Readable<T> = T | SignalAccessor<T>

local function read<T>(value: Readable<T>): T
	if type(value) == "function" then
		return ((value :: any) :: SignalAccessor<T>)()
	end

	return value :: T
end

return read
