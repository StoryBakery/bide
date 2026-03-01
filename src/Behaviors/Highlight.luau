--[=[
	@class Highlight

	hover 시 BackgroundColor3를 트윈하는 Behavior 입니다.

	```luau
	Interactive({
		Highlight({ NormalColor = ..., HighlightColor = ... }),
	})
	```
]=]

local DynamicTimer = require("../../roblox_packages/DynamicTimer")
local vide = require("../vide")

local read = vide.read
local effect = vide.effect

type Prop<T> = T | (() -> T)

export type HighlightParams = {
	NormalColor: Prop<Color3>?,
	HighlightColor: Prop<Color3>?,
	Duration: number?,
}

local function Highlight(params: HighlightParams?)
	local p = params or {} :: HighlightParams
	local duration = p.Duration or 0.1

	return {
		apply = function(instance: GuiObject, state: any?)
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

			if state then
				effect(function()
					if state.isHovered() then
						tweenTo(read(highlightColor))
					else
						tweenTo(read(normalColor))
					end
				end)
			else
				local enterConn = instance.MouseEnter:Connect(function()
					tweenTo(read(highlightColor))
				end)
				local leaveConn = instance.MouseLeave:Connect(function()
					tweenTo(read(normalColor))
				end)
				vide.cleanup(enterConn)
				vide.cleanup(leaveConn)
			end

			return {
				Destroy = function()
					if currentTween then
						currentTween:Destroy()
					end
				end,
			}
		end,
	}
end

return Highlight
