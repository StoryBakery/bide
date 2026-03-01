--[=[
    @class UICornerWrapper
]=]

local vide = require("../vide")

local Props = require("../Utils/Props")

local create = vide.create

local EMPTY_KEY_SET = {}

export type CornerProps = {
	CornerRadius: UDim,
}

local function Corner(props: CornerProps)
	local _, restProps = Props.splitProps(props :: any, EMPTY_KEY_SET)
	return create "UICorner"(Props.composeProps({}, restProps :: any, props :: any))
end

return Corner
