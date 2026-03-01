--[=[
	@class ImageLabel

	테마 기본값이 적용된 ImageLabel 래퍼입니다.
]=]

local vide = require("../vide")

local Element = require("../Core/Element")
local Props = require("../Utils/Props")

local read = vide.read

type Prop<T> = T | (() -> T)

export type ImageLabelProps = {
	ImageContent: Prop<Content>?,
	ImageColor3: Prop<Color3>?,
	ImageTransparency: Prop<number>?,
	ScaleType: Prop<Enum.ScaleType>?,
}

local OWNED_KEY_SET = Props.keySet({
	"ImageContent",
	"ImageColor3",
})

local EMPTY_CONTENT = Content.fromUri("")

local function ImageLabel(props: ImageLabelProps): GuiBase2d
	local owned, forward, children = Props.extract(props :: any, OWNED_KEY_SET)

	local base = {
		Class = "ImageLabel",
		BackgroundTransparency = 1,
		ImageContent = function()
			return read(owned.ImageContent) or EMPTY_CONTENT
		end,
		ImageColor3 = function()
			return read(owned.ImageColor3) or Color3.new(1, 1, 1)
		end,
		StrokeEnabled = false,
		ScaleType = Enum.ScaleType.Fit,
	}

	local elementProps = Props.merge(base, forward)
	Props.appendChildren(elementProps, children)

	return Element(elementProps :: any)
end

return ImageLabel
