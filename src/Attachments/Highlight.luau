--[=[
	@class Highlight

	hover 시 BackgroundColor3를 트윈하는 attachment입니다.

	```luau
	Frame({
		Attach = {
			Highlight({ NormalColor = ..., HighlightColor = ... }),
		},
	})
	```
]=]

local DynamicTimer = require("../../roblox_packages/DynamicTimer")
local InputState = require("./InputState")
local reactive = require("../Reactive")

local acquireInputState = InputState.acquire
local effect = reactive.effect
local read = reactive.read

type Prop<T> = T | (() -> T)

export type HighlightParams = {
	NormalColor: Prop<Color3>?,
	HighlightColor: Prop<Color3>?,
	Duration: number?,
}

local function Highlight(params: HighlightParams?)
	local p = params or {} :: HighlightParams
	local duration = p.Duration or 0.1

	return function(instance: GuiObject)
		local state, releaseInputState = acquireInputState(instance)
		local currentTween: any = nil

		local function tweenTo(goalColor: Color3)
			if currentTween then
				currentTween:Destroy()
			end
			local nextTween = DynamicTimer:CreateTween({
				Start = instance.BackgroundColor3,
				Goal = goalColor,
				Duration = duration,
				Callback = function(value: Color3)
					instance.BackgroundColor3 = value
				end,
			})
			currentTween = nextTween
			nextTween:Play()
		end

		local normalColor = p.NormalColor
		local highlightColor = p.HighlightColor

		if normalColor then
			instance.BackgroundColor3 = read(normalColor)
		end

		effect(function()
			if state.isHovered() then
				tweenTo(read(highlightColor))
			else
				tweenTo(read(normalColor))
			end
		end)

		return function()
			releaseInputState()

			if currentTween then
				currentTween:Destroy()
			end
		end
	end
end

return Highlight
