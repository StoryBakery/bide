--[=[
	@class Tooltip

	hover 시 툴팁을 표시하는 attachment입니다.
]=]

local InputState = require("./InputState")
local reactive = require("../Reactive")
local Instance = require("../Instance")

local acquireInputState = InputState.acquire
local effect = reactive.effect
local signal = reactive.signal
local read = reactive.read
local create = Instance.create

type Prop<T> = T | (() -> T)

export type TooltipParams = {
	Text: Prop<string>?,
	DelaySeconds: number?,
}

local function Tooltip(params: TooltipParams?)
	local p = params or {} :: TooltipParams
	local delaySeconds = p.DelaySeconds or 0.5

	return function(instance: GuiObject)
		local state, releaseInputState = acquireInputState(instance)
		local isVisible, setIsVisible = signal(false)
		local delayThread: thread? = nil

		local function showDelayed()
			if delayThread then
				task.cancel(delayThread)
			end
			delayThread = task.delay(delaySeconds, function()
				setIsVisible(true)
				delayThread = nil
			end)
		end

		local function hide()
			if delayThread then
				task.cancel(delayThread)
				delayThread = nil
			end
			setIsVisible(false)
		end

		effect(function()
			if state.isHovered() then
				showDelayed()
			else
				hide()
			end
		end)

		local tooltip = reactive.show(isVisible, function()
			return create "TextLabel" {
				Name = "Tooltip",
				BackgroundColor3 = Color3.fromRGB(40, 40, 40),
				BackgroundTransparency = 0.1,
				TextColor3 = Color3.fromRGB(220, 220, 220),
				AutomaticSize = Enum.AutomaticSize.XY,
				Size = UDim2.fromOffset(0, 0),
				Position = UDim2.new(0.5, 0, 0, -4),
				AnchorPoint = Vector2.new(0.5, 1),
				Text = function()
					return read(p.Text) or ""
				end,
				TextSize = 12,
				ZIndex = 999,
				BorderSizePixel = 0,
				create "UIPadding" {
					PaddingLeft = UDim.new(0, 6),
					PaddingRight = UDim.new(0, 6),
					PaddingTop = UDim.new(0, 3),
					PaddingBottom = UDim.new(0, 3),
				},
				create "UICorner" {
					CornerRadius = UDim.new(0, 4),
				},
			}
		end)

		tooltip.Parent = instance

		return function()
			releaseInputState()
			hide()
			tooltip:Destroy()
		end
	end
end

return Tooltip
