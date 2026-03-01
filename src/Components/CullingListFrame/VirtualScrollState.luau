--[=[
	@class VirtualScrollState

	가상 스크롤의 커서/인덱스/스크롤 상태를 관리하는 모듈입니다.
	CullingListFrame 에서 추출한 상태 관리 유틸리티입니다.
]=]

local vide = require("../../vide")

local source = vide.source
local read = vide.read

local function createState<T>(initialValue: T)
	local state = source(initialValue)

	local function setValue(nextValue: T | ((T) -> T))
		if type(nextValue) == "function" then
			local updater = (nextValue :: any) :: (T) -> T
			state(updater(state()))
		else
			state(nextValue)
		end
	end

	local function getValue(): T
		return state()
	end

	return getValue, setValue
end

local function resolveValueSource<T>(customValue: T | (() -> T) | nil, defaultGetter: () -> T): () -> T
	if customValue ~= nil then
		return function()
			return read(customValue)
		end
	end

	return defaultGetter
end

local function getVector2Axis(value: Vector2, axis: "X" | "Y"): number
	if axis == "Y" then
		return value.Y
	end

	return value.X
end

export type VirtualScrollStateConfig = {
	CursorIndex: number?,
	ScrollingDirection: ("X" | "Y")?,
	ReversesAlignment: boolean?,
	ScrollingEnabled: boolean?,
	ScrollDeltaScale: number?,
	OnCursorChange: ((number) -> ())?,
}

export type VirtualScrollState = {
	getCursorIndex: () -> number,
	setCursorIndex: (number | ((number) -> number)) -> (),
	getElementCount: () -> number,
	setElementCount: (number | ((number) -> number)) -> (),
	getRenderMaxIndex: () -> number,
	setRenderMaxIndex: (number | ((number) -> number)) -> (),
	getFrameSize: () -> number,
	setFrameSize: (number | ((number) -> number)) -> (),
	getScrollBarPosition: () -> number,
	setScrollBarPosition: (number | ((number) -> number)) -> (),
	getCursorProgress: () -> number,
	setCursorProgress: (number | ((number) -> number)) -> (),
	getScrollingDirection: () -> "X" | "Y",
	getReversesAlignment: () -> boolean,
	getScrollingEnabled: () -> boolean,
	getScrollDeltaScale: () -> number,
	getVector2Axis: (Vector2, "X" | "Y") -> number,
	createState: typeof(createState),
	resolveValueSource: typeof(resolveValueSource),
}

local function createVirtualScrollState(config: VirtualScrollStateConfig): VirtualScrollState
	local getCursorIndex, setCursorIndex =
		createState(math.max((config.CursorIndex :: number?) or 1, 1))
	local getElementCount, setElementCount = createState(0)
	local getRenderMaxIndex, setRenderMaxIndex = createState(getCursorIndex())
	local getFrameSize, setFrameSize = createState(0)
	local getScrollBarPosition, setScrollBarPosition = createState(0)
	local getCursorProgress, setCursorProgress = createState(0)

	local function getScrollingDirection(): "X" | "Y"
		local direction = read(config.ScrollingDirection)
		if direction == "X" or direction == "Y" then
			return direction
		end
		return "Y"
	end

	local function getReversesAlignment(): boolean
		return (read(config.ReversesAlignment) :: boolean?) or false
	end

	local function getScrollingEnabled(): boolean
		if config.ScrollingEnabled == nil then
			return true
		end
		return read(config.ScrollingEnabled) :: boolean
	end

	local function getScrollDeltaScale(): number
		return (read(config.ScrollDeltaScale) :: number?) or 1
	end

	return {
		getCursorIndex = getCursorIndex,
		setCursorIndex = setCursorIndex,
		getElementCount = getElementCount,
		setElementCount = setElementCount,
		getRenderMaxIndex = getRenderMaxIndex,
		setRenderMaxIndex = setRenderMaxIndex,
		getFrameSize = getFrameSize,
		setFrameSize = setFrameSize,
		getScrollBarPosition = getScrollBarPosition,
		setScrollBarPosition = setScrollBarPosition,
		getCursorProgress = getCursorProgress,
		setCursorProgress = setCursorProgress,
		getScrollingDirection = getScrollingDirection,
		getReversesAlignment = getReversesAlignment,
		getScrollingEnabled = getScrollingEnabled,
		getScrollDeltaScale = getScrollDeltaScale,
		getVector2Axis = getVector2Axis,
		createState = createState,
		resolveValueSource = resolveValueSource,
	}
end

return createVirtualScrollState
