local vide = require("../../../src/vide")

local Components = require("../../../src/Components")
local Layout = require("../../../src/Layout")

local mount = vide.mount
local source = vide.source

local function App()
	local cursorIndex = source(1)

	local elements: { any } = {}
	for index = 1, 24 do
		local order = source(index)
		local hue = (index % 24) / 24

		elements[index] = {
			Key = `Node_{index}`,
			Order = function()
				return order()
			end,
			Element = function()
				return Components.Button({
					Size = UDim2.fromOffset(120, 120),
					Text = function()
						return string.format("[%02d] %.1f", index, order())
					end,
					ButtonColor = Color3.fromHSV(hue, 0.2, 1),
					HighlightColor = Color3.fromHSV((hue + 0.5) % 1, 0.2, 1),
					OnMouseButton1Click = function()
						order(order() + 1)
					end,
					OnMouseButton2Click = function()
						order(order() - 1)
					end,
				})
			end,
		}
	end

	return Components.Frame({
		Size = UDim2.fromScale(1, 1),

		Layout.Padding({
			Padding = 12,
		}),
		Components.TextLabel({
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(420, 24),
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = "Left Click: Order +1, Right Click: Order -1",
		}),

		Components.CullingListFrame({
			Size = UDim2.fromOffset(520, 180),
			Position = UDim2.fromOffset(0, 28),
			CursorIndex = cursorIndex(),
			OnCursorChange = function(nextValue: number)
				cursorIndex(nextValue)
			end,
			Elements = elements,
			SortOrder = "Order" :: "Order",
			ScrollingDirection = "X" :: "X",
			ReversesAlignment = true,
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
