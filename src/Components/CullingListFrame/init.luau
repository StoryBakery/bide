--[=[
	@class CullingListFrame

	버추얼 스크롤이 필요한 긴 리스트를 렌더링하는 videKit 컴포넌트입니다.
	보이지 않는 요소는 생성하지 않고, 스크롤 위치 변경 시 자연스러운 페이드/슬라이드 애니메이션을 제공합니다.
]=]

local RunService = game:GetService("RunService")

local DynamicTimer = require("../../roblox_packages/DynamicTimer")
local LinearInterpolation = require("../../roblox_packages/LinearInterpolation") :: any
local vide = require("../vide")

local Button = require("./Button")
local Frame = require("./Frame")
local Props = require("../Utils/Props")
local area = require("../Contexts/Area")
local theme = require("../Contexts/Theme")

local create = vide.create
local effect = vide.effect
local signal = vide.signal
local onCleanup = vide.onCleanup
local read = vide.read

type ElementFactory = () -> GuiObject
type ElementLike = GuiObject | ElementFactory
type ElementEntry = ElementLike | {
	Key: any?,
	Order: number | (() -> number)?,
	Element: ElementLike,
}

--[=[
	@interface CullingListFrameProps
	@within CullingListFrame

	CullingListFrame 이 요구하는 속성입니다.

	.ScrollingEnabled boolean? -- [[
		false 로 지정하면 마우스 휠 입력을 무시합니다
		@default true
	]]
	.ScrollingDirection "X" | "Y"? -- [[
		스크롤 축입니다. 
		@default은 "Y" 입니다
	]]
	.CursorIndex number? -- [[
		첫 번째로 보여줄 요소의 인덱스입니다. 
		@default 1
	]]

	.ScrollBarVisible boolean? -- [[
		true 일 때만 커스텀 스크롤바를 렌더합니다. 
		@default true
	]].
	.ScrollBarThickness number? -- [[
		스크롤바 두께입니다. 
		@default 12
	]]
	.ScrollBarColor Color3? -- [[
		스크롤바 색상입니다.
	]]
	.ScrollDeltaScale number? -- [[
		마우스 휠 스크롤 민감도 스케일입니다. 
		@default 1
	]]

	.FadeDuration number? -- [[
		요소가 보여지거나 사라질 때의 애니메이션 시간(초)입니다. 
		@default 0.5
	]]
	
	.CullingFadeColor Color3? -- 컬링 중 사용할 페이드 색상입니다.
	.CullingFadeTransparency number? -- 컬링 페이드 기본 투명도입니다.

	.Elements { ElementEntry } -- 렌더링할 요소 정의 목록입니다. 각 항목은 Gui 객체를 생성하는 함수이거나 Gui 객체 자체입니다. Order 기반 정렬 시엔 {Key, Order, Element} 형태를 사용합니다.

	.OnCursorChange ((number) -> ())? -- 커서 인덱스(리스트의 첫 번째 가시 요소)가 바뀔 때 호출됩니다.

	.SortOrder "Name" | "Order" | "Index"? -- [[
		요소 정렬 기준입니다
		@default "Index"
	]]
	
	.ReversesAlignment boolean? -- true 일 경우 정렬 방향과 스크롤 방향을 반대로 적용합니다.
]=]
export type CullingListFrameProps = {
	ScrollingEnabled: boolean?,
	ScrollingDirection: "X" | "Y"?,
	CursorIndex: number?,

	ScrollBarVisible: boolean?,
	ScrollBarThickness: number?,
	ScrollBarColor: Color3?,
	ScrollDeltaScale: number?,

	FadeDuration: number?,

	CullingFadeColor: Color3?,
	CullingFadeTransparency: number?,
	Elements: { ElementEntry },

	OnCursorChange: ((delta: number) -> ())?,

	SortOrder: "Name" | "Order" | "Index"?,
	ReversesAlignment: boolean?,
} & Frame.FrameProps

local OWNED_KEY_SET = Props.keySet({
	"ScrollingEnabled",
	"ScrollingDirection",
	"CursorIndex",
	"ScrollBarVisible",
	"ScrollBarThickness",
	"ScrollBarColor",
	"ScrollDeltaScale",
	"FadeDuration",
	"CullingFadeColor",
	"CullingFadeTransparency",
	"Elements",
	"OnCursorChange",
	"SortOrder",
	"ReversesAlignment",
	"ref",
})

type PropElementInfo = any
type IndexChangeInfo = any

local PADDING = 1
local MAX_RENDER_AHEAD = 50

local scrollBarSmoothers = {} :: { [any]: (dt: number) -> () }
local scrollBarSmootherConn: RBXScriptConnection?

local function updateScrollBarSmootherConnection()
	if scrollBarSmootherConn and next(scrollBarSmoothers) == nil then
		scrollBarSmootherConn:Disconnect()
		scrollBarSmootherConn = nil
	end
end

local function addScrollBarSmoother(token: any, callback: (dt: number) -> ())
	scrollBarSmoothers[token] = callback

	if scrollBarSmootherConn == nil then
		scrollBarSmootherConn = RunService.RenderStepped:Connect(function(dt)
			for _, smoother in scrollBarSmoothers do
				smoother(dt)
			end

			updateScrollBarSmootherConnection()
		end)
	end
end

local function getVector2Axis(value: Vector2, axis: "X" | "Y"): number
	if axis == "Y" then
		return value.Y
	end

	return value.X
end

local function removeScrollBarSmoother(token: any)
	scrollBarSmoothers[token] = nil
	updateScrollBarSmootherConnection()
end

local function createState<T>(initialValue: T)
	return signal(initialValue)
end

local function resolveSignalValue<T>(
	customValue: T | (() -> T) | nil,
	defaultAccessor: () -> T
): () -> T
	if customValue ~= nil then
		return function()
			return read(customValue)
		end
	end

	return defaultAccessor
end

local function getElementKey(element: any, fallbackKey: any)
	if element == nil then
		return fallbackKey
	end

	local entry = if type(element) == "table" then element :: any else nil

	if entry ~= nil then
		local entryAny = entry :: any
		if entry.Key ~= nil then
			return read(entry.Key)
		end

		if entryAny.Element ~= nil and type(entryAny.Element) == "table" then
			local nested = entryAny.Element :: any
			if nested.props and nested.props.key ~= nil then
				return read(nested.props.key)
			end

			if nested.key ~= nil then
				return read(nested.key)
			end
		end
	end

	return fallbackKey
end

local function getCompareElementInfo(sortOrder: string)
	if sortOrder == "Order" then
		return function(a: any, b: any)
			return (a.Order or math.huge) < (b.Order or math.huge)
		end
	elseif sortOrder == "Index" then
		return function(a: any, b: any)
			return (a.Index or 0) < (b.Index or 0)
		end
	elseif sortOrder == "Name" then
		return function(a: any, b: any)
			return tostring(a.Key) < tostring(b.Key)
		end
	end

	return function()
		return false
	end
end

local function resolveElementFactory(element: ElementLike): ElementFactory
	if type(element) == "function" then
		return element :: ElementFactory
	end

	return function()
		return element :: GuiObject
	end
end

local function CullingListFrame(
	props: CullingListFrameProps,
	forwardedRef: ((ScrollingFrame?) -> ())?
)
	local localProps, restProps = Props.splitProps(props :: any, OWNED_KEY_SET)
	local frameProps = Props.composeProps({}, restProps :: any, props :: any)

	local propChildren: { any } = {}
	for key, child in frameProps do
		if type(key) == "number" then
			propChildren[#propChildren + 1] = child
			frameProps[key] = nil
		end
	end

	local userRef = localProps.ref
	frameProps.Class = frameProps.Class or "ScrollingFrame"
	frameProps.CanvasSize = UDim2.fromOffset(0, 0)
	frameProps.ScrollBarThickness = 0
	frameProps.ScrollingEnabled = false

	local getFrameRef, setFrameRef = createState(nil :: ScrollingFrame?)
	frameProps.ref = function(instance: ScrollingFrame?)
		setFrameRef(instance)

		if typeof(userRef) == "function" then
			(userRef :: any)(instance)
		end

		if typeof(forwardedRef) == "function" then
			forwardedRef(instance)
		end
	end

	local function getScrollingDirection(): "X" | "Y"
		local direction = read(localProps.ScrollingDirection)
		if direction == "X" or direction == "Y" then
			return direction
		end
		return "Y"
	end

	local function getReversesAlignment(): boolean
		return (read(localProps.ReversesAlignment) :: boolean?) or false
	end

	local function getScrollingEnabled()
		if localProps.ScrollingEnabled == nil then
			return true
		end

		return read(localProps.ScrollingEnabled)
	end

	local function getScrollDeltaScale()
		return (read(localProps.ScrollDeltaScale) :: number?) or 1
	end

	local function getScrollBarThickness()
		return (read(localProps.ScrollBarThickness) :: number?) or 12
	end

	local function getScrollBarVisible()
		if localProps.ScrollBarVisible == nil then
			return true
		end

		return read(localProps.ScrollBarVisible)
	end

	local function getFadeDuration()
		return (read(localProps.FadeDuration) :: number?) or 0.5
	end

	local getScrollBarColor = resolveSignalValue(localProps.ScrollBarColor, function()
		return theme().ScrollBar
	end)
	local getCullingFadeColor = resolveSignalValue(localProps.CullingFadeColor, function()
		return theme().CullingFade
	end)
	local getCullingFadeTransparency = resolveSignalValue(
		localProps.CullingFadeTransparency,
		function()
			return theme().CullingFadeTransparency
		end
	)

	local userInputManager = area().UserInputManager

	local getPropElementInfosByIndex, setPropElementInfosByIndex =
		createState({} :: { PropElementInfo })
	local getElementKeysByIndex, setElementKeysByIndex = createState({} :: { [number]: any })
	local getElementCount, setElementCount = createState(0)

	local getCursorIndex, setCursorIndex =
		createState(math.max((read(localProps.CursorIndex) :: number?) or 1, 1))
	local getRenderMaxIndex, setRenderMaxIndex = createState(getCursorIndex())

	local getProgressesByIndex, setProgressesByIndex = createState({} :: { [number]: number })
	local getUpProgressesByIndex, setUpProgressesByIndex = createState({} :: { [number]: number })
	local getDownProgressesByIndex, setDownProgressesByIndex =
		createState({} :: { [number]: number })

	local getElementCanvasGroupSizesByKey, setElementCanvasGroupSizesByKey =
		createState({} :: { [any]: number })
	local getIndexChangeInfosByKey, setIndexChangeInfosByKey =
		createState({} :: { [any]: IndexChangeInfo })

	local getCursorProgress, setCursorProgress = createState(0)
	local getScrollBarPosition, setScrollBarPosition = createState(0)

	local getScrollBarContainer, setScrollBarContainer = createState(nil :: Frame?)
	local getIsClickingScrollBar, setIsClickingScrollBar = createState(false)

	local getFrameSize, setFrameSize = createState(0)
	local getVisibleCanvasGroups, setVisibleCanvasGroups = createState({} :: { GuiObject })

	local canvasGroupsByKey = {} :: { [any]: GuiObject? }
	local elementInstancesByKey = {} :: { [any]: GuiObject? }
	local sizeConnectionsByKey = {} :: { [any]: RBXScriptConnection? }
	local progressTweensByIndexRef = {
		current = {} :: { [number]: DynamicTimer.DynamicTween },
	}

	local lastIndexesByKeyRef = {
		current = {} :: { [any]: number },
	}
	local isInitializedRef = {
		current = false,
	}

	local lastCursorIndexRef = {
		current = getCursorIndex(),
	}
	local lastRenderMaxIndexRef = {
		current = getCursorIndex() - 1,
	}
	local scrollBarDragToken = {}
	local scrollBarSmootherToken = {}

	local function ensureElementInstance(key: any, elementInfo: PropElementInfo): GuiObject
		local instance = elementInstancesByKey[key] :: GuiObject?
		if instance then
			return instance
		end

		instance = (elementInfo.ElementFactory :: any)() :: GuiObject
		elementInstancesByKey[key] = instance
		return instance
	end

	effect(function()
		setCursorIndex(math.max((read(localProps.CursorIndex) :: number?) or 1, 1))
	end)

	effect(function()
		local elements = (read(localProps.Elements) :: { [any]: any }?)
			or error("Missing props.Elements")
		local sortOrder = (read(localProps.SortOrder) :: string?) or "Index"
		local compareElementInfo = getCompareElementInfo(sortOrder)

		local newPropElementInfosByIndex: { any } = {}
		local newElementKeysByIndex: { [number]: any } = {}
		local newElementCount = 0

		if sortOrder == "Index" then
			for index, element in elements do
				newElementCount += 1

				local info: { [any]: any } = {}
				info.Key = getElementKey(element, index)
				info.ElementFactory = resolveElementFactory(
					(
							if type(element) == "table" and element.Element ~= nil
								then element.Element
								else element
						) :: ElementLike
				)
				info.Index = index

				newPropElementInfosByIndex[#newPropElementInfosByIndex + 1] = info
			end
		else
			for name, element in elements do
				newElementCount += 1

				local info: { [any]: any } = {}

				if sortOrder == "Order" then
					local elementEntry = element :: any
					local child = elementEntry.Element or element

					info.Key = getElementKey(elementEntry, name)
					info.ElementFactory = resolveElementFactory(child)
					info.Order = read(elementEntry.Order) or math.huge
				else
					info.Key = getElementKey(element, name)
					info.ElementFactory = resolveElementFactory(
						(
								if type(element) == "table" and element.Element ~= nil
									then element.Element
									else element
							) :: ElementLike
					)
				end
				newPropElementInfosByIndex[#newPropElementInfosByIndex + 1] = info
			end
		end

		table.sort(newPropElementInfosByIndex, compareElementInfo)

		for index, elementInfo in newPropElementInfosByIndex do
			newElementKeysByIndex[index] = elementInfo.Key
		end

		setPropElementInfosByIndex(newPropElementInfosByIndex)
		setElementCount(newElementCount)
		setElementKeysByIndex(newElementKeysByIndex)
	end)

	effect(function()
		local elementCount = getElementCount()
		local clampedCursorIndex = math.clamp(getCursorIndex(), 1, math.max(elementCount, 1))
		if clampedCursorIndex ~= getCursorIndex() then
			setCursorIndex(clampedCursorIndex)
		end

		local function resizeTable(prev: { [number]: number }, defaultValue: number)
			local newTable = table.create(math.max(elementCount, 1), defaultValue)
			for index = 1, math.min(#prev, elementCount) do
				newTable[index] = prev[index] or defaultValue
			end

			return newTable
		end

		setProgressesByIndex(function(prev)
			local resized = resizeTable(prev, 0)
			if resized[clampedCursorIndex] == nil or resized[clampedCursorIndex] == 0 then
				resized[clampedCursorIndex] = 1
			end

			return resized
		end)
		setUpProgressesByIndex(function(prev)
			return resizeTable(prev, 0)
		end)
		setDownProgressesByIndex(function(prev)
			return resizeTable(prev, 0)
		end)

		setRenderMaxIndex(function(old)
			return math.clamp(old, clampedCursorIndex, math.max(elementCount, clampedCursorIndex))
		end)
	end)

	effect(function()
		if not getScrollingEnabled() then
			return
		end

		local scrollingFrame = getFrameRef()
		if scrollingFrame == nil then
			return
		end

		local scrollConn = scrollingFrame.InputChanged:Connect(function(inputObject: InputObject)
			if inputObject.UserInputType ~= Enum.UserInputType.MouseWheel then
				return
			end

			local scrollDelta = inputObject.Position.Z * getScrollDeltaScale()
			if math.abs(scrollDelta) < 1 then
				if math.sign(scrollDelta) == 1 then
					scrollDelta = 1
				elseif math.sign(scrollDelta) == -1 then
					scrollDelta = -1
				end
			end

			if getReversesAlignment() then
				scrollDelta = -scrollDelta
			end

			local newCursorIndex = getCursorIndex() - scrollDelta
			local totalCount = math.max(getElementCount(), 1)
			newCursorIndex = math.clamp(newCursorIndex, 1, totalCount)

			setCursorIndex(newCursorIndex)

			local onCursorChange = localProps.OnCursorChange :: ((number) -> ())?
			if onCursorChange then
				onCursorChange(newCursorIndex)
			end
		end)

		onCleanup(function()
			scrollConn:Disconnect()
		end)
	end)

	effect(function()
		local scrollingFrame = getFrameRef()
		if scrollingFrame == nil then
			return
		end

		setFrameSize(getVector2Axis(scrollingFrame.AbsoluteSize, getScrollingDirection()))

		local conn = scrollingFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			setFrameSize(getVector2Axis(scrollingFrame.AbsoluteSize, getScrollingDirection()))
		end)

		onCleanup(function()
			conn:Disconnect()
		end)
	end)

	local function updateCursorFromScrollBarInput()
		local container = getScrollBarContainer()
		if container == nil then
			return false
		end

		local uiPosition = container.AbsolutePosition
		local uiSize = container.AbsoluteSize
		local axisSize = if getScrollingDirection() == "Y" then uiSize.Y else uiSize.X
		if axisSize <= 0 then
			return false
		end

		local mousePosition = userInputManager:GetMousePosition()
		local progress = if getScrollingDirection() == "Y"
			then (mousePosition.Y - uiPosition.Y) / axisSize
			else (mousePosition.X - uiPosition.X) / axisSize
		if getReversesAlignment() then
			progress = 1 - progress
		end

		local newCursorIndex = math.clamp(
			math.ceil(progress * math.max(getElementCount(), 1)),
			1,
			math.max(getElementCount(), 1)
		)
		setCursorIndex(newCursorIndex)

		local onCursorChange = localProps.OnCursorChange :: ((number) -> ())?
		if onCursorChange then
			onCursorChange(newCursorIndex)
		end

		return true
	end

	local function stopScrollBarDrag()
		setIsClickingScrollBar(false)
		removeScrollBarSmoother(scrollBarDragToken)
	end

	local function onScrollBarClick()
		if getIsClickingScrollBar() then
			return
		end
		setIsClickingScrollBar(true)

		updateCursorFromScrollBarInput()
		removeScrollBarSmoother(scrollBarDragToken)
		addScrollBarSmoother(scrollBarDragToken, function()
			if not getScrollBarContainer() then
				stopScrollBarDrag()
				return
			end

			if
				not userInputManager:IsInputKeyPressed(
					Enum.UserInputType.MouseButton1,
					Enum.UserInputType.MouseButton3,
					Enum.UserInputType.Touch
				)
			then
				stopScrollBarDrag()
				return
			end

			updateCursorFromScrollBarInput()
		end)
	end

	effect(function()
		setCursorProgress((getCursorIndex() - 1) / math.max(getElementCount(), 1))
	end)

	effect(function()
		setScrollBarPosition(getCursorProgress())
		addScrollBarSmoother(scrollBarSmootherToken, function(dt)
			setScrollBarPosition(function(old: number)
				return LinearInterpolation.number(
						old,
						getCursorProgress(),
						1 - 0.005 ^ dt
					) :: number
			end)
		end)

		onCleanup(function()
			removeScrollBarSmoother(scrollBarSmootherToken)
		end)
	end)

	local function tweenChangeIndexProgressOnIndexChanged(
		key: any,
		lastIndex: number,
		index: number
	)
		local indexChangeProgressTween: DynamicTimer.DynamicTween
		indexChangeProgressTween = DynamicTimer:CreateTween({
			Duration = 0.3,
			EasingStyle = "Cubic",
			EasingDirection = "InOut",
			Callback = function(p: number)
				local indexChangeInfosByKey = getIndexChangeInfosByKey() :: any
				indexChangeInfosByKey[key] = {
					LastIndex = lastIndex,
					Tween = indexChangeProgressTween,
					Progress = p,
				}
				setIndexChangeInfosByKey(indexChangeInfosByKey)
			end,
		}) :: DynamicTimer.DynamicTween
		indexChangeProgressTween:Play()
		indexChangeProgressTween.Completed:Once(function()
			if indexChangeProgressTween.IsDestroyed then
				return
			end

			indexChangeProgressTween:Destroy()
			local indexChangeInfosByKey = getIndexChangeInfosByKey() :: any
			indexChangeInfosByKey[key] = nil
			setIndexChangeInfosByKey(indexChangeInfosByKey)
		end)
	end

	local function getElementSizeForRenderByIndex(
		isIndexChanged: boolean,
		indexChangeInfo: IndexChangeInfo,
		key: any,
		lastIndex: number,
		index: number,
		elementKeysByIndex: { [number]: any },
		elementCanvasGroupSizesByKey: { [any]: number }
	)
		if isIndexChanged then
			if indexChangeInfo then
				indexChangeInfo.Tween:Destroy()
			end
			tweenChangeIndexProgressOnIndexChanged(key, lastIndex, index)

			local lastKey = elementKeysByIndex[lastIndex]
			return elementCanvasGroupSizesByKey[lastKey] or 0
		elseif indexChangeInfo then
			local lastElementIndex = indexChangeInfo.LastIndex
			local lastKey = elementKeysByIndex[lastElementIndex]
			if not lastKey then
				return elementCanvasGroupSizesByKey[key] or 0
			end

			local changeProgress = indexChangeInfo.Progress
			local lastIndexSize = elementCanvasGroupSizesByKey[lastKey] or 0
			local currentIndexSize = elementCanvasGroupSizesByKey[key] or 0

			return LinearInterpolation.number(lastIndexSize, currentIndexSize, changeProgress)
		end

		return elementCanvasGroupSizesByKey[key] or 0
	end

	local function detectAndUpdateElementSize(canvasGroup: GuiObject, key: any)
		local size = getVector2Axis(canvasGroup.AbsoluteSize, getScrollingDirection()) + PADDING
		local function updateElementCanvasGroupSizesByKey(
			elementCanvasGroupSizesByKey: { [any]: number }
		)
			local lastSize = elementCanvasGroupSizesByKey[key]
			if lastSize == size then
				return elementCanvasGroupSizesByKey
			end

			elementCanvasGroupSizesByKey[key] = size
			return elementCanvasGroupSizesByKey
		end

		setElementCanvasGroupSizesByKey(updateElementCanvasGroupSizesByKey)

		local conn = canvasGroup:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			size = getVector2Axis(canvasGroup.AbsoluteSize, getScrollingDirection()) + PADDING
			setElementCanvasGroupSizesByKey(updateElementCanvasGroupSizesByKey)
		end)

		return conn
	end

	effect(function()
		if not isInitializedRef.current then
			RunService.RenderStepped:Once(function()
				isInitializedRef.current = true
			end)
		end

		local propElementInfosByIndex = getPropElementInfosByIndex()
		local elementCount = getElementCount()
		local elementKeysByIndex = getElementKeysByIndex()
		local renderMaxIndex = getRenderMaxIndex()
		local progressesByIndex = getProgressesByIndex()
		local elementCanvasGroupSizesByKey = getElementCanvasGroupSizesByKey()
		local indexChangeInfosByKey = getIndexChangeInfosByKey()
		local downProgressesByIndex = getDownProgressesByIndex()
		local upProgressesByIndex = getUpProgressesByIndex()
		local frameSize = getFrameSize()

		local elementCanvasGroups: { GuiObject } = {}
		local elementIndexesByKey = {}
		local forIterationCount = math.min(renderMaxIndex + MAX_RENDER_AHEAD, elementCount)
		local goalPositionsByIndex = table.create(forIterationCount + 1, 0)
		local renderableElementInfosByIndex = {}
		local padding = 0

		for index = 1, forIterationCount do
			local elementInfo = propElementInfosByIndex[index]
			if elementInfo == nil then
				continue
			end

			local key = elementInfo.Key
			elementIndexesByKey[key] = index

			local progress = (progressesByIndex[index] :: number?) or 0
			local shouldCull = progress <= 0
			if shouldCull then
				continue
			end

			local indexChangeInfo = indexChangeInfosByKey[key]
			local goalPosition = goalPositionsByIndex[index]
			local lastIndex = lastIndexesByKeyRef.current[key]
			local isIndexChanged = lastIndex ~= nil and lastIndex ~= index

			local currentCanvasSize = getElementSizeForRenderByIndex(
				isIndexChanged,
				indexChangeInfo,
				key,
				lastIndex,
				index,
				elementKeysByIndex,
				elementCanvasGroupSizesByKey
			)

			goalPositionsByIndex[index + 1] = goalPosition + currentCanvasSize
			renderableElementInfosByIndex[index] = elementInfo

			local downProgress = (downProgressesByIndex[index] :: number?) or 0
			local upProgress = (upProgressesByIndex[index] :: number?) or 0
			padding -= currentCanvasSize * downProgress
			padding -= currentCanvasSize * upProgress
		end

		for index, elementInfo in renderableElementInfosByIndex do
			local key = elementInfo.Key
			local progress = (progressesByIndex[index] :: number?) or 0

			local indexChangeInfo = indexChangeInfosByKey[key]
			local position = goalPositionsByIndex[index]
			if indexChangeInfo then
				local lastIndex = indexChangeInfo.LastIndex
				local lastIndexPosition = goalPositionsByIndex[lastIndex] or frameSize
				position = LinearInterpolation.number(
					lastIndexPosition,
					position,
					indexChangeInfo.Progress
				)
			end

			position += padding
			local anchorPoint = Vector2.zero
			if getReversesAlignment() then
				position = frameSize - position
				anchorPoint = if getScrollingDirection() == "Y"
					then Vector2.new(0, 1)
					else Vector2.new(1, 0)
			end

			local canvasGroup = canvasGroupsByKey[key]
			local elementInstance = ensureElementInstance(key, elementInfo)

			if canvasGroup == nil then
				canvasGroup = create "Frame" {
					AutomaticSize = if getScrollingDirection() == "Y"
						then Enum.AutomaticSize.Y
						else Enum.AutomaticSize.X,
					AnchorPoint = anchorPoint,
					BackgroundTransparency = 1,
					BackgroundColor3 = getCullingFadeColor,
					BorderSizePixel = 0,
				}
				canvasGroupsByKey[key] = canvasGroup

				local sizeConn = detectAndUpdateElementSize(canvasGroup, key)
				sizeConnectionsByKey[key] = sizeConn
			else
				canvasGroup.AutomaticSize = if getScrollingDirection() == "Y"
					then Enum.AutomaticSize.Y
					else Enum.AutomaticSize.X
				canvasGroup.AnchorPoint = anchorPoint
				canvasGroup.BackgroundColor3 = getCullingFadeColor()
			end

			if (elementInstance :: any).Parent ~= canvasGroup then
				(elementInstance :: any).Parent = canvasGroup
			end

			if getScrollingDirection() == "Y" then
				canvasGroup.Position = UDim2.new(progress - 1, 0, 0, position)
				canvasGroup.Size = UDim2.fromScale(1, 0)
			else
				canvasGroup.Position = UDim2.new(0, position, progress - 1, 0)
				canvasGroup.Size = UDim2.fromScale(0, 1)
			end

			canvasGroup.ZIndex = index
			canvasGroup.BackgroundTransparency =
				LinearInterpolation.number(getCullingFadeTransparency(), 1, progress)

			elementCanvasGroups[#elementCanvasGroups + 1] = canvasGroup
		end

		for key, conn in sizeConnectionsByKey do
			if elementIndexesByKey[key] ~= nil then
				continue
			end

			(conn :: RBXScriptConnection):Disconnect()
			sizeConnectionsByKey[key] = nil
		end

		for key, canvasGroup in canvasGroupsByKey do
			if elementIndexesByKey[key] ~= nil then
				continue
			end

			if canvasGroup then
				canvasGroup:Destroy()
			end
			canvasGroupsByKey[key] = nil

			local elementInstance = elementInstancesByKey[key] :: GuiObject?
			if elementInstance then
				(elementInstance :: any).Parent = nil
				elementInstance:Destroy()
			end
			elementInstancesByKey[key] = nil
		end

		setVisibleCanvasGroups(elementCanvasGroups)
		lastIndexesByKeyRef.current = elementIndexesByKey
	end)

	onCleanup(function()
		removeScrollBarSmoother(scrollBarDragToken)
		removeScrollBarSmoother(scrollBarSmootherToken)

		for key, conn in sizeConnectionsByKey do
			(conn :: RBXScriptConnection):Disconnect()
			sizeConnectionsByKey[key] = nil
		end

		for _, canvasGroup in canvasGroupsByKey do
			if canvasGroup then
				canvasGroup:Destroy()
			end
		end

		for key, elementInstance in elementInstancesByKey do
			if elementInstance then
				(elementInstance :: any).Parent = nil
				elementInstance:Destroy()
			end
			elementInstancesByKey[key] = nil
		end

		for index, progressTween in progressTweensByIndexRef.current do
			progressTween:Destroy()
			progressTweensByIndexRef.current[index] = nil
		end

		local indexChangeInfosByKey = getIndexChangeInfosByKey()
		for key, indexChangeInfo in indexChangeInfosByKey do
			indexChangeInfo.Tween:Destroy()
			indexChangeInfosByKey[key] = nil
		end
	end)

	local function tweenElementProgressFromIndex(
		index: number,
		startProgress: number,
		goalProgress: number,
		callback: (number) -> (),
		onEnd: (() -> ())?
	)
		if progressTweensByIndexRef.current[index] then
			progressTweensByIndexRef.current[index]:Destroy()
		end

		local progressTween = DynamicTimer:CreateTween({
			Start = startProgress,
			Goal = goalProgress,
			Duration = getFadeDuration(),
			Callback = callback,
		}) :: DynamicTimer.DynamicTween
		progressTween:Play()
		progressTweensByIndexRef.current[index] = progressTween
		progressTween.Completed:Once(function()
			if onEnd then
				onEnd()
			end
			if progressTween.IsDestroyed then
				return
			end
			progressTweensByIndexRef.current[index] = nil
		end)
	end

	effect(function()
		local progressesByIndex = getProgressesByIndex()
		local cursorIndex = getCursorIndex()

		for index = cursorIndex, lastCursorIndexRef.current do
			local startProgress = progressesByIndex[index] or 0
			if startProgress == 1 then
				continue
			end
			tweenElementProgressFromIndex(index, startProgress, 1, function(p)
				setProgressesByIndex(function(progressesByIndex)
					progressesByIndex[index] = p
					return progressesByIndex
				end)
				setUpProgressesByIndex(function(progressesByIndex)
					progressesByIndex[index] = 1 - (p :: number)
					return progressesByIndex
				end)
			end, function()
				setUpProgressesByIndex(function(progressesByIndex)
					progressesByIndex[index] = 0
					return progressesByIndex
				end)
			end)
		end

		for index = lastCursorIndexRef.current, cursorIndex - 1 do
			local startProgress = progressesByIndex[index] or 0
			if startProgress == 0 then
				continue
			end
			tweenElementProgressFromIndex(index, startProgress, 0, function(p)
				setProgressesByIndex(function(progressesByIndex)
					progressesByIndex[index] = p
					return progressesByIndex
				end)
				setDownProgressesByIndex(function(progressesByIndex)
					progressesByIndex[index] = 1 - (p :: number)
					return progressesByIndex
				end)
			end, function()
				setDownProgressesByIndex(function(progressesByIndex)
					progressesByIndex[index] = 0
					return progressesByIndex
				end)
			end)
		end

		lastCursorIndexRef.current = cursorIndex
	end)

	effect(function()
		local renderMaxIndex = getRenderMaxIndex()
		local progressesByIndex = getProgressesByIndex()
		local cursorIndex = getCursorIndex()

		for index = math.max(lastRenderMaxIndexRef.current + 1, cursorIndex), renderMaxIndex do
			local startProgress = progressesByIndex[index] or 0
			if startProgress == 1 then
				continue
			end

			tweenElementProgressFromIndex(index, startProgress, 1, function(p)
				setProgressesByIndex(function(progressesByIndex)
					progressesByIndex[index] = p
					return progressesByIndex
				end)
			end)
		end

		for index = renderMaxIndex + 1, lastRenderMaxIndexRef.current do
			local startProgress = progressesByIndex[index] or 0

			if index < cursorIndex then
				setProgressesByIndex(function(progressesByIndex)
					progressesByIndex[index] = 0
					return progressesByIndex
				end)
			else
				tweenElementProgressFromIndex(index, startProgress, 0, function(p)
					setProgressesByIndex(function(progressesByIndex)
						progressesByIndex[index] = p
						return progressesByIndex
					end)
				end)
			end
		end

		lastRenderMaxIndexRef.current = renderMaxIndex
	end)

	effect(function()
		local elementCanvasGroupSizesByKey = getElementCanvasGroupSizesByKey()
		local frameSize = getFrameSize()
		local renderMaxIndex = getRenderMaxIndex()
		local elementKeysByIndex = getElementKeysByIndex()
		local elementCount = getElementCount()
		local cursorIndex = getCursorIndex()

		local totalSize = 0
		local newRenderMaxIndex = cursorIndex

		for index = cursorIndex, elementCount do
			local key = elementKeysByIndex[index]
			local size = if key ~= nil then elementCanvasGroupSizesByKey[key] else nil

			if size == nil then
				if index <= renderMaxIndex + MAX_RENDER_AHEAD then
					newRenderMaxIndex = index
					continue
				else
					break
				end
			end

			newRenderMaxIndex = index
			totalSize += size :: number
			if frameSize <= totalSize then
				break
			end
		end

		if not isInitializedRef.current then
			setProgressesByIndex(function(progressesByIndex)
				for i = cursorIndex, newRenderMaxIndex do
					progressesByIndex[i] = 1
				end
				return progressesByIndex
			end)
		end

		setRenderMaxIndex(newRenderMaxIndex)
	end)

	local children: { any } = {}

	local scrollBar = vide.show(getScrollBarVisible, function()
		local function getScrollBarPositionUDim2()
			local scrollBarPosition = getScrollBarPosition()
			if not getReversesAlignment() then
				return if getScrollingDirection() == "Y"
					then UDim2.new(0, 0, scrollBarPosition, -2)
					else UDim2.new(scrollBarPosition, -2, 0, 0)
			end

			return if getScrollingDirection() == "Y"
				then UDim2.new(0, 0, 1 - scrollBarPosition, 2)
				else UDim2.new(1 - scrollBarPosition, 2, 0, 0)
		end

		local scrollBarProps: { [any]: any } = {
			Class = "Frame",
			ref = function(instance)
				setScrollBarContainer(instance :: Frame?)
			end,

			Size = function()
				local thickness = getScrollBarThickness()
				if getScrollingDirection() == "Y" then
					return UDim2.new(0, thickness, 1, 0)
				end

				return UDim2.new(1, 0, 0, thickness)
			end,
			Position = function()
				if getScrollingDirection() == "Y" then
					return UDim2.fromScale(1, 0)
				end

				return UDim2.fromScale(0, 1)
			end,
			AnchorPoint = function()
				if getScrollingDirection() == "Y" then
					return Vector2.new(1, 0)
				end

				return Vector2.new(0, 1)
			end,

			OnClick = onScrollBarClick,
		}

		local scrollBarChildProps: { [any]: any } = {
			BackgroundColor3 = getScrollBarColor,
			Size = function()
				local scrollBarScale = 1 / math.max(getElementCount(), 1)
				if getScrollingDirection() == "Y" then
					return UDim2.new(1, 0, scrollBarScale, 4)
				end

				return UDim2.new(scrollBarScale, 4, 1, 0)
			end,
			AnchorPoint = function()
				if not getReversesAlignment() then
					return Vector2.zero
				end

				if getScrollingDirection() == "Y" then
					return Vector2.new(0, 1)
				end

				return Vector2.new(1, 0)
			end,
			Position = getScrollBarPositionUDim2,
		}

		scrollBarProps[#scrollBarProps + 1] = Frame(scrollBarChildProps :: any)
		return Button(scrollBarProps :: any)
	end)

	children[#children + 1] = scrollBar

	local listProps: { [any]: any } = {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = function()
			local scrollBarOffset = if getScrollBarVisible() then getScrollBarThickness() else 0
			if getScrollingDirection() == "Y" then
				return UDim2.new(1, if getScrollBarVisible() then -scrollBarOffset else 0, 1, 0)
			end

			return UDim2.new(1, 0, 1, if getScrollBarVisible() then -scrollBarOffset else 0)
		end,
	}

	listProps[#listProps + 1] = function()
		return getVisibleCanvasGroups()
	end

	children[#children + 1] = create("Frame")(listProps :: any)

	for _, child in propChildren do
		children[#children + 1] = child
	end

	for _, child in children do
		frameProps[#frameProps + 1] = child
	end

	return Frame(frameProps :: any)
end

return CullingListFrame
