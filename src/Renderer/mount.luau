local apply = require("../Instance/apply")
local root = require("../Reactive/root")

local function mount<T>(component: () -> T, target: Instance?): () -> ()
	local destroy = root(function(dispose)
		local result = component()
		if target then
			(apply :: any)(target, { result :: any })
		end

		return dispose
	end)

	return destroy
end

return mount
