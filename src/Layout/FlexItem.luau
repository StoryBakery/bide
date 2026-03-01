--[=[
    @class UIFlexItemWrapper
]=]

local vide = require("../vide")

local Props = require("../Utils/Props")

local create = vide.create

local EMPTY_KEY_SET = {}

export type FlexItemProps = {
	FlexMode: Enum.UIFlexMode?,
	ItemLineAlignment: Enum.ItemLineAlignment?,
	GrowRatio: number?,
	ShrinkRatio: number?,
}

local function FlexItem(props: FlexItemProps)
	local _, restProps = Props.splitProps(props :: any, EMPTY_KEY_SET)
	return create "UIFlexItem"(Props.composeProps({}, restProps :: any, props :: any))
end

return FlexItem
