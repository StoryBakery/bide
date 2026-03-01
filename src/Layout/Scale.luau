--[=[
    @class UIScaleWrapper
]=]

local vide = require("../vide")

local Props = require("../Utils/Props")

local create = vide.create

local EMPTY_KEY_SET = {}

export type ScaleProps = {
	Scale: number,
}

local function Scale(props: ScaleProps)
	local _, restProps = Props.splitProps(props :: any, EMPTY_KEY_SET)
	return create "UIScale"(Props.composeProps({}, restProps :: any, props :: any))
end

return Scale
