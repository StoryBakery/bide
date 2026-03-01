--[=[
	@class TextLabel

	테마 기본값이 적용된 TextLabel 래퍼입니다.
]=]

local vide = require("../vide")

local Element = require("../Core/Element")
local Props = require("../Utils/Props")
local theme = require("../Contexts/Theme")

local read = vide.read

type Prop<T> = T | (() -> T)

export type TextLabelProps = {
	Text: Prop<string>?,
	TextColor3: Prop<Color3>?,
	TextSize: Prop<number>?,
	TextScaled: boolean?,
	TextXAlignment: Prop<Enum.TextXAlignment>?,
	TextYAlignment: Prop<Enum.TextYAlignment>?,
	TextTransparency: Prop<number>?,
	FontFace: Font?,
}

local OWNED_KEY_SET = Props.keySet({
	"Text",
	"TextColor3",
	"TextSize",
	"FontFace",
})

local function TextLabel(props: TextLabelProps): GuiBase2d
	local owned, forward, children = Props.extract(props :: any, OWNED_KEY_SET)

	local base = {
		Class = "TextLabel",
		BackgroundTransparency = 1,
		Text = function()
			return read(owned.Text) or ""
		end,
		TextColor3 = function()
			return read(owned.TextColor3) or theme().Text
		end,
		TextSize = function()
			return read(owned.TextSize) or 14
		end,
		FontFace = owned.FontFace,
		StrokeEnabled = false,
	}

	local elementProps = Props.merge(base, forward)
	Props.appendChildren(elementProps, children)

	return Element(elementProps :: any)
end

return TextLabel
