local reactive = require("../../../../../src/Reactive")
local Renderer = require("../../../../../src/Renderer")

local Attachments = require("../../../../../src/Attachments")
local Components = require("../../../../../src/Components")
local Layout = require("../../../../../src/Layout")
local Area = require("../../../../../src/Contexts/Area")

local mount = Renderer.mount
local source = reactive.source

local function App()
	local area = reactive.useContext(Area) :: Area.AreaValue
	local value = source(0.5)

	local function onDragMove(delta)
		value(math.clamp(value() + delta, 0, 1))
	end

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

		Components.TextLabel({
			Size = UDim2.fromOffset(280, 24),
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = function()
				return string.format("Drag Value: %.3f", value())
			end,
		}),

		Components.Button({
			Size = UDim2.fromOffset(280, 34),
			Text = function()
				return string.format("Drag Me (%.3f)", value())
			end,
			Attach = {
				Attachments.DragAxis({
					UserInputManager = area.UserInputManager,
					SlideDirection = "X",
					OnDragMove = onDragMove,
				}),
			},
		}),

		Components.Frame({
			Size = UDim2.fromOffset(280, 14),
			BackgroundTransparency = 0.6,
			StrokeEnabled = false,

			Components.Frame({
				AnchorPoint = Vector2.zero,
				Size = function()
					return UDim2.fromScale(value(), 1)
				end,
				StrokeEnabled = false,
			}),
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
