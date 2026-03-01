--[=[
    @class UIGradientWrapper
]=]

local vide = require("../vide")

local Props = require("../Utils/Props")

local create = vide.create

local EMPTY_KEY_SET = {}

type Prop<T> = T | (() -> T)

export type GradientProps = {
	Enabled: Prop<boolean>?,
	Rotation: Prop<number>?,
	Color: Prop<ColorSequence>?,
	Transparency: Prop<NumberSequence>?,
	Offset: Prop<Vector2>?,
}

local function Gradient(props: GradientProps)
	local _, restProps = Props.splitProps(props :: any, EMPTY_KEY_SET)
	return create "UIGradient"(Props.composeProps({}, restProps :: any, props :: any))
end

return Gradient
