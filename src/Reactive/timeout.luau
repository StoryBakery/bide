type TimeoutHandle = {
	cancel: boolean,
}

local task = task or require("@lune/task")

local function timeout(seconds: number, callback: () -> ()): TimeoutHandle
	local handle = {
		cancel = false,
	}

	task.delay(seconds, function()
		if handle.cancel then
			return
		end
		callback()
	end)

	return handle
end

return timeout
