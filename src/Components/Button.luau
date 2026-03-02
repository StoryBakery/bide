--[=[
	@class Button

	완전한 버튼 컴포넌트입니다.
	Interactive + Highlight + PressScale + Ripple + Clickable + Tooltip 을 조합합니다.
	Icon과 Text를 자동 레이아웃합니다.

	```luau
		Button({
			Text = "확인",
			IconContent = Content.fromAssetId(123),
			OnClick = function(io) print("clicked") end,
		})
	```
]=]

local vide = require("../vide")

local Clickable = require("../Behaviors/Clickable")
local Highlight = require("../Behaviors/Highlight")
local Interactive = require("../Core/Interactive")
local PressScale = require("../Behaviors/PressScale")
local Props = require("../Utils/Props")
local Ripple = require("../Behaviors/Ripple")
local Tooltip = require("../Behaviors/Tooltip")
local area = require("../Contexts/Area")
local theme = require("../Contexts/Theme")

local create = vide.create
local signal = vide.signal
local read = vide.read

type Prop<T> = T | (() -> T)

export type ButtonProps = {
	-- 외관
	ButtonColor: Prop<Color3>?,
	HighlightColor: Prop<Color3>?,
	ClickEffectColor: Prop<Color3>?,
	ClickEffectImageContent: Prop<Content>?,
	CornerRadius: Prop<number | UDim>?,

	-- 텍스트
	Text: Prop<string>?,
	TextColor3: Prop<Color3>?,
	TextSize: number?,
	TextScaled: boolean?,
	TextXAlignment: Enum.TextXAlignment?,
	TextYAlignment: Enum.TextYAlignment?,
	TextTransparency: number?,
	FontFace: Font?,

	-- 아이콘
	IconContent: Prop<Content>?,
	IconColor: Prop<Color3>?,

	-- 상호작용
	AutoScaleEnabled: boolean?,
	OnClick: ((inputObject: InputObject) -> ())?,
	OnMouseButton1Click: ((inputObject: InputObject) -> ())?,
	OnMouseButton2Click: ((inputObject: InputObject) -> ())?,
	OnMouseButton3Click: ((inputObject: InputObject) -> ())?,
	OnTouch: ((inputObject: InputObject) -> ())?,
	OnEnter: (() -> ())?,
	OnLeave: (() -> ())?,

	-- 기타
	TooltipText: string?,
	Size: Prop<UDim2>?,
	Position: Prop<UDim2>?,
	AnchorPoint: Prop<Vector2>?,
	LayoutOrder: Prop<number>?,
	ZIndex: Prop<number>?,
	Visible: Prop<boolean>?,
	AutomaticSize: Prop<Enum.AutomaticSize>?,
}

local OWNED_KEY_SET = Props.keySet({
	"AutoScaleEnabled",
	"ButtonColor",
	"ClickEffectColor",
	"ClickEffectImageContent",
	"CornerRadius",
	"FontFace",
	"HighlightColor",
	"IconContent",
	"IconColor",
	"OnClick",
	"OnEnter",
	"OnLeave",
	"OnMouseButton1Click",
	"OnMouseButton2Click",
	"OnMouseButton3Click",
	"OnTouch",
	"Text",
	"TextColor3",
	"TextScaled",
	"TextSize",
	"TextTransparency",
	"TextXAlignment",
	"TextYAlignment",
	"TooltipText",
})

local EMPTY_CONTENT = Content.fromUri("")

-- 내부: 아이콘 생성
local function createIcon(props: { [any]: any }): GuiBase2d?
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
			return read(iconColor) or theme().ButtonIcon
		end,
		LayoutOrder = 100,
		ScaleType = Enum.ScaleType.Fit,
	}
end

-- 내부: 텍스트 생성
local function createText(props: { [any]: any }): GuiBase2d?
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
			return read(props.TextColor3) or theme().ButtonText
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
	local owned, forward, children = Props.extract(props :: any, OWNED_KEY_SET)

	local _, setIsHighlight = signal(false)

	-- 색상 getter
	local function getButtonColor(): Color3
		return read(owned.ButtonColor) or theme().Button
	end
	local function getHighlightColor(): Color3
		return read(owned.HighlightColor) or theme().ButtonHighlight
	end
	local function getClickEffectColor(): Color3
		return read(owned.ClickEffectColor) or theme().ButtonClickEffect
	end

	-- Behaviors 조합
	local autoScale = if owned.AutoScaleEnabled == nil then true else owned.AutoScaleEnabled
	local interactiveChildren: { any } = {}

	-- Highlight
	interactiveChildren[#interactiveChildren + 1] = Highlight({
		NormalColor = getButtonColor,
		HighlightColor = getHighlightColor,
		Duration = 0.1,
	})

	-- PressScale
	if autoScale then
		interactiveChildren[#interactiveChildren + 1] = PressScale({
			DefaultScale = 1,
			HoverScale = 1.05,
			PressedScale = 0.95,
			Duration = 0.2,
		})
	end

	-- Ripple
	interactiveChildren[#interactiveChildren + 1] = Ripple({
		Color = getClickEffectColor,
		ImageContent = function()
			return read(owned.ClickEffectImageContent) or theme().ButtonClickEffectImageContent
		end,
		ResolutionScale = function()
			return area().ResolutionScale :: number
		end,
	})

	-- Clickable
	interactiveChildren[#interactiveChildren + 1] = Clickable({
		OnClick = owned.OnClick,
		OnMouseButton1Click = owned.OnMouseButton1Click,
		OnMouseButton2Click = owned.OnMouseButton2Click,
		OnMouseButton3Click = owned.OnMouseButton3Click,
		OnTouch = owned.OnTouch,
		OnEnter = owned.OnEnter,
		OnLeave = owned.OnLeave,
		OnHoverBegin = function()
			setIsHighlight(true)
		end,
		OnHoverEnd = function()
			setIsHighlight(false)
		end,
		UserInputManager = area().UserInputManager,
	})

	-- Tooltip
	if owned.TooltipText then
		interactiveChildren[#interactiveChildren + 1] = Tooltip({
			Text = owned.TooltipText,
		})
	end

	-- 내부 콘텐츠 (Icon + Text + Layout)
	local iconElement = createIcon(owned)
	local textElement = createText(owned)
	local hasContent = iconElement or textElement

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
		Props.appendChildren(contentProps, contentChildren)
		interactiveChildren[#interactiveChildren + 1] = create "Frame"(contentProps)
	end

	-- 사용자 children 추가
	Props.appendChildren(interactiveChildren, children)

	-- Interactive props 조립
	local interactiveProps: { [any]: any } = table.clone(forward)
	interactiveProps.BackgroundColor3 = getButtonColor
	if interactiveProps.Size == nil then
		interactiveProps.Size = UDim2.fromScale(1, 1)
	end
	Props.appendChildren(interactiveProps, interactiveChildren)

	return Interactive(interactiveProps :: any)
end

return Button
