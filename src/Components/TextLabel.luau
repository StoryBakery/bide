--[=[
	@class TextLabel

	테마 기본값이 적용된 TextLabel 래퍼입니다.
]=]

local TableUtil = require("../../roblox_packages/TableUtil")
local reactive = require("../Reactive")

local Frame = require("./Frame")
local Props = require("../Utils/Props")
local Theme = require("../Contexts/Theme")

local read = reactive.read

type Prop<T> = T | (() -> T)

local OWN_PROPS_SCHEMA = {
	Text = Props.optional<<string>>(),
	TextColor3 = Props.optional<<Color3>>(),
	TextSize = Props.optional<<number>>(),
	FontFace = Props.optional<<Font>>(),
}

export type TextLabelOwnProps = typeof(OWN_PROPS_SCHEMA)

type TextLabelBaseProps = {
	TextScaled: boolean?,
	TextXAlignment: Prop<Enum.TextXAlignment>?,
	TextYAlignment: Prop<Enum.TextYAlignment>?,
	TextTransparency: Prop<number>?,
} & Frame.FrameProps

export type TextLabelProps = TextLabelOwnProps & TextLabelBaseProps

local function TextLabel(props: TextLabelProps): GuiBase2d
	local ownProps, forwardProps, children = Props.splitProps(props :: any, OWN_PROPS_SCHEMA)
	local themeContext = reactive.useContext(Theme)
	local getTheme = themeContext.Get

	local base = {
		Class = "TextLabel",
		BackgroundTransparency = 1,
		Text = function()
			return read(ownProps.Text) or ""
		end,
		TextColor3 = function()
			return read(ownProps.TextColor3) or getTheme().Text
		end,
		TextSize = function()
			return read(ownProps.TextSize) or 14
		end,
		FontFace = ownProps.FontFace,
		StrokeEnabled = false,
	}

	local elementProps = TableUtil.merge(base, forwardProps)
	if #children > 0 then
		table.move(children, 1, #children, #elementProps + 1, elementProps)
	end

	return Frame(elementProps :: any)
end

return TextLabel
