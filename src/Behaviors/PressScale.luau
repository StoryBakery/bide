--[=[
	@class PressScale

	hover/press 시 UIScale을 트윈하는 Behavior 입니다.
]=]

local DynamicTimer = require("../../roblox_packages/DynamicTimer")
local vide = require("../vide")

local effect = vide.effect

export type PressScaleParams = {
	DefaultScale: number?,
	HoverScale: number?,
	PressedScale: number?,
	Duration: number?,
}

local function PressScale(params: PressScaleParams?)
	local p = params or {} :: PressScaleParams
	local defaultScale = p.DefaultScale or 1
	local hoverScale = p.HoverScale or 1.05
	local pressedScale = p.PressedScale or 0.95
	local duration = p.Duration or 0.2

	return {
		apply = function(instance: GuiObject, state: any?)
			local currentTween: any = nil
			local scale = Instance.new("UIScale")
			scale.Name = "PressScale"
			scale.Scale = defaultScale
			scale.Parent = instance

			local function tweenTo(goal: number)
				if currentTween then
					currentTween:Destroy()
				end
				local nextTween = DynamicTimer:CreateTween({
					Start = scale.Scale,
					Goal = goal,
					Duration = duration,
					Callback = function(value: number)
						scale.Scale = value
					end,
				})
				currentTween = nextTween
				nextTween:Play()
			end

			if state then
				effect(function()
					if state.isPressed() then
						tweenTo(pressedScale)
					elseif state.isHovered() then
						tweenTo(hoverScale)
					else
						tweenTo(defaultScale)
					end
				end)
			end

			return {
				Destroy = function()
					if currentTween then
						currentTween:Destroy()
					end
					scale:Destroy()
				end,
			}
		end,
	}
end

return PressScale
