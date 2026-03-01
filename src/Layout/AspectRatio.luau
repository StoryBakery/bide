--[=[
    @class UIAspectRatioConstraintWrapper
]=]

local vide = require("../vide")

local Props = require("../Utils/Props")

local create = vide.create

local EMPTY_KEY_SET = {}

export type AspectRatioConstraintProps = {
	AspectRatio: number?,
	DominantAxis: Enum.DominantAxis?,
	AspectType: Enum.AspectType?,
}

local function AspectRatioConstraint(props: AspectRatioConstraintProps)
	local _, restProps = Props.splitProps(props :: any, EMPTY_KEY_SET)
	return create "UIAspectRatioConstraint"(Props.composeProps({}, restProps :: any, props :: any))
end

return AspectRatioConstraint
