local vide = require("../../../src/vide")

local Components = require("../../../src/Components")
local Layout = require("../../../src/Layout")
local theme = require("../../../src/Contexts/Theme")

local mount = vide.mount
local source = vide.source

local function App()
	local selected = source(false)

	return Components.Frame({
		Size = UDim2.fromScale(1, 1),

		Layout.ListLayout({
			Padding = UDim.new(0, 8),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),

		Layout.Padding({
			Padding = 12,
		}),

		Components.Button({
			Size = UDim2.fromOffset(220, 40),
			Text = function()
				return if selected() then "선택됨" else "기본 버튼"
			end,
			ButtonColor = function()
				return if selected() then theme().ButtonSelected else theme().Button
			end,
			TextColor3 = function()
				return if selected() then theme().ButtonTextOnSelected else theme().ButtonText
			end,
			OnClick = function()
				selected(function(value)
					return not value
				end)
			end,
		}),

		Components.Button({
			Size = UDim2.fromOffset(220, 40),
			Text = "툴팁 버튼",
			TooltipText = "Hover Tooltip",
			AutoScaleEnabled = true,
		}),
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
