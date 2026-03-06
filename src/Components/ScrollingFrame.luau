--[=[
	@class ScrollingFrame

	ScrollingFrame 기반의 래퍼 컴포넌트입니다.
]=]

local Frame = require("./Frame")
local Props = require("../Utils/Props")
local TableUtil = require("../../roblox_packages/TableUtil")
local Theme = require("../Contexts/Theme")
local reactive = require("../Reactive")

type Prop<T> = T | (() -> T)

local DEFAULT_SCROLLBAR_IMAGE_CONTENT = Content.fromAssetId(1195495135)

local OWN_PROPS_SCHEMA = {}

export type ScrollingFrameOwnProps = typeof(OWN_PROPS_SCHEMA)

type ScrollingFrameBaseProps = {

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

export type ScrollingFrameProps = ScrollingFrameOwnProps & ScrollingFrameBaseProps

local function ScrollingFrame(props: ScrollingFrameProps)
	local themeContext = reactive.useContext(Theme)
	local getTheme = themeContext.Get

	local base = {
		Class = "ScrollingFrame",

		MidImageContent = DEFAULT_SCROLLBAR_IMAGE_CONTENT,
		BottomImageContent = DEFAULT_SCROLLBAR_IMAGE_CONTENT,
		TopImageContent = DEFAULT_SCROLLBAR_IMAGE_CONTENT,
		ScrollBarThickness = function()
			return math.max(4 / getTheme().DisplayScale, 1)
		end,

		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,

		ScrollBarImageColor3 = props.ScrollBarImageColor3 or function()
			return getTheme().ScrollBar
		end,
	}

	local _, forwardProps = Props.splitProps(props :: any, OWN_PROPS_SCHEMA)

	return Frame(TableUtil.merge(base, forwardProps) :: any)
end

return ScrollingFrame
