--[=[
	@class InteractionState

	하나의 GuiObject 에 대한 hover/press 이벤트를 한 번만 연결하여
	여러 Behavior 가 공유할 수 있는 반응형 상태입니다.
]=]

local vide = require("../vide")

local signal = vide.signal
local onCleanup = vide.onCleanup

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
	local isHovered, setIsHovered = signal(false)
	local isPressed, setIsPressed = signal(false)
	local pressInputObject, setPressInputObject = signal(nil :: InputObject?)

	local mouseEnterConn = instance.MouseEnter:Connect(function()
		setIsHovered(true)
	end)

	local mouseLeaveConn = instance.MouseLeave:Connect(function()
		setIsHovered(false)
	end)

	local inputBeganConn = instance.InputBegan:Connect(function(inputObject)
		if not isClickInput(inputObject) then
			return
		end
		setIsPressed(true)
		setPressInputObject(inputObject)
		inputObject:GetPropertyChangedSignal("UserInputState"):Once(function()
			setIsPressed(false)
			setPressInputObject(nil)
		end)
	end)

	local function destroy()
		mouseEnterConn:Disconnect()
		mouseLeaveConn:Disconnect()
		inputBeganConn:Disconnect()
	end

	onCleanup(destroy)

	return {
		isHovered = isHovered,
		isPressed = isPressed,
		pressInputObject = pressInputObject,
		Destroy = destroy,
	}
end

return createInteractionState
