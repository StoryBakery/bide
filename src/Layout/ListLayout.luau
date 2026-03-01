--[=[
	@class ListLayout

	UIListLayout 래퍼입니다.
]=]

local vide = require("../vide")

local create = vide.create
local read = vide.read

type Prop<T> = T | (() -> T)

export type ListLayoutProps = {
	FillDirection: Prop<Enum.FillDirection>?,
	Padding: Prop<number | UDim>?,
	VerticalAlignment: Prop<Enum.VerticalAlignment>?,
	HorizontalAlignment: Prop<Enum.HorizontalAlignment>?,
	SortOrder: Prop<Enum.SortOrder>?,
	HorizontalFlex: Prop<Enum.UIFlexAlignment>?,
	VerticalFlex: Prop<Enum.UIFlexAlignment>?,
	Wraps: Prop<boolean>?,
}

local function toUDimPadding(value: number | UDim | nil): UDim
	if value == nil then
		return UDim.new(0, 0)
	end
	if typeof(value) == "UDim" then
		return value
	end
	return UDim.new(0, value :: number)
end

local function ListLayout(props: ListLayoutProps?): Instance
	local p = props or {} :: ListLayoutProps

	return create "UIListLayout" {
		FillDirection = function()
			return read(p.FillDirection) or Enum.FillDirection.Vertical
		end,
		Padding = function()
			return toUDimPadding(read(p.Padding))
		end,
		VerticalAlignment = function()
			return read(p.VerticalAlignment) or Enum.VerticalAlignment.Top
		end,
		HorizontalAlignment = function()
			return read(p.HorizontalAlignment) or Enum.HorizontalAlignment.Left
		end,
		SortOrder = function()
			return read(p.SortOrder) or Enum.SortOrder.LayoutOrder
		end,
		HorizontalFlex = p.HorizontalFlex,
		VerticalFlex = p.VerticalFlex,
		Wraps = p.Wraps,
	}
end

return ListLayout
