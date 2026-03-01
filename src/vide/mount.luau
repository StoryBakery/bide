local apply = require("./apply")
local root = require("./root")

local function mount<T>(component: () -> T, target: Instance?): () -> ()
	local destroy = root(function()
		local result = component()
		if target then
			(apply :: any)(target, { result :: any })
		end
	end)

	return destroy
end

return mount
