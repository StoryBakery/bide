--[=[
    @class UISizeConstraintWrapper
]=]

local vide = require("../vide")

local Props = require("../Utils/Props")

local create = vide.create

local EMPTY_KEY_SET = {}

type Prop<T> = T | (() -> T)

export type SizeConstraintProps = {
	MaxSize: Prop<Vector2>?,
	MinSize: Prop<Vector2>?,
}

local function SizeConstraint(props: SizeConstraintProps)
	local _, restProps = Props.splitProps(props :: any, EMPTY_KEY_SET)
	return create "UISizeConstraint"(Props.composeProps({}, restProps :: any, props :: any))
end

return SizeConstraint
