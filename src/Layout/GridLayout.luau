--[=[
    @class UIGridLayoutWrapper
]=]

local vide = require("../vide")

local Props = require("../Utils/Props")

local create = vide.create

local EMPTY_KEY_SET = {}

export type GridLayoutProps = {
	SortOrder: Enum.SortOrder?,

	CellSize: UDim2?,
	CellPadding: UDim2?,

	FillDirection: Enum.FillDirection?,
	HorizontalAlignment: Enum.HorizontalAlignment?,
	VerticalAlignment: Enum.VerticalAlignment?,

	FillDirectionMaxCells: number?,

	StartCorner: Enum.StartCorner?,
}

local function UIGridLayout(props: GridLayoutProps)
	local _, restProps = Props.splitProps(props :: any, EMPTY_KEY_SET)
	return create "UIGridLayout"(Props.composeProps({}, restProps :: any, props :: any))
end

return UIGridLayout
