--[=[
	@class HoverDelay

	hover 후 지정 시간 뒤에 콜백을 실행하는 Behavior 입니다.
]=]

local vide = require("../vide")

local effect = vide.effect
local onCleanup = vide.onCleanup

export type HoverDelayParams = {
	DelaySeconds: number?,
	OnHover: (() -> ())?,
	OnLeave: (() -> ())?,
}

local function HoverDelay(params: HoverDelayParams?)
	local p = params or {} :: HoverDelayParams
	local delaySeconds = p.DelaySeconds or 0.2

	return {
		apply = function(instance: GuiObject, state: any?)
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

			if state then
				effect(function()
					if state.isHovered() then
						onHoverStart()
					else
						onHoverEnd()
					end
				end)
			else
				local enterConn = instance.MouseEnter:Connect(onHoverStart)
				local leaveConn = instance.MouseLeave:Connect(onHoverEnd)
				onCleanup(enterConn)
				onCleanup(leaveConn)
			end

			return {
				Destroy = function()
					if delayThread then
						task.cancel(delayThread)
					end
				end,
			}
		end,
	}
end

return HoverDelay
