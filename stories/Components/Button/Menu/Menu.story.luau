local vide = require("../../../../src/vide")

local Components = require("../../../../src/Components")
local Layout = require("../../../../src/Layout")

local mount = vide.mount
local source = vide.source

type MenuItem = {
	Name: string,
	IconContent: Content?,
}

local ITEMS: { MenuItem } = {
	{
		Name = "Alpha",
		IconContent = Content.fromAssetId(5816944720),
	},
	{
		Name = "Bravo",
		IconContent = Content.fromAssetId(17341357210),
	},
	{
		Name = "Charlie",
		IconContent = Content.fromAssetId(184767240),
	},
	{
		Name = "Delta",
		IconContent = nil,
	},
}

local function App()
	local selectedItemName = source("Bravo")

	local children: { any } = {
		Layout.ListLayout({
			Padding = 8,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Top,
		}),
		Layout.Padding({
			Padding = 12,
		}),
		Components.TextLabel({
			Size = UDim2.fromOffset(260, 24),
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = function()
				return `Selected: {selectedItemName()}`
			end,
		}),
	}

	for index = 1, #ITEMS do
		local item = ITEMS[index]
		children[#children + 1] = Components.Button({
			Size = UDim2.fromOffset(260, 34),
			IconContent = item.IconContent,
			Text = item.Name,
			OnClick = function()
				selectedItemName(item.Name)
			end,
		})
	end

	local frameProps: { [any]: any } = {
		Size = UDim2.fromScale(1, 1),
	}
	for index = 1, #children do
		frameProps[#frameProps + 1] = children[index]
	end

	return Components.Frame(frameProps)
end

return function(target)
	local unmount = mount(function()
		return App()
	end, target)

	return function()
		unmount()
	end
end
