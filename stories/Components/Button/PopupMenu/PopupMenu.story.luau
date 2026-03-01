local vide = require("../../../../src/vide")

local Components = require("../../../../src/Components")
local Layout = require("../../../../src/Layout")

local mount = vide.mount
local source = vide.source

local POPUP_BUTTON_NAMES = {
	"Open",
	"Rename",
	"Duplicate",
	"Delete",
}

local function App()
	local isPopupVisible = source(false)
	local lastSelectedButtonName = source("None")

	local popupChildren: { any } = {
		Layout.ListLayout({
			Padding = 4,
		}),
		Layout.Padding({
			Padding = 6,
		}),
	}

	for index = 1, #POPUP_BUTTON_NAMES do
		local buttonName = POPUP_BUTTON_NAMES[index]
		popupChildren[#popupChildren + 1] = Components.Button({
			Size = UDim2.fromOffset(170, 28),
			Text = buttonName,
			OnClick = function()
				lastSelectedButtonName(buttonName)
				isPopupVisible(false)
			end,
		})
	end

	local popupPanelProps: { [any]: any } = {
		Name = "PopupPanel",
		Position = UDim2.fromOffset(0, 72),
		Size = UDim2.fromOffset(190, 150),
		Visible = function()
			return isPopupVisible()
		end,
	}
	for index = 1, #popupChildren do
		popupPanelProps[#popupPanelProps + 1] = popupChildren[index]
	end

	return Components.Frame({
		Size = UDim2.fromScale(1, 1),
		Layout.Padding({
			Padding = 12,
		}),

		Components.Button({
			Size = UDim2.fromOffset(220, 34),
			Text = function()
				if isPopupVisible() then
					return "Hide Popup"
				end

				return "Show Popup"
			end,
			OnClick = function()
				isPopupVisible(function(value)
					return not value
				end)
			end,
		}),

		Components.TextLabel({
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, 44),
			Size = UDim2.fromOffset(260, 24),
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = function()
				return `Last Selected: {lastSelectedButtonName()}`
			end,
		}),
		Components.Frame(popupPanelProps),
	})
end

return function(target)
	local unmount = mount(function()
		return App()
	end, target)

	return function()
		unmount()
	end
end
