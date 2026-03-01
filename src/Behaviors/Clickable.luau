--[=[
	@class Clickable

	click/hover 이벤트 콜백을 처리하는 Behavior 입니다.
]=]

local vide = require("../vide")

local effect = vide.effect

export type ClickableParams = {
	OnClick: ((inputObject: InputObject) -> ())?,
	OnMouseButton1Click: ((inputObject: InputObject) -> ())?,
	OnMouseButton2Click: ((inputObject: InputObject) -> ())?,
	OnMouseButton3Click: ((inputObject: InputObject) -> ())?,
	OnTouch: ((inputObject: InputObject) -> ())?,
	OnEnter: (() -> ())?,
	OnLeave: (() -> ())?,
	OnHoverBegin: (() -> ())?,
	OnHoverEnd: (() -> ())?,
	OnPressBegin: (() -> ())?,
	OnPressEnd: (() -> ())?,
	UserInputManager: any?,
}

local function isClickInput(inputObject: InputObject): boolean
	local t = inputObject.UserInputType
	return t == Enum.UserInputType.MouseButton1
		or t == Enum.UserInputType.MouseButton2
		or t == Enum.UserInputType.MouseButton3
		or t == Enum.UserInputType.Touch
end

local function dispatchByType(params: ClickableParams, inputObject: InputObject)
	if params.OnClick then
		task.defer(params.OnClick, inputObject)
	end

	local userInputType = inputObject.UserInputType
	if userInputType == Enum.UserInputType.MouseButton1 then
		if params.OnMouseButton1Click then
			task.defer(params.OnMouseButton1Click, inputObject)
		end
	elseif userInputType == Enum.UserInputType.MouseButton2 then
		if params.OnMouseButton2Click then
			task.defer(params.OnMouseButton2Click, inputObject)
		end
	elseif userInputType == Enum.UserInputType.MouseButton3 then
		if params.OnMouseButton3Click then
			task.defer(params.OnMouseButton3Click, inputObject)
		end
	elseif userInputType == Enum.UserInputType.Touch then
		if params.OnTouch then
			task.defer(params.OnTouch, inputObject)
		end
	end
end

local function Clickable(params: ClickableParams?)
	local p = params or {} :: ClickableParams

	return {
		apply = function(instance: GuiObject, state: any?)
			if state then
				-- InteractionState 사용
				local lastHovered = false
				effect(function()
					local hovered = state.isHovered()
					if hovered and not lastHovered then
						if p.OnEnter then
							task.spawn(p.OnEnter)
						end
						if p.OnHoverBegin then
							p.OnHoverBegin()
						end
					elseif not hovered and lastHovered then
						if p.OnLeave then
							task.spawn(p.OnLeave)
						end
						if p.OnHoverEnd then
							p.OnHoverEnd()
						end
					end
					lastHovered = hovered
				end)

				local lastInput: InputObject? = nil
				effect(function()
					local pressed = state.isPressed()
					local inputObj = state.pressInputObject()
					if pressed and inputObj and inputObj ~= lastInput then
						lastInput = inputObj

						local uim = p.UserInputManager
						if uim then
							local inputType = inputObj.UserInputType
							local changed = uim:_setInputKeyPressed(inputType, true)
							if changed then
								inputObj:GetPropertyChangedSignal("UserInputState"):Once(function()
									uim:_setInputKeyPressed(inputObj.UserInputType, false)
								end)
							end
						end

						if isClickInput(inputObj) then
							if p.OnPressBegin then
								p.OnPressBegin()
							end
							dispatchByType(p, inputObj)
						end
					elseif not pressed and lastInput then
						if p.OnPressEnd then
							p.OnPressEnd()
						end
						lastInput = nil
					end
				end)

				return { Destroy = function() end }
			end

			-- fallback: 직접 이벤트 연결
			local enterConn = instance.MouseEnter:Connect(function()
				if p.OnEnter then
					task.spawn(p.OnEnter)
				end
				if p.OnHoverBegin then
					p.OnHoverBegin()
				end
			end)

			local leaveConn = instance.MouseLeave:Connect(function()
				if p.OnLeave then
					task.spawn(p.OnLeave)
				end
				if p.OnHoverEnd then
					p.OnHoverEnd()
				end
			end)

			local inputConn = instance.InputBegan:Connect(function(inputObject)
				if not isClickInput(inputObject) then
					return
				end

				local uim = p.UserInputManager
				if uim then
					local inputType = inputObject.UserInputType
					local changed = uim:_setInputKeyPressed(inputType, true)
					if changed then
						inputObject:GetPropertyChangedSignal("UserInputState"):Once(function()
							uim:_setInputKeyPressed(inputObject.UserInputType, false)
						end)
					end
				end

				if p.OnPressBegin then
					p.OnPressBegin()
				end
				dispatchByType(p, inputObject)

				if p.OnPressEnd then
					inputObject:GetPropertyChangedSignal("UserInputState"):Once(function()
						p.OnPressEnd()
					end)
				end
			end)

			return {
				Destroy = function()
					enterConn:Disconnect()
					leaveConn:Disconnect()
					inputConn:Disconnect()
				end,
			}
		end,
	}
end

return Clickable
