--[=[
	@class Ripple

	press 시 리플 이펙트를 생성하는 attachment입니다.
]=]

local DynamicTimer = require("../../roblox_packages/DynamicTimer")
local InputState = require("./InputState")
local reactive = require("../Reactive")

local acquireInputState = InputState.acquire
local effect = reactive.effect
local read = reactive.read

type Prop<T> = T | (() -> T)

export type RippleParams = {
	Color: Prop<Color3>?,
	ImageContent: Prop<Content>?,
	Transparency: Prop<number>?,
	DisplayScale: Prop<number>?,
	Duration: number?,
}

local RIPPLE_DURATION = 0.5
local EMPTY_CONTENT = Content.fromUri("")

local function Ripple(params: RippleParams?)
	local p = params or {} :: RippleParams

	return function(instance: GuiObject)
		local state, releaseInputState = acquireInputState(instance)
		local activeTweens: { [any]: true } = {}
		local cleanupThreads: { [thread]: true } = {}

		local function spawnRipple(inputObject: InputObject)
			local displayScale = (read(p.DisplayScale) :: number?) or 1
			if displayScale <= 0 then
				displayScale = 1
			end

			local ripple = Instance.new("ImageLabel")
			ripple.BackgroundTransparency = 1
			ripple.Size = UDim2.fromOffset(0, 0)
			ripple.AnchorPoint = Vector2.new(0.5, 0.5)
			ripple.ImageContent = (read(p.ImageContent) :: Content?) or EMPTY_CONTENT
			ripple.ImageColor3 = (read(p.Color) :: Color3?) or Color3.new(1, 1, 1)
			ripple.ImageTransparency = (read(p.Transparency) :: number?) or 0.5
			ripple.ScaleType = Enum.ScaleType.Fit
			ripple.Parent = instance

			local buttonSize = instance.AbsoluteSize
			local largestSize = math.max(buttonSize.X, buttonSize.Y) * math.pi / 2 / displayScale
			local startTransparency = ripple.ImageTransparency

			ripple.Position = UDim2.fromOffset(
				(inputObject.Position.X - instance.AbsolutePosition.X) / displayScale,
				(inputObject.Position.Y - instance.AbsolutePosition.Y) / displayScale
			)

			local duration = p.Duration or RIPPLE_DURATION
			local tween = DynamicTimer:CreateTween({
				Start = 0,
				Goal = 1,
				Duration = duration,
				Callback = function(progress: number)
					ripple.Size = UDim2.fromOffset(largestSize * progress, largestSize * progress)
					ripple.ImageTransparency = startTransparency + (1 - startTransparency) * progress
				end,
			})
			activeTweens[tween] = true
			tween:Play()

			local cleanupThread: thread
			cleanupThread = task.delay(duration, function()
				cleanupThreads[cleanupThread] = nil
				activeTweens[tween] = nil
				if not tween.IsDestroyed then
					tween:Destroy()
				end
				ripple:Destroy()
			end)
			cleanupThreads[cleanupThread] = true
		end

		local lastInput: InputObject? = nil
		effect(function()
			local pressed = state.isPressed()
			local inputObj = state.pressInputObject()
			if pressed and inputObj and inputObj ~= lastInput then
				lastInput = inputObj
				spawnRipple(inputObj)
			elseif not pressed then
				lastInput = nil
			end
		end)

		return function()
			releaseInputState()

			for thread in cleanupThreads do
				task.cancel(thread)
			end

			for tween in activeTweens do
				if not tween.IsDestroyed then
					tween:Destroy()
				end
			end
		end
	end
end

return Ripple
