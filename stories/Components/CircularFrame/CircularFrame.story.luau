local RunService = game:GetService("RunService")

local vide = require("../../../src/vide")

local Components = require("../../../src/Components")
local Layout = require("../../../src/Layout")

local effect = vide.effect
local mount = vide.mount
local source = vide.source

local function clampProgress(value: number): number
	return math.clamp(value, 0, 1)
end

local function App()
	local autoProgressEnabled = source(true)
	local startProgress = source(0.1)
	local endProgress = source(0.7)

	effect(function()
		local conn = RunService.RenderStepped:Connect(function(dt: number)
			if not autoProgressEnabled() then
				return
			end

			local nextStartProgress = (startProgress() + dt * 0.15) % 1
			local nextEndProgress = (nextStartProgress + 0.6) % 1
			startProgress(nextStartProgress)
			endProgress(nextEndProgress)
		end)

		vide.cleanup(conn)
		return nil
	end)

	return Components.Frame({
		Size = UDim2.fromScale(1, 1),

		Layout.Padding({
			Padding = 12,
		}),
		Layout.ListLayout({
			Padding = 8,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),

		Components.CircularFrame({
			Size = UDim2.fromOffset(220, 220),
			StartProgress = startProgress,
			EndProgress = endProgress,

			Layout.AspectRatio({
				AspectRatio = 1,
			}),
			Components.ImageLabel({
				ImageContent = Content.fromAssetId(11813117028),
			}),
		}),

		Components.TextLabel({
			Size = UDim2.fromOffset(260, 24),
			BackgroundTransparency = 1,
			Text = function()
				return string.format("start=%.3f / end=%.3f", startProgress(), endProgress())
			end,
		}),

		Components.Button({
			Size = UDim2.fromOffset(260, 34),
			Text = function()
				if autoProgressEnabled() then
					return "Disable Auto Progress"
				end

				return "Enable Auto Progress"
			end,
			OnClick = function()
				autoProgressEnabled(function(value)
					return not value
				end)
			end,
		}),

		Components.Button({
			Size = UDim2.fromOffset(260, 34),
			Text = "Advance Start +0.05",
			OnClick = function()
				startProgress(clampProgress(startProgress() + 0.05))
			end,
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
