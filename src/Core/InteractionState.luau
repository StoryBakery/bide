--[=[
	@class InteractionState

	하나의 GuiObject 에 대한 hover/press 이벤트를 한 번만 연결하여
	여러 Behavior 가 공유할 수 있는 반응형 상태입니다.
]=]

local vide = require("../vide")

local source = vide.source
local cleanup = vide.cleanup

local function isClickInput(inputObject: InputObject): boolean
	local inputType = inputObject.UserInputType
	return inputType == Enum.UserInputType.MouseButton1
		or inputType == Enum.UserInputType.MouseButton2
		or inputType == Enum.UserInputType.MouseButton3
		or inputType == Enum.UserInputType.Touch
end

export type InteractionState = {
	isHovered: () -> boolean,
	isPressed: () -> boolean,
	pressInputObject: () -> InputObject?,
	Destroy: () -> (),
}

local function createInteractionState(instance: GuiObject): InteractionState
	local isHovered = source(false)
	local isPressed = source(false)
	local pressInputObject = source(nil :: InputObject?)

	local mouseEnterConn = instance.MouseEnter:Connect(function()
		isHovered(true)
	end)

	local mouseLeaveConn = instance.MouseLeave:Connect(function()
		isHovered(false)
	end)

	local inputBeganConn = instance.InputBegan:Connect(function(inputObject)
		if not isClickInput(inputObject) then
			return
		end
		isPressed(true)
		pressInputObject(inputObject)
		inputObject:GetPropertyChangedSignal("UserInputState"):Once(function()
			isPressed(false)
			pressInputObject(nil)
		end)
	end)

	local function destroy()
		mouseEnterConn:Disconnect()
		mouseLeaveConn:Disconnect()
		inputBeganConn:Disconnect()
	end

	cleanup(destroy)

	return {
		isHovered = isHovered,
		isPressed = isPressed,
		pressInputObject = pressInputObject,
		Destroy = destroy,
	}
end

return createInteractionState
