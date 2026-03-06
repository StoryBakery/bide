--[=[
	@class ImageLabel

	테마 기본값이 적용된 ImageLabel 래퍼입니다.
]=]

local TableUtil = require("../../roblox_packages/TableUtil")
local reactive = require("../Reactive")

local Frame = require("./Frame")
local Props = require("../Utils/Props")

local read = reactive.read

type Prop<T> = T | (() -> T)

local OWN_PROPS_SCHEMA = {
	ImageContent = Props.optional<<Content>>(),
	ImageColor3 = Props.optional<<Color3>>(),
}

export type ImageLabelOwnProps = typeof(OWN_PROPS_SCHEMA)

type ImageLabelBaseProps = {
	ImageTransparency: Prop<number>?,
	ScaleType: Prop<Enum.ScaleType>?,
} & Frame.FrameProps

export type ImageLabelProps = ImageLabelOwnProps & ImageLabelBaseProps

local EMPTY_CONTENT = Content.fromUri("")

local function ImageLabel(props: ImageLabelProps): GuiBase2d
	local ownProps, forwardProps, children = Props.splitProps(props :: any, OWN_PROPS_SCHEMA)

	local base = {
		Class = "ImageLabel",
		BackgroundTransparency = 1,
		ImageContent = function()
			return read(ownProps.ImageContent) or EMPTY_CONTENT
		end,
		ImageColor3 = function()
			return read(ownProps.ImageColor3) or Color3.new(1, 1, 1)
		end,
		StrokeEnabled = false,
		ScaleType = Enum.ScaleType.Fit,
	}

	local elementProps = TableUtil.merge(base, forwardProps)
	if #children > 0 then
		table.move(children, 1, #children, #elementProps + 1, elementProps)
	end

	return Frame(elementProps :: any)
end

return ImageLabel
