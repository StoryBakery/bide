--[=[
	@class PageStepper

	페이지 전환을 위한 스텝 버튼 컴포넌트입니다.
]=]

local DynamicTimer = require("../../roblox_packages/DynamicTimer")
local Instance = require("../Instance")
local reactive = require("../Reactive")

local Props = require("../Utils/Props")

local AspectRatioConstraint = require("../Layout/AspectRatio")
local Frame = require("./Frame")
local GridLayout = require("../Layout/GridLayout")
local SizeConstraint = require("../Layout/SizeConstraint")
local TextLabel = require("./TextLabel")

local StepButton = require("@self/StepButton")

local create = Instance.create
local effect = reactive.effect
local signal = reactive.signal
local cleanup = reactive.cleanup
local read = reactive.read

local OWN_PROPS_SCHEMA = {
	CurrentPage = Props.required<<number>>(),
	Pages = Props.required<<{ any }>>(),
	PageTweenDuration = Props.optional<<number>>(),
	OnChangingPage = Props.required<<((pageDelta: number) -> ())>>(),
}

export type PageStepperOwnProps = typeof(OWN_PROPS_SCHEMA)

export type PageStepperProps = PageStepperOwnProps & Frame.FrameProps

local function PageStepper(props: PageStepperProps)
	local ownProps, forwardProps, children = Props.splitProps(props :: any, OWN_PROPS_SCHEMA)
	local currentPage = read(ownProps.CurrentPage)
	local pages = read(ownProps.Pages) :: { any }
	local pageTweenDuration = read(ownProps.PageTweenDuration)

	local scrollPos, setScrollPos = signal(0)
	local scrollTween: DynamicTimer.DynamicTween?

	effect(function()
		if scrollTween then
			scrollTween:Destroy()
		end

		local paddingTween = DynamicTimer:CreateTween({
			Start = scrollPos(),
			Goal = currentPage - 1,
			Duration = pageTweenDuration or 0.2,
			Callback = function(value)
				setScrollPos(value)
			end,
		}) :: DynamicTimer.DynamicTween
		paddingTween:Play()
		scrollTween = paddingTween
	end)

	cleanup(function()
		if scrollTween then
			scrollTween:Destroy()
		end
	end)

	local scrollingFrameInstance = nil

	local scrollingFrameProps: { [any]: any } = {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ScrollBarThickness = 0,
		ScrollingEnabled = false,

		CanvasPosition = function()
			if scrollingFrameInstance == nil then
				return Vector2.zero
			end

			return Vector2.new(scrollPos() * scrollingFrameInstance.AbsoluteSize.X, 0)
		end,
		CanvasSize = UDim2.fromScale(#pages, 1),
	}

	for index, page in pages do
		scrollingFrameProps[index] = page
	end

	table.insert(
		scrollingFrameProps,
		GridLayout {
			CellSize = UDim2.fromScale(1 / #pages, 1),
			CellPadding = UDim2.fromScale(0, 0),
			VerticalAlignment = Enum.VerticalAlignment.Top,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
		}
	)

	scrollingFrameInstance = create "ScrollingFrame"(scrollingFrameProps)
	local pagesFolder = create "Folder" { scrollingFrameInstance }

	local pageDisplayProps = {
		Size = UDim2.fromScale(0.1, 0.1),
		Position = UDim2.new(1, -5, 0, 2),
		AnchorPoint = Vector2.new(1, 0),
		StrokeEnabled = false,
		BackgroundTransparency = 1,
		Text = `{currentPage}/{#pages}`,
		TextXAlignment = Enum.TextXAlignment.Right,
		SizeConstraint = SizeConstraint({
			MaxSize = Vector2.new(70, 15),
		}),
		AspectRatioConstraint = AspectRatioConstraint({
			AspectRatio = 4,
		}),
	}

	local leftStep = StepButton(({
		Text = "◀",
		Position = UDim2.new(0, 5, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		OnClick = function()
			local onChangingPage = read(ownProps.OnChangingPage) :: ((number) -> ())?
			if onChangingPage == nil then
				return
			end
			onChangingPage(-1)
		end,
	}) :: any)

	local rightStep = StepButton(({
		Text = "▶",
		Position = UDim2.new(1, -5, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		OnClick = function()
			local onChangingPage = read(ownProps.OnChangingPage) :: ((number) -> ())?
			if onChangingPage == nil then
				return
			end
			onChangingPage(1)
		end,
	}) :: any)

	local frameProps: { [any]: any } = {}
	for key, value in forwardProps do
		frameProps[key] = value
	end
	if #children > 0 then
		table.move(children, 1, #children, #frameProps + 1, frameProps)
	end

	table.insert(frameProps, leftStep)
	table.insert(frameProps, rightStep)
	table.insert(frameProps, TextLabel(pageDisplayProps :: any))
	table.insert(frameProps, pagesFolder)

	return Frame(frameProps :: any)
end

return PageStepper
