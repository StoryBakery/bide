--[=[
    @class UIGridLayoutWrapper
]=]

local Instance = require("../Instance")

local create = Instance.create

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
	return create "UIGridLayout"(props :: any)
end

return UIGridLayout
