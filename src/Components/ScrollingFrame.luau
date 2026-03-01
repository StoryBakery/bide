--[=[
	@class ScrollingFrame

	ScrollingFrame 기반의 래퍼 컴포넌트입니다.
]=]

local Frame = require("./Frame")
local Props = require("../Utils/Props")
local area = require("../Contexts/Area")
local theme = require("../Contexts/Theme")

type Prop<T> = T | (() -> T)

local DEFAULT_SCROLLBAR_IMAGE_CONTENT = Content.fromAssetId(1195495135)

export type ScrollingFrameProps = {

	--roblox scrolling frame props
	AutomaticCanvasSize: Prop<Enum.AutomaticSize>?,
	CanvasSize: Prop<UDim2>?,
	CanvasPosition: Prop<Vector2>?,

	ScrollingEnabled: Prop<boolean>?,

	ScrollBarThickness: Prop<number>?,
	ScrollBarImageColor3: Prop<Color3>?,
	ScrollBarImageTransparency: Prop<number>?,
	ScrollingDirection: Prop<Enum.ScrollingDirection>?,

	TopImageContent: Prop<Content>?,
	MidImageContent: Prop<Content>?,
	BottomImageContent: Prop<Content>?,

	HorizontalScrollBarInset: Prop<Enum.ScrollBarInset>?,
	VerticalScrollBarInset: Prop<Enum.ScrollBarInset>?,

	VerticalScrollBarPosition: Prop<Enum.VerticalScrollBarPosition>?,

	ElasticBehavior: Prop<Enum.ElasticBehavior>?,
} & Frame.FrameProps

local function ScrollingFrame(props: ScrollingFrameProps)
	local base = {
		Class = "ScrollingFrame",

		MidImageContent = DEFAULT_SCROLLBAR_IMAGE_CONTENT,
		BottomImageContent = DEFAULT_SCROLLBAR_IMAGE_CONTENT,
		TopImageContent = DEFAULT_SCROLLBAR_IMAGE_CONTENT,
		ScrollBarThickness = function()
			return math.max(4 / area().ResolutionScale, 1)
		end,

		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,

		ScrollBarImageColor3 = props.ScrollBarImageColor3 or function()
			return theme().ScrollBar
		end,
	}

	local _, forwardProps = Props.extract(props :: any, {})

	return Frame(Props.merge(base, forwardProps) :: any)
end

return ScrollingFrame
