--[=[
    @class UICornerWrapper
]=]

local Instance = require("../Instance")

local create = Instance.create

export type CornerProps = {
	CornerRadius: UDim,
}

local function Corner(props: CornerProps)
	return create "UICorner"(props :: any)
end

return Corner
