--[=[
	Axis 드래그 attachment 모듈입니다.
]=]

local RunService = if game then game:GetService("RunService") else nil
local UserInputService = if game then game:GetService("UserInputService") else nil

export type AxisParams = {
	UserInputManager: any,
	SlideDirection: "X" | "Y"?,
	MouseIcon: any?,
	MouseIconPriority: number?,
	EnableShiftSlow: boolean?,
	ShiftSlowScale: number?,
	WheelWhileDraggingScale: number?,
	OnDragStart: ((instance: GuiObject) -> ())?,
	OnDragMove: ((delta: number, instance: GuiObject) -> ())?,
	OnWheelWhileDragging: ((delta: number, instance: GuiObject) -> ())?,
	OnDragEnd: ((instance: GuiObject) -> ())?,
}

local dragStepCallbacksByToken = {} :: { [any]: () -> () }
local dragStepConnection: RBXScriptConnection?

local function updateDragStepConnection()
	if dragStepConnection and next(dragStepCallbacksByToken) == nil then
		dragStepConnection:Disconnect()
		dragStepConnection = nil
	end
end

local function addDragStepCallback(token: any, callback: () -> ())
	dragStepCallbacksByToken[token] = callback
	if dragStepConnection == nil then
		dragStepConnection = RunService.RenderStepped:Connect(function()
			for _, dragStepCallback in dragStepCallbacksByToken do
				dragStepCallback()
			end

			updateDragStepConnection()
		end)
	end
end

local function removeDragStepCallback(token: any)
	dragStepCallbacksByToken[token] = nil
	updateDragStepConnection()
end

local function isDragInput(inputObject: InputObject): boolean
	local inputType = inputObject.UserInputType
	return inputType == Enum.UserInputType.MouseButton1 or inputType == Enum.UserInputType.Touch
end

local function Axis(params: AxisParams)
	local slideDirection = params.SlideDirection or "X"
	local mouseIconPriority = params.MouseIconPriority or 0
	local enableShiftSlow = if params.EnableShiftSlow == nil then true else params.EnableShiftSlow
	local shiftSlowScale = if params.ShiftSlowScale ~= nil then params.ShiftSlowScale else 0.1
	local wheelWhileDraggingScale = if params.WheelWhileDraggingScale ~= nil
		then params.WheelWhileDraggingScale
		else 0

	return function(instance: GuiObject)
		if RunService == nil or UserInputService == nil then
			error("DragAxis requires Roblox services", 0)
		end

		local guiObject = instance :: GuiObject
		local userInputManager = params.UserInputManager

		local isDragging = false
		local contextMouseIcon: { Destroy: (any) -> () }?
		local inputChangedConn: RBXScriptConnection?
		local dragStepToken = {}

		local function getMouseProgress(): number
			local absoluteSize = guiObject.AbsoluteSize
			local mousePosition = userInputManager:GetMousePosition()

			if slideDirection == "Y" then
				if absoluteSize.Y == 0 then
					return 0
				end

				return -mousePosition.Y / absoluteSize.Y
			end

			if absoluteSize.X == 0 then
				return 0
			end

			return mousePosition.X / absoluteSize.X
		end

		local function stopDrag()
			if not isDragging then
				return
			end

			isDragging = false

			removeDragStepCallback(dragStepToken)

			if params.OnDragEnd then
				params.OnDragEnd(guiObject)
			end

			if contextMouseIcon then
				contextMouseIcon:Destroy()
				contextMouseIcon = nil
			end
		end

		local inputBeganConn = guiObject.InputBegan:Connect(function(inputObject: InputObject)
			if not isDragInput(inputObject) then
				return
			end

			if isDragging then
				return
			end

			isDragging = true

			if params.OnDragStart then
				params.OnDragStart(guiObject)
			end

			if params.MouseIcon then
				contextMouseIcon = userInputManager
					:GetMouse()
					:AddContextMouseIcon(params.MouseIcon, mouseIconPriority)
			end

			local lastMouseProgress = getMouseProgress()
			removeDragStepCallback(dragStepToken)
			addDragStepCallback(dragStepToken, function()
				if
					not userInputManager:IsInputKeyPressed(
						Enum.UserInputType.MouseButton1,
						Enum.UserInputType.Touch
					)
				then
					stopDrag()
					return
				end

				local currentMouseProgress = getMouseProgress()
				local delta = currentMouseProgress - lastMouseProgress
				if
					enableShiftSlow
					and userInputManager:IsInputKeyPressed(
						Enum.KeyCode.LeftShift,
						Enum.KeyCode.RightShift
					)
				then
					delta *= shiftSlowScale
				end

				if params.OnDragMove then
					params.OnDragMove(delta, guiObject)
				end

				lastMouseProgress = currentMouseProgress
			end)
		end)

		inputChangedConn = UserInputService.InputChanged:Connect(function(inputObject: InputObject)
			if not isDragging then
				return
			end

			if inputObject.UserInputType ~= Enum.UserInputType.MouseWheel then
				return
			end

			if params.OnWheelWhileDragging then
				params.OnWheelWhileDragging(
					inputObject.Position.Z * wheelWhileDraggingScale,
					guiObject
				)
			end
		end)

		local ancestryConn = guiObject.AncestryChanged:Connect(function(_, parent)
			if parent == nil then
				stopDrag()
			end
		end)

		return function()
			stopDrag()
			inputBeganConn:Disconnect()

			if inputChangedConn then
				inputChangedConn:Disconnect()
			end

			ancestryConn:Disconnect()
		end
	end
end

return Axis
