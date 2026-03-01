--[=[
	@class Element

	모든 videkery 컴포넌트의 기본 래퍼입니다.
	Roblox GuiObject 를 생성하고 테마 기본값과 UICorner/UIStroke를 적용합니다.
]=]

local vide = require("../vide")

local Props = require("../Utils/Props")
local theme = require("../Contexts/Theme")

local create = vide.create
local read = vide.read

type Prop<T> = T | (() -> T)

export type ElementProps = {
	Class: string?,
	CornerRadius: Prop<number | UDim>?,
	Size: Prop<UDim2>?,
	Position: Prop<UDim2>?,
	AnchorPoint: Prop<Vector2>?,
	BackgroundColor3: Prop<Color3>?,
	BackgroundTransparency: Prop<number>?,
	Transparency: Prop<number>?,
	LayoutOrder: Prop<number>?,
	ZIndex: Prop<number>?,
	Rotation: Prop<number>?,
	StrokeColor: Prop<Color3>?,
	StrokeEnabled: Prop<boolean>?,
	StrokeThickness: Prop<number>?,
	StrokeTransparency: Prop<number>?,
	AutomaticSize: Prop<Enum.AutomaticSize>?,
	SizeConstraint: Prop<Enum.SizeConstraint>?,
	Visible: Prop<boolean>?,
	ClipsDescendants: Prop<boolean>?,
	Name: string?,
}

local OWNED_KEY_SET = Props.keySet({
	"Class",
	"CornerRadius",
	"StrokeColor",
	"StrokeEnabled",
	"StrokeThickness",
	"StrokeTransparency",
})

local function createUICorner(cornerRadius: number | UDim): Instance
	local r: UDim
	if typeof(cornerRadius) == "number" then
		if cornerRadius >= 0 and cornerRadius <= 1 then
			r = UDim.new(cornerRadius, 0)
		else
			r = UDim.new(0, cornerRadius)
		end
	else
		r = cornerRadius
	end
	return create "UICorner" { CornerRadius = r }
end

local function Element(props: ElementProps): GuiBase2d
	local owned, forward, children = Props.extract(props :: any, OWNED_KEY_SET)
	local class = (owned.Class :: string?) or "Frame"

	-- 기본값 적용
	if forward.BorderSizePixel == nil then
		forward.BorderSizePixel = 0
	end
	if forward.BackgroundColor3 == nil then
		forward.BackgroundColor3 = function()
			return theme().Background
		end
	end
	if forward.BackgroundTransparency == nil and owned.Transparency ~= nil then
		forward.BackgroundTransparency = owned.Transparency
	end
	if forward.Size == nil then
		forward.Size = UDim2.fromScale(1, 1)
	end

	-- UIStroke
	local function getStrokeTransparency()
		local strokeEnabled = read(owned.StrokeEnabled)
		local transparency = read(owned.StrokeTransparency)
		if strokeEnabled == nil or strokeEnabled == true then
			return transparency or 0
		end
		return 1
	end

	Props.appendChild(
		children,
		create "UIStroke" {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = function()
				return read(owned.StrokeColor) or theme().Stroke
			end,
			Thickness = function()
				return read(owned.StrokeThickness) or 1
			end,
			Transparency = getStrokeTransparency,
		}
	)

	-- UICorner
	local cornerRadius = read(owned.CornerRadius) :: (number | UDim)?
	if cornerRadius ~= nil and cornerRadius ~= 0 then
		Props.appendChild(children, createUICorner(cornerRadius))
	end

	-- children 을 forward에 병합
	Props.appendChildren(forward, children)

	return create(class)(forward)
end

return Element
