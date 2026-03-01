--[=[
	@class FadeAnimator

	CullingListFrame의 요소 등장/사라짐 트윈 애니메이션을 담당합니다.
]=]

local DynamicTimer = require("../../../roblox_packages/DynamicTimer")

export type FadeAnimatorConfig = {
	GetFadeDuration: () -> number,
	GetProgressesByIndex: () -> { [number]: number },
	SetProgressesByIndex: (({ [number]: number }) -> { [number]: number }) -> (),
	GetUpProgressesByIndex: () -> { [number]: number },
	SetUpProgressesByIndex: (({ [number]: number }) -> { [number]: number }) -> (),
	GetDownProgressesByIndex: () -> { [number]: number },
	SetDownProgressesByIndex: (({ [number]: number }) -> { [number]: number }) -> (),
}

export type FadeAnimator = {
	TweenProgressFromIndex: (
		index: number,
		startProgress: number,
		goalProgress: number,
		callback: (number) -> (),
		onEnd: (() -> ())?
	) -> (),
	TweenCursorUp: (cursorIndex: number, lastCursorIndex: number) -> (),
	TweenCursorDown: (lastCursorIndex: number, cursorIndex: number) -> (),
	TweenRenderMaxExpand: (
		lastRenderMaxIndex: number,
		renderMaxIndex: number,
		cursorIndex: number
	) -> (),
	TweenRenderMaxShrink: (
		renderMaxIndex: number,
		lastRenderMaxIndex: number,
		cursorIndex: number
	) -> (),
	DestroyAllTweens: () -> (),
}

local function createFadeAnimator(config: FadeAnimatorConfig): FadeAnimator
	local progressTweensByIndex = {} :: { [number]: DynamicTimer.DynamicTween }

	local function tweenProgressFromIndex(
		index: number,
		startProgress: number,
		goalProgress: number,
		callback: (number) -> (),
		onEnd: (() -> ())?
	)
		if progressTweensByIndex[index] then
			progressTweensByIndex[index]:Destroy()
		end

		local progressTween = DynamicTimer:CreateTween({
			Start = startProgress,
			Goal = goalProgress,
			Duration = config.GetFadeDuration(),
			Callback = callback,
		}) :: DynamicTimer.DynamicTween
		progressTween:Play()
		progressTweensByIndex[index] = progressTween
		progressTween.Completed:Once(function()
			if onEnd then
				onEnd()
			end
			if progressTween.IsDestroyed then
				return
			end
			progressTweensByIndex[index] = nil
		end)
	end

	local function tweenCursorUp(cursorIndex: number, lastCursorIndex: number)
		local progressesByIndex = config.GetProgressesByIndex()

		for index = cursorIndex, lastCursorIndex do
			local startProgress = progressesByIndex[index] or 0
			if startProgress == 1 then
				continue
			end
			tweenProgressFromIndex(index, startProgress, 1, function(p)
				config.SetProgressesByIndex(function(prev)
					prev[index] = p
					return prev
				end)
				config.SetUpProgressesByIndex(function(prev)
					prev[index] = 1 - (p :: number)
					return prev
				end)
			end, function()
				config.SetUpProgressesByIndex(function(prev)
					prev[index] = 0
					return prev
				end)
			end)
		end
	end

	local function tweenCursorDown(lastCursorIndex: number, cursorIndex: number)
		local progressesByIndex = config.GetProgressesByIndex()

		for index = lastCursorIndex, cursorIndex - 1 do
			local startProgress = progressesByIndex[index] or 0
			if startProgress == 0 then
				continue
			end
			tweenProgressFromIndex(index, startProgress, 0, function(p)
				config.SetProgressesByIndex(function(prev)
					prev[index] = p
					return prev
				end)
				config.SetDownProgressesByIndex(function(prev)
					prev[index] = 1 - (p :: number)
					return prev
				end)
			end, function()
				config.SetDownProgressesByIndex(function(prev)
					prev[index] = 0
					return prev
				end)
			end)
		end
	end

	local function tweenRenderMaxExpand(
		lastRenderMaxIndex: number,
		renderMaxIndex: number,
		cursorIndex: number
	)
		local progressesByIndex = config.GetProgressesByIndex()

		for index = math.max(lastRenderMaxIndex + 1, cursorIndex), renderMaxIndex do
			local startProgress = progressesByIndex[index] or 0
			if startProgress == 1 then
				continue
			end

			tweenProgressFromIndex(index, startProgress, 1, function(p)
				config.SetProgressesByIndex(function(prev)
					prev[index] = p
					return prev
				end)
			end)
		end
	end

	local function tweenRenderMaxShrink(
		renderMaxIndex: number,
		lastRenderMaxIndex: number,
		cursorIndex: number
	)
		local progressesByIndex = config.GetProgressesByIndex()

		for index = renderMaxIndex + 1, lastRenderMaxIndex do
			local startProgress = progressesByIndex[index] or 0

			if index < cursorIndex then
				config.SetProgressesByIndex(function(prev)
					prev[index] = 0
					return prev
				end)
			else
				tweenProgressFromIndex(index, startProgress, 0, function(p)
					config.SetProgressesByIndex(function(prev)
						prev[index] = p
						return prev
					end)
				end)
			end
		end
	end

	local function destroyAllTweens()
		for index, progressTween in progressTweensByIndex do
			progressTween:Destroy()
			progressTweensByIndex[index] = nil
		end
	end

	return {
		TweenProgressFromIndex = tweenProgressFromIndex,
		TweenCursorUp = tweenCursorUp,
		TweenCursorDown = tweenCursorDown,
		TweenRenderMaxExpand = tweenRenderMaxExpand,
		TweenRenderMaxShrink = tweenRenderMaxShrink,
		DestroyAllTweens = destroyAllTweens,
	}
end

return createFadeAnimator
