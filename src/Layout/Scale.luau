--[=[
    @class UIScaleWrapper
]=]

local Instance = require("../Instance")

local create = Instance.create

export type ScaleProps = {
	Scale: number,
}

local function Scale(props: ScaleProps)
	return create "UIScale"(props :: any)
end

return Scale
