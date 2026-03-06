--[=[
    @class UISizeConstraintWrapper
]=]

local Instance = require("../Instance")

local create = Instance.create

type Prop<T> = T | (() -> T)

export type SizeConstraintProps = {
	MaxSize: Prop<Vector2>?,
	MinSize: Prop<Vector2>?,
}

local function SizeConstraint(props: SizeConstraintProps)
	return create "UISizeConstraint"(props :: any)
end

return SizeConstraint
