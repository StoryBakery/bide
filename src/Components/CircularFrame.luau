--[=[
	@class CircularFrame

	원형 진행 UI 를 렌더링하는 컴포넌트입니다.
]=]

local Instance = require("../Instance")
local TableUtil = require("../../roblox_packages/TableUtil")
local reactive = require("../Reactive")

local Frame = require("./Frame")
local Gradient = require("../Layout/Gradient")
local Props = require("../Utils/Props")

local create = Instance.create
local memo = reactive.memo
local read = reactive.read

type Prop<T> = T | (() -> T)

local OWN_PROPS_SCHEMA = {
	Class = Props.optional<<string>>(),
	StartProgress = Props.optional<<number>>(),
	EndProgress = Props.optional<<number>>(),
}

export type CircularFrameOwnProps = typeof(OWN_PROPS_SCHEMA)

export type CircularFrameProps = CircularFrameOwnProps & Frame.FrameProps

local OFFSET = 0.001

local CIRCLUAR_TRANSPARENCY_SEQUENCE = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0),
	NumberSequenceKeypoint.new(0.5, 0),
	NumberSequenceKeypoint.new(0.5 + OFFSET, 1),
	NumberSequenceKeypoint.new(1, 1),
})

local REVERSED_TRANSPARENCY_SEQUENCE = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.5 - OFFSET, 1),
	NumberSequenceKeypoint.new(0.5, 0),
	NumberSequenceKeypoint.new(1, 0),
})

type FollowedClone = {
	Clone: Instance,
	Destroy: () -> (),
}

local UNFOLLOWING_PROPERTY_SET = {
	Parent = true,
	AbsolutePosition = true,
	AbsoluteSize = true,
	AbsoluteRotation = true,
}

local function followCloningInstance(original: Instance): FollowedClone
	local cloned = original:Clone()
	local destroyed = false
	local clonedChildrenByOriginalChild = {} :: { [Instance]: FollowedClone }
	local connections = {} :: { RBXScriptConnection }

	local function destroyFollowedClone()
		if destroyed then
			return
		end
		destroyed = true

		for index = 1, #connections do
			connections[index]:Disconnect()
		end
		table.clear(connections)

		for originalChild, followedChild in clonedChildrenByOriginalChild do
			followedChild.Destroy()
			clonedChildrenByOriginalChild[originalChild] = nil
		end

		cloned:Destroy()
	end

	local originalChildren = original:GetChildren()
	local clonedChildren = cloned:GetChildren()
	for index = 1, #originalChildren do
		local originalChild = originalChildren[index]
		local followedChild = followCloningInstance(originalChild)
		clonedChildrenByOriginalChild[originalChild] = followedChild

		local existingClonedChild = clonedChildren[index]
		if existingClonedChild and existingClonedChild ~= followedChild.Clone then
			existingClonedChild:Destroy()
		end

		followedChild.Clone.Parent = cloned
	end

	connections[#connections + 1] = original.Changed:Connect(function(property)
		if destroyed or UNFOLLOWING_PROPERTY_SET[property] then
			return
		end

		pcall(function()
			(cloned :: any)[property] = (original :: any)[property]
		end)
	end)

	connections[#connections + 1] = original.ChildAdded:Connect(function(child)
		if destroyed then
			return
		end

		local followedChild = followCloningInstance(child)
		clonedChildrenByOriginalChild[child] = followedChild
		followedChild.Clone.Parent = cloned
	end)

	connections[#connections + 1] = original.ChildRemoved:Connect(function(child)
		local followedChild = clonedChildrenByOriginalChild[child]
		if followedChild == nil then
			return
		end

		followedChild.Destroy()
		clonedChildrenByOriginalChild[child] = nil
	end)

	return {
		Clone = cloned,
		Destroy = destroyFollowedClone,
	}
end

local function createPropChildrenContainer(positionX: number, childFolder: Instance)
	local followedFolder = followCloningInstance(childFolder)
	local clonedFolder = followedFolder.Clone :: GuiObject
	clonedFolder.Visible = true

	local props: { [any]: any } = {
		Size = UDim2.fromScale(2, 1),
		Position = UDim2.fromScale(positionX, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Attach = function()
			return followedFolder.Destroy
		end,
		clonedFolder,
	}

	return create "Frame"(props :: any)
end

local function createGradient(
	offsetX: number,
	rotationFn: () -> number,
	transparencySequence: NumberSequence
)
	return Gradient({
		Transparency = transparencySequence,
		Offset = Vector2.new(offsetX, 0),
		Rotation = function()
			return rotationFn() * 360
		end,
	})
end

local function computeAngles(startProgress: number, endProgress: number)
	local delta = endProgress - startProgress

	local startProgressDecimal = startProgress % 1
	local endProgressDecimal = endProgress % 1

	local gradientAngleR1 = 0
	local gradientAngleR1_1 = 0
	local gradientAngleR2 = 0

	local gradientAngleL1 = 0
	local gradientAngleL1_1 = 0
	local gradientAngleL2 = 0

	local canvasGroupR1Visible = true
	local canvasGroupR2Visible = false
	local canvasGroupL1Visible = true
	local canvasGroupL2Visible = false

	if 1 <= delta then
		gradientAngleR1 = 0
		gradientAngleR1_1 = 0.5
		gradientAngleL1 = 0.5
		gradientAngleL1_1 = 1
	elseif delta <= 0 then
		gradientAngleR1 = 0.5
		gradientAngleR1_1 = 0.5
		gradientAngleL1 = 1
		gradientAngleL1_1 = 1
	elseif 1 <= startProgressDecimal + delta then
		if delta <= 0.5 then
			if startProgressDecimal <= 0.5 then
				gradientAngleR1 = math.clamp(startProgressDecimal, 0, 0.5)
				gradientAngleR1_1 = 0.5
				gradientAngleL1 = 0.5
				gradientAngleL1_1 = math.clamp(endProgressDecimal, 0.5, 1)
			else
				gradientAngleR1 = 0
				gradientAngleR1_1 = math.clamp(endProgressDecimal, 0, 0.5)
				gradientAngleL1 = math.clamp(startProgressDecimal, 0.5, 1)
				gradientAngleL1_1 = 1
			end
		else
			if startProgressDecimal <= 0.5 then
				gradientAngleR1 = math.clamp(startProgressDecimal, 0, 0.5)
				gradientAngleR1_1 = 0.5
				gradientAngleL1 = math.clamp(startProgressDecimal, 0.5, 1)
				gradientAngleL1_1 = 1
				gradientAngleR2 = endProgressDecimal
				canvasGroupR2Visible = true
			else
				gradientAngleR1 = 0
				gradientAngleR1_1 = math.clamp(endProgressDecimal, 0, 0.5)
				gradientAngleL1 = math.clamp(startProgressDecimal, 0.5, 1)
				gradientAngleL1_1 = 1
				gradientAngleL2 = endProgressDecimal
				canvasGroupL2Visible = true
			end
		end
	else
		gradientAngleR1 = math.clamp(startProgressDecimal, 0, 0.5)
		gradientAngleR1_1 = math.clamp(endProgressDecimal, 0, 0.5)
		gradientAngleL1 = math.clamp(startProgressDecimal, 0.5, 1)
		gradientAngleL1_1 = math.clamp(endProgressDecimal, 0.5, 1)
	end

	return {
		gradientAngleR1 = gradientAngleR1,
		gradientAngleR1_1 = gradientAngleR1_1,
		gradientAngleR2 = gradientAngleR2,
		gradientAngleL1 = gradientAngleL1,
		gradientAngleL1_1 = gradientAngleL1_1,
		gradientAngleL2 = gradientAngleL2,
		canvasGroupR1Visible = canvasGroupR1Visible,
		canvasGroupR2Visible = canvasGroupR2Visible,
		canvasGroupL1Visible = canvasGroupL1Visible,
		canvasGroupL2Visible = canvasGroupL2Visible,
	}
end

local function CircularFrame(props: CircularFrameProps)
	local ownProps, forwardProps, propChildren = Props.splitProps(props, OWN_PROPS_SCHEMA)
	local base = {
		Class = (read(ownProps.Class) :: string?) or "CanvasGroup",
	}

	local childFolder = create "Frame" {
		Name = "CircularFrameChildren",

		Size = UDim2.fromScale(1, 1),
		Visible = false,
		propChildren,
	}

	local function getStartProgress()
		local value = read(ownProps.StartProgress)
		if value == nil then
			return 0
		end
		return value
	end

	local function getEndProgress()
		local value = read(ownProps.EndProgress)
		if value == nil then
			return 1
		end
		return value
	end

	local anglesSignal = memo(function()
		local startProgress = getStartProgress()
		local endProgress = getEndProgress()
		return computeAngles(startProgress, endProgress)
	end)

	local function angles()
		return anglesSignal()
	end

	local propsWithChildren = table.clone(propChildren)

	propsWithChildren[#propsWithChildren + 1] = childFolder

	local startProgressCanvasRight1 = create "CanvasGroup" {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,

		createGradient(-0.5, function()
			return angles().gradientAngleR1_1
		end, CIRCLUAR_TRANSPARENCY_SEQUENCE),

		createPropChildrenContainer(-1, childFolder),
	}

	propsWithChildren[#propsWithChildren + 1] = create "CanvasGroup" {
		Visible = function()
			return angles().canvasGroupR1Visible
		end,
		Size = UDim2.fromScale(0.5, 1),
		Position = UDim2.fromScale(0.5, 0),
		BackgroundTransparency = 1,

		createGradient(-0.5, function()
			return angles().gradientAngleR1
		end, REVERSED_TRANSPARENCY_SEQUENCE),

		startProgressCanvasRight1,
	}

	propsWithChildren[#propsWithChildren + 1] = create "CanvasGroup" {
		Visible = function()
			return angles().canvasGroupR2Visible
		end,
		Size = UDim2.fromScale(0.5, 1),
		Position = UDim2.fromScale(0.5, 0),
		BackgroundTransparency = 1,

		createGradient(-0.5, function()
			return angles().gradientAngleR2
		end, CIRCLUAR_TRANSPARENCY_SEQUENCE),

		createPropChildrenContainer(-1, childFolder),
	}

	local startProgressCanvasLeft1 = create "CanvasGroup" {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,

		createGradient(0.5, function()
			return angles().gradientAngleL1_1
		end, CIRCLUAR_TRANSPARENCY_SEQUENCE),

		createPropChildrenContainer(0, childFolder),
	}

	propsWithChildren[#propsWithChildren + 1] = create "CanvasGroup" {
		Visible = function()
			return angles().canvasGroupL1Visible
		end,
		Size = UDim2.fromScale(0.5, 1),
		Position = UDim2.fromScale(0, 0),
		BackgroundTransparency = 1,

		createGradient(0.5, function()
			return angles().gradientAngleL1
		end, REVERSED_TRANSPARENCY_SEQUENCE),

		startProgressCanvasLeft1,
	}

	propsWithChildren[#propsWithChildren + 1] = create "CanvasGroup" {
		Visible = function()
			return angles().canvasGroupL2Visible
		end,
		Size = UDim2.fromScale(0.5, 1),
		Position = UDim2.fromScale(0, 0),
		BackgroundTransparency = 1,

		createGradient(0.5, function()
			return angles().gradientAngleL2
		end, CIRCLUAR_TRANSPARENCY_SEQUENCE),

		createPropChildrenContainer(0, childFolder),
	}

	local frameProps = TableUtil.merge(base, forwardProps)
	if #propsWithChildren > 0 then
		table.move(propsWithChildren, 1, #propsWithChildren, #frameProps + 1, frameProps)
	end

	return Frame(frameProps)
end

return CircularFrame
