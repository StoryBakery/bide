--[=[
	@class Ripple

	press 시 리플 이펙트를 생성하는 Behavior 입니다.
]=]

local DynamicTimer = require("../../roblox_packages/DynamicTimer")
local vide = require("../vide")

local effect = vide.effect
local read = vide.read

type Prop<T> = T | (() -> T)

export type RippleParams = {
	Color: Prop<Color3>?,
	ImageContent: Prop<Content>?,
	Transparency: Prop<number>?,
	ResolutionScale: Prop<number>?,
	Duration: number?,
}

local RIPPLE_DURATION = 0.5
local EMPTY_CONTENT = Content.fromUri("")

local function Ripple(params: RippleParams?)
	local p = params or {} :: RippleParams

	return {
		apply = function(instance: GuiObject, state: any?)
			local activeTweens: { [any]: true } = {}
			local cleanupThreads: { [thread]: true } = {}

			local function spawnRipple(inputObject: InputObject)
				local resolutionScale = (read(p.ResolutionScale) :: number?) or 1
				if resolutionScale <= 0 then
					resolutionScale = 1
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
				local largestSize = math.max(buttonSize.X, buttonSize.Y)
					* math.pi
					/ 2
					/ resolutionScale
				local startTransparency = ripple.ImageTransparency

				ripple.Position = UDim2.fromOffset(
					(inputObject.Position.X - instance.AbsolutePosition.X) / resolutionScale,
					(inputObject.Position.Y - instance.AbsolutePosition.Y) / resolutionScale
				)

				local duration = p.Duration or RIPPLE_DURATION
				local tween = DynamicTimer:CreateTween({
					Start = 0,
					Goal = 1,
					Duration = duration,
					Callback = function(progress: number)
						ripple.Size =
							UDim2.fromOffset(largestSize * progress, largestSize * progress)
						ripple.ImageTransparency = startTransparency
							+ (1 - startTransparency) * progress
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

			if state then
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
			end

			return {
				Destroy = function()
					for thread in cleanupThreads do
						task.cancel(thread)
					end
					for tween in activeTweens do
						if not tween.IsDestroyed then
							tween:Destroy()
						end
					end
				end,
			}
		end,
	}
end

return Ripple
