--[=[
	@class Tooltip

	hover 시 툴팁을 표시하는 Behavior 입니다.
]=]

local vide = require("../vide")

local effect = vide.effect
local signal = vide.signal
local onCleanup = vide.onCleanup
local read = vide.read
local create = vide.create

type Prop<T> = T | (() -> T)

export type TooltipParams = {
	Text: Prop<string>?,
	DelaySeconds: number?,
}

local function Tooltip(params: TooltipParams?)
	local p = params or {} :: TooltipParams
	local delaySeconds = p.DelaySeconds or 0.5

	return {
		apply = function(instance: GuiObject, state: any?)
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

			if state then
				effect(function()
					if state.isHovered() then
						showDelayed()
					else
						hide()
					end
				end)
			else
				local enterConn = instance.MouseEnter:Connect(showDelayed)
				local leaveConn = instance.MouseLeave:Connect(hide)
				onCleanup(enterConn)
				onCleanup(leaveConn)
			end

			local tooltip = vide.show(isVisible, function()
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

			return {
				Destroy = function()
					hide()
					tooltip:Destroy()
				end,
			}
		end,
	}
end

return Tooltip
