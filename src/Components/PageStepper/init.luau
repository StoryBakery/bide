--[=[
	@class PageStepper

	페이지 전환을 위한 스텝 버튼 컴포넌트입니다.
]=]

local DynamicTimer = require("../../roblox_packages/DynamicTimer")
local vide = require("../vide")

local Props = require("../Utils/Props")

local AspectRatioConstraint = require("../Layout/AspectRatio")
local Frame = require("./Frame")
local GridLayout = require("../Layout/GridLayout")
local SizeConstraint = require("../Layout/SizeConstraint")
local TextLabel = require("./TextLabel")

local StepButton = require("@self/StepButton")

local cleanup = vide.cleanup
local create = vide.create
local effect = vide.effect
local read = vide.read
local source = vide.source

export type PageStepperProps = {

	CurrentPage: number,

	Pages: { any },

	PageTweenDuration: number?,

	OnChangingPage: (pageDelta: number) -> (),
} & Frame.FrameProps

local OWNED_KEY_SET = Props.keySet({
	"CurrentPage",
	"Pages",
	"PageTweenDuration",
	"OnChangingPage",
})

local function PageStepper(props: PageStepperProps)
	local ownedProps, forwardProps, children = Props.extract(props :: any, OWNED_KEY_SET)
	local currentPage = read(ownedProps.CurrentPage)
	local pages = read(ownedProps.Pages) :: { any }
	local pageTweenDuration = read(ownedProps.PageTweenDuration)
	local onChangingPage = ownedProps.OnChangingPage

	local scrollPos = source(0)
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
				scrollPos(value)
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

	Props.appendChild(
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
			onChangingPage(-1)
		end,
	}) :: any)

	local rightStep = StepButton(({
		Text = "▶",
		Position = UDim2.new(1, -5, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		OnClick = function()
			onChangingPage(1)
		end,
	}) :: any)

	local frameProps: { [any]: any } = {}
	for key, value in forwardProps do
		frameProps[key] = value
	end
	Props.appendChildren(frameProps, children)

	Props.appendChild(frameProps, leftStep)
	Props.appendChild(frameProps, rightStep)
	Props.appendChild(frameProps, TextLabel(pageDisplayProps :: any))
	Props.appendChild(frameProps, pagesFolder)

	return Frame(frameProps :: any)
end

return PageStepper
