--[=[
    @class UIGradientWrapper
]=]

local Instance = require("../Instance")

local create = Instance.create

type Prop<T> = T | (() -> T)

export type GradientProps = {
	Enabled: Prop<boolean>?,
	Rotation: Prop<number>?,
	Color: Prop<ColorSequence>?,
	Transparency: Prop<NumberSequence>?,
	Offset: Prop<Vector2>?,
}

local function Gradient(props: GradientProps)
	return create "UIGradient"(props :: any)
end

return Gradient
