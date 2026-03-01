--[=[
	@class Frame

	Element 기반 Frame 래퍼입니다.
]=]

local Element = require("../Core/Element")
local Props = require("../Utils/Props")

export type FrameProps = Element.ElementProps

local function Frame(props: FrameProps): GuiBase2d
	local frameProps = Props.composeProps({
		Class = "Frame",
	}, props :: any, nil)

	return Element(frameProps :: any)
end

return Frame
