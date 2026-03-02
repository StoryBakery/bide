--[=[
	@class ScrollBarControl

	CullingListFrame의 스크롤바 UI 및 드래그/클릭 제어를 담당합니다.
]=]

local RunService = game:GetService("RunService")

local LinearInterpolation = require("../../../roblox_packages/LinearInterpolation") :: any
local vide = require("../../vide")

local Button = require("../Button")
local Frame = require("../Frame")
local theme = require("../../Contexts/Theme")

local effect = vide.effect
local signal = vide.signal
local onCleanup = vide.onCleanup

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

local function removeScrollBarSmoother(token: any)
	scrollBarSmoothers[token] = nil
	updateScrollBarSmootherConnection()
end

export type ScrollBarConfig = {
	GetScrollBarVisible: () -> boolean,
	GetScrollBarThickness: () -> number,
	GetScrollBarColor: () -> Color3,
	GetScrollingDirection: () -> "X" | "Y",
	GetReversesAlignment: () -> boolean,
	GetElementCount: () -> number,
	GetCursorIndex: () -> number,
	SetCursorIndex: (number | ((number) -> number)) -> (),
	GetCursorProgress: () -> number,
	GetScrollBarPosition: () -> number,
	SetScrollBarPosition: (number | ((number) -> number)) -> (),
	UserInputManager: any,
	OnCursorChange: ((number) -> ())?,
}

export type ScrollBarHandle = {
	ScrollBarElement: any,
	Destroy: () -> (),
}

local function createScrollBarControl(config: ScrollBarConfig): ScrollBarHandle
	local scrollBarDragToken = {}
	local scrollBarSmootherToken = {}
	local getScrollBarContainer, setScrollBarContainer = signal(nil :: Frame?)
	local getIsClickingScrollBar, setIsClickingScrollBar = signal(false)

	local function updateCursorFromScrollBarInput()
		local container = getScrollBarContainer()
		if container == nil then
			return false
		end

		local uiPosition = container.AbsolutePosition
		local uiSize = container.AbsoluteSize
		local axisSize = if config.GetScrollingDirection() == "Y" then uiSize.Y else uiSize.X
		if axisSize <= 0 then
			return false
		end

		local mousePosition = config.UserInputManager:GetMousePosition()
		local progress = if config.GetScrollingDirection() == "Y"
			then (mousePosition.Y - uiPosition.Y) / axisSize
			else (mousePosition.X - uiPosition.X) / axisSize
		if config.GetReversesAlignment() then
			progress = 1 - progress
		end

		local newCursorIndex = math.clamp(
			math.ceil(progress * math.max(config.GetElementCount(), 1)),
			1,
			math.max(config.GetElementCount(), 1)
		)
		config.SetCursorIndex(newCursorIndex)

		if config.OnCursorChange then
			config.OnCursorChange(newCursorIndex)
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
				not config.UserInputManager:IsInputKeyPressed(
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

	-- 스크롤바 위치 스무딩
	effect(function()
		config.SetScrollBarPosition(config.GetCursorProgress())
		addScrollBarSmoother(scrollBarSmootherToken, function(dt)
			config.SetScrollBarPosition(function(old: number)
				return LinearInterpolation.number(
						old,
						config.GetCursorProgress(),
						1 - 0.005 ^ dt
					) :: number
			end)
		end)

		onCleanup(function()
			removeScrollBarSmoother(scrollBarSmootherToken)
		end)
	end)

	local scrollBarElement = vide.show(config.GetScrollBarVisible, function()
		local function getScrollBarPositionUDim2()
			local scrollBarPosition = config.GetScrollBarPosition()
			if not config.GetReversesAlignment() then
				return if config.GetScrollingDirection() == "Y"
					then UDim2.new(0, 0, scrollBarPosition, -2)
					else UDim2.new(scrollBarPosition, -2, 0, 0)
			end

			return if config.GetScrollingDirection() == "Y"
				then UDim2.new(0, 0, 1 - scrollBarPosition, 2)
				else UDim2.new(1 - scrollBarPosition, 2, 0, 0)
		end

		local scrollBarProps: { [any]: any } = {
			Class = "Frame",
			ref = function(instance)
				setScrollBarContainer(instance :: Frame?)
			end,

			Size = function()
				local thickness = config.GetScrollBarThickness()
				if config.GetScrollingDirection() == "Y" then
					return UDim2.new(0, thickness, 1, 0)
				end

				return UDim2.new(1, 0, 0, thickness)
			end,
			Position = function()
				if config.GetScrollingDirection() == "Y" then
					return UDim2.fromScale(1, 0)
				end

				return UDim2.fromScale(0, 1)
			end,
			AnchorPoint = function()
				if config.GetScrollingDirection() == "Y" then
					return Vector2.new(1, 0)
				end

				return Vector2.new(0, 1)
			end,

			OnClick = onScrollBarClick,
		}

		local scrollBarChildProps: { [any]: any } = {
			BackgroundColor3 = config.GetScrollBarColor,
			Size = function()
				local scrollBarScale = 1 / math.max(config.GetElementCount(), 1)
				if config.GetScrollingDirection() == "Y" then
					return UDim2.new(1, 0, scrollBarScale, 4)
				end

				return UDim2.new(scrollBarScale, 4, 1, 0)
			end,
			AnchorPoint = function()
				if not config.GetReversesAlignment() then
					return Vector2.zero
				end

				if config.GetScrollingDirection() == "Y" then
					return Vector2.new(0, 1)
				end

				return Vector2.new(1, 0)
			end,
			Position = getScrollBarPositionUDim2,
		}

		scrollBarProps[1] = Frame(scrollBarChildProps :: any)
		return Button(scrollBarProps :: any)
	end)

	local function destroy()
		removeScrollBarSmoother(scrollBarDragToken)
		removeScrollBarSmoother(scrollBarSmootherToken)
	end

	return {
		ScrollBarElement = scrollBarElement,
		Destroy = destroy,
	}
end

-- 유틸 함수 export
createScrollBarControl.addScrollBarSmoother = addScrollBarSmoother
createScrollBarControl.removeScrollBarSmoother = removeScrollBarSmoother

return createScrollBarControl
