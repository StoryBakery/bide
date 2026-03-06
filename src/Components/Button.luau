--[=[
	@class Button

	완전한 버튼 컴포넌트입니다.
	Frame 루트에 여러 attachment를 조합해 버튼 동작을 만듭니다.
	Icon과 Text를 자동 레이아웃합니다.

	```luau
		Button({
			Text = "확인",
			IconContent = Content.fromAssetId(123),
			OnClick = function(io) print("clicked") end,
		})
	```
]=]

local Instance = require("../Instance")
local reactive = require("../Reactive")

local Area = require("../Contexts/Area")
local Clickable = require("../Attachments/Clickable")
local Frame = require("./Frame")
local Highlight = require("../Attachments/Highlight")
local PressScale = require("../Attachments/PressScale")
local Props = require("../Utils/Props")
local Ripple = require("../Attachments/Ripple")
local Theme = require("../Contexts/Theme")
local Tooltip = require("../Attachments/Tooltip")

local create = Instance.create
local read = reactive.read

type Prop<T> = T | (() -> T)
type ThemeValue = typeof(Theme.BuiltInThemes.Dark)
type ThemeAccessor = () -> ThemeValue

local OWN_PROPS_SCHEMA = {
	ButtonColor = Props.optional<<Color3>>(),
	HighlightColor = Props.optional<<Color3>>(),
	ClickEffectColor = Props.optional<<Color3>>(),
	ClickEffectImageContent = Props.optional<<Content>>(),
	CornerRadius = Props.optional<<number | UDim>>(),
	Text = Props.optional<<string>>(),
	TextColor3 = Props.optional<<Color3>>(),
	TextSize = Props.optional<<number>>(),
	TextScaled = Props.optional<<boolean>>(),
	TextXAlignment = Props.optional<<Enum.TextXAlignment>>(),
	TextYAlignment = Props.optional<<Enum.TextYAlignment>>(),
	TextTransparency = Props.optional<<number>>(),
	FontFace = Props.optional<<Font>>(),
	IconContent = Props.optional<<Content>>(),
	IconColor = Props.optional<<Color3>>(),
	AutoScaleEnabled = Props.optional<<boolean>>(),
	OnClick = Props.optional<<((inputObject: InputObject) -> ())>>(),
	OnMouseButton1Click = Props.optional<<((inputObject: InputObject) -> ())>>(),
	OnMouseButton2Click = Props.optional<<((inputObject: InputObject) -> ())>>(),
	OnMouseButton3Click = Props.optional<<((inputObject: InputObject) -> ())>>(),
	OnTouch = Props.optional<<((inputObject: InputObject) -> ())>>(),
	OnEnter = Props.optional<<(() -> ())>>(),
	OnLeave = Props.optional<<(() -> ())>>(),
	TooltipText = Props.optional<<string>>(),
}

export type ButtonOwnProps = typeof(OWN_PROPS_SCHEMA)

type ButtonBaseProps = {
	-- 외관
	Size: Prop<UDim2>?,
	Position: Prop<UDim2>?,
	AnchorPoint: Prop<Vector2>?,
	Attach: any?,
	LayoutOrder: Prop<number>?,
	ZIndex: Prop<number>?,
	Visible: Prop<boolean>?,
	AutomaticSize: Prop<Enum.AutomaticSize>?,
}

export type ButtonProps = ButtonOwnProps & ButtonBaseProps

local EMPTY_CONTENT = Content.fromUri("")

local function appendAttach(targetProps: { [any]: any }, attachment: any)
	if attachment == nil or attachment == false then
		return
	end

	if type(attachment) == "function" then
		local currentAttach = targetProps.Attach

		if currentAttach == nil then
			targetProps.Attach = { attachment }
		elseif type(currentAttach) == "function" then
			targetProps.Attach = { currentAttach, attachment }
		elseif type(currentAttach) == "table" then
			currentAttach[#currentAttach + 1] = attachment
		else
			error(`Invalid Attach prop type "{type(currentAttach)}"`)
		end

		return
	end

	if type(attachment) ~= "table" then
		error(`Invalid attachment type "{type(attachment)}"`)
	end

	for key, nestedAttachment in attachment do
		if type(key) ~= "number" then
			error(`Invalid attachment key "{tostring(key)}"`)
		end

		appendAttach(targetProps, nestedAttachment)
	end
end

-- 내부: 아이콘 생성
local function createIcon(props: { [any]: any }, getTheme: ThemeAccessor): GuiBase2d?
	local iconContent = props.IconContent :: (Content | (() -> Content))?
	if iconContent == nil then
		return nil
	end

	local iconColor = props.IconColor

	return create "ImageLabel" {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		Position = UDim2.fromScale(0, 0.5),
		AnchorPoint = Vector2.new(0, 0.5),
		ImageContent = function()
			return read(iconContent) or EMPTY_CONTENT
		end,
		ImageColor3 = function()
			return read(iconColor) or getTheme().ButtonIcon
		end,
		LayoutOrder = 100,
		ScaleType = Enum.ScaleType.Fit,
	}
end

-- 내부: 텍스트 생성
local function createText(props: { [any]: any }, getTheme: ThemeAccessor): GuiBase2d?
	local text = props.Text :: Prop<string>?
	if text == nil then
		return nil
	end

	return create "TextLabel" {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = function()
			return read(text) or ""
		end,
		TextColor3 = function()
			return read(props.TextColor3) or getTheme().ButtonText
		end,
		TextSize = props.TextSize or 14,
		TextScaled = props.TextScaled,
		TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Center,
		TextYAlignment = props.TextYAlignment or Enum.TextYAlignment.Center,
		TextTransparency = props.TextTransparency,
		FontFace = props.FontFace,
		LayoutOrder = 200,
		AutomaticSize = Enum.AutomaticSize.X,
	}
end

local function Button(props: ButtonProps): GuiBase2d
	local ownProps, forwardProps, children = Props.splitProps(props :: any, OWN_PROPS_SCHEMA)
	local area = reactive.useContext(Area) :: Area.AreaValue
	local themeContext = reactive.useContext(Theme)
	local getTheme = themeContext.Get

	-- 색상 getter
	local function getButtonColor(): Color3
		return read(ownProps.ButtonColor) or getTheme().Button
	end
	local function getHighlightColor(): Color3
		return read(ownProps.HighlightColor) or getTheme().ButtonHighlight
	end
	local function getClickEffectColor(): Color3
		return read(ownProps.ClickEffectColor) or getTheme().ButtonClickEffect
	end

	-- attachment 조합
	local autoScaleValue = read(ownProps.AutoScaleEnabled) :: boolean?
	local autoScale = if autoScaleValue == nil then true else autoScaleValue
	local buttonProps: { [any]: any } = table.clone(forwardProps)
	local userAttach = buttonProps.Attach
	buttonProps.Attach = nil

	appendAttach(
		buttonProps,
		Highlight({
			NormalColor = getButtonColor,
			HighlightColor = getHighlightColor,
			Duration = 0.1,
		})
	)

	if autoScale then
		appendAttach(
			buttonProps,
			PressScale({
				DefaultScale = 1,
				HoverScale = 1.05,
				PressedScale = 0.95,
				Duration = 0.2,
			})
		)
	end

	appendAttach(
		buttonProps,
		Ripple({
			Color = getClickEffectColor,
			ImageContent = function()
				return read(ownProps.ClickEffectImageContent)
					or getTheme().ButtonClickEffectImageContent
			end,
			DisplayScale = function()
				return getTheme().DisplayScale :: number
			end,
		})
	)

	appendAttach(
		buttonProps,
		Clickable({
			OnClick = read(ownProps.OnClick),
			OnMouseButton1Click = read(ownProps.OnMouseButton1Click),
			OnMouseButton2Click = read(ownProps.OnMouseButton2Click),
			OnMouseButton3Click = read(ownProps.OnMouseButton3Click),
			OnTouch = read(ownProps.OnTouch),
			OnEnter = read(ownProps.OnEnter),
			OnLeave = read(ownProps.OnLeave),
			UserInputManager = area.UserInputManager,
		})
	)

	if ownProps.TooltipText ~= nil then
		appendAttach(
			buttonProps,
			Tooltip({
				Text = ownProps.TooltipText,
			})
		)
	end

	appendAttach(buttonProps, userAttach)

	-- 내부 콘텐츠 (Icon + Text + Layout)
	local iconElement = createIcon(ownProps, getTheme)
	local textElement = createText(ownProps, getTheme)
	local hasContent = iconElement or textElement
	local buttonChildren: { any } = {}

	if hasContent then
		local contentChildren: { any } = {}
		if iconElement then
			contentChildren[#contentChildren + 1] = iconElement
		end
		if textElement then
			contentChildren[#contentChildren + 1] = textElement
		end
		contentChildren[#contentChildren + 1] = create "UIListLayout" {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 2),
			VerticalAlignment = Enum.VerticalAlignment.Center,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
		}
		contentChildren[#contentChildren + 1] = create "UIPadding" {
			PaddingLeft = UDim.new(0, 4),
			PaddingRight = UDim.new(0, 4),
			PaddingTop = UDim.new(0, 2),
			PaddingBottom = UDim.new(0, 2),
		}

		-- 콘텐츠 프레임
		local contentProps: { [any]: any } = {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
		}
		if #contentChildren > 0 then
			table.move(contentChildren, 1, #contentChildren, #contentProps + 1, contentProps)
		end
		buttonChildren[#buttonChildren + 1] = create "Frame"(contentProps)
	end

	if #children > 0 then
		table.move(children, 1, #children, #buttonChildren + 1, buttonChildren)
	end

	buttonProps.Class = "ImageButton"
	buttonProps.BackgroundColor3 = getButtonColor
	buttonProps.CornerRadius = ownProps.CornerRadius
	if buttonProps.Size == nil then
		buttonProps.Size = UDim2.fromScale(1, 1)
	end
	if #buttonChildren > 0 then
		table.move(buttonChildren, 1, #buttonChildren, #buttonProps + 1, buttonProps)
	end

	return Frame(buttonProps :: any)
end

return Button
