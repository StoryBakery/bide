--[=[
	@class PressScale

	hover/press 시 UIScale을 트윈하는 attachment입니다.
]=]

local DynamicTimer = require("../../roblox_packages/DynamicTimer")
local InputState = require("./InputState")
local reactive = require("../Reactive")

local acquireInputState = InputState.acquire
local effect = reactive.effect

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

	return function(instance: GuiObject)
		local state, releaseInputState = acquireInputState(instance)
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

		effect(function()
			if state.isPressed() then
				tweenTo(pressedScale)
			elseif state.isHovered() then
				tweenTo(hoverScale)
			else
				tweenTo(defaultScale)
			end
		end)

		return function()
			releaseInputState()

			if currentTween then
				currentTween:Destroy()
			end

			scale:Destroy()
		end
	end
end

return PressScale
