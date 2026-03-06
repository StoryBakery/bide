--[=[
    @class UIFlexItemWrapper
]=]

local Instance = require("../Instance")

local create = Instance.create

export type FlexItemProps = {
	FlexMode: Enum.UIFlexMode?,
	ItemLineAlignment: Enum.ItemLineAlignment?,
	GrowRatio: number?,
	ShrinkRatio: number?,
}

local function FlexItem(props: FlexItemProps)
	return create "UIFlexItem"(props :: any)
end

return FlexItem
