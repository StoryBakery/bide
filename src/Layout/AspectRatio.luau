--[=[
    @class UIAspectRatioConstraintWrapper
]=]

local Instance = require("../Instance")

local create = Instance.create

export type AspectRatioConstraintProps = {
	AspectRatio: number?,
	DominantAxis: Enum.DominantAxis?,
	AspectType: Enum.AspectType?,
}

local function AspectRatioConstraint(props: AspectRatioConstraintProps)
	return create "UIAspectRatioConstraint"(props :: any)
end

return AspectRatioConstraint
