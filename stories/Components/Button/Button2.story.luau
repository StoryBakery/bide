local RunService = game:GetService("RunService")

local reactive = require("../../../src/Reactive")
local Renderer = require("../../../src/Renderer")

local Components = require("../../../src/Components")

local effect = reactive.effect
local mount = Renderer.mount
local source = reactive.source

local function BeatButton()
	local beat = source(0)

	effect(function()
		local time = 0
		local conn = RunService.Heartbeat:Connect(function(dt: number)
			time += dt * 2
			beat((math.sin(time) + 1) / 2)
		end)

		reactive.cleanup(conn)
		return nil
	end)

	return Components.Button({
		Size = UDim2.fromOffset(220, 42),
		Text = "Click Me",
		ButtonColor = function()
			return Color3.fromRGB(40, 40, 40):Lerp(Color3.fromRGB(230, 70, 80), beat())
		end,
		HighlightColor = function()
			return Color3.fromRGB(70, 70, 70):Lerp(Color3.fromRGB(255, 110, 120), beat())
		end,
		TextColor3 = function()
			return Color3.fromRGB(235, 235, 235):Lerp(Color3.fromRGB(255, 255, 255), beat())
		end,
	})
end

return function(target)
	local unmount = mount(function()
		return Components.Frame({
			Size = UDim2.fromScale(1, 1),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BeatButton(),
		})
	end, target)

	return function()
		unmount()
	end
end
