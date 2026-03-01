local vide = require("../../../src/vide")

local Components = require("../../../src/Components")
local Layout = require("../../../src/Layout")

local mount = vide.mount
local source = vide.source

local function createElement(index: number)
	local hue = (index % 36) / 36

	return {
		Key = index,
		Order = index,
		Element = function()
			return Components.Button({
				Size = UDim2.fromScale(1, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				Text = `Item {index}`,
				ButtonColor = Color3.fromHSV(hue, 0.2, 1),
				HighlightColor = Color3.fromHSV((hue + 0.5) % 1, 0.2, 1),
				TextColor3 = Color3.fromHSV((hue + 0.5) % 1, 1, 1),
			})
		end,
	}
end

local function App()
	local cursorIndex = source(1)

	local elements: { any } = {}
	for index = 1, 120 do
		elements[index] = createElement(index)
	end

	return Components.Frame({
		Size = UDim2.fromScale(1, 1),

		Layout.Padding({
			Padding = 12,
		}),

		Components.TextLabel({
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			Size = UDim2.fromOffset(320, 24),
			Text = function()
				return `Cursor: {cursorIndex()}`
			end,
		}),

		Components.CullingListFrame({
			Size = UDim2.fromOffset(360, 280),
			Position = UDim2.fromOffset(0, 28),
			Elements = elements,
			CursorIndex = cursorIndex(),
			OnCursorChange = function(nextValue: number)
				cursorIndex(nextValue)
			end,
			SortOrder = "Index" :: "Index",
			ScrollingDirection = "Y" :: "Y",
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
