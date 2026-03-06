--[=[
	@class HoverDelay

	hover 후 지정 시간 뒤에 콜백을 실행하는 attachment입니다.
]=]

local InputState = require("./InputState")
local reactive = require("../Reactive")

local acquireInputState = InputState.acquire
local effect = reactive.effect

export type HoverDelayParams = {
	DelaySeconds: number?,
	OnHover: (() -> ())?,
	OnLeave: (() -> ())?,
}

local function HoverDelay(params: HoverDelayParams?)
	local p = params or {} :: HoverDelayParams
	local delaySeconds = p.DelaySeconds or 0.2

	return function(instance: GuiObject)
		local state, releaseInputState = acquireInputState(instance)
		local delayThread: thread? = nil

		local function onHoverStart()
			if delayThread then
				task.cancel(delayThread)
			end
			if delaySeconds <= 0 then
				if p.OnHover then
					p.OnHover()
				end
				return
			end
			delayThread = task.delay(delaySeconds, function()
				delayThread = nil
				if p.OnHover then
					p.OnHover()
				end
			end)
		end

		local function onHoverEnd()
			if delayThread then
				task.cancel(delayThread)
				delayThread = nil
			end
			if p.OnLeave then
				p.OnLeave()
			end
		end

		effect(function()
			if state.isHovered() then
				onHoverStart()
			else
				onHoverEnd()
			end
		end)

		return function()
			releaseInputState()

			if delayThread then
				task.cancel(delayThread)
			end
		end
	end
end

return HoverDelay
