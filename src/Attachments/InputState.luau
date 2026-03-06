--[=[
	@class InputState

	하나의 GuiObject 에 대한 hover/press 이벤트를 한 번만 연결하여
	여러 attachment가 공유할 수 있는 반응형 상태입니다.
]=]

local reactive = require("../Reactive")

local signal = reactive.signal

local function isClickInput(inputObject: InputObject): boolean
	local inputType = inputObject.UserInputType
	return inputType == Enum.UserInputType.MouseButton1
		or inputType == Enum.UserInputType.MouseButton2
		or inputType == Enum.UserInputType.MouseButton3
		or inputType == Enum.UserInputType.Touch
end

export type InputState = {
	isHovered: () -> boolean,
	isPressed: () -> boolean,
	pressInputObject: () -> InputObject?,
	Destroy: () -> (),
}

type InputStateRecord = {
	refCount: number,
	state: InputState,
}

local inputStateRecordByInstance = setmetatable({}, { __mode = "k" }) :: {
	[GuiObject]: InputStateRecord,
}

local function createInputState(instance: GuiObject): InputState
	local isHovered, setIsHovered = signal(false)
	local isPressed, setIsPressed = signal(false)
	local pressInputObject, setPressInputObject = signal(nil :: InputObject?)
	local destroyed = false

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
		if destroyed then
			return
		end

		destroyed = true
		mouseEnterConn:Disconnect()
		mouseLeaveConn:Disconnect()
		inputBeganConn:Disconnect()
	end

	return {
		isHovered = isHovered,
		isPressed = isPressed,
		pressInputObject = pressInputObject,
		Destroy = destroy,
	}
end

local function acquire(instance: GuiObject): (InputState, () -> ())
	local record = inputStateRecordByInstance[instance]

	if record == nil then
		record = {
			refCount = 0,
			state = createInputState(instance),
		}
		inputStateRecordByInstance[instance] = record
	end

	record.refCount += 1

	local released = false

	return record.state, function()
		if released then
			return
		end

		released = true
		record.refCount -= 1

		if record.refCount == 0 then
			record.state.Destroy()
			inputStateRecordByInstance[instance] = nil
		end
	end
end

return {
	acquire = acquire,
}
