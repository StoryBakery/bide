--[=[
	@class Frame

	모든 bide 컴포넌트의 기본 래퍼입니다.
	Roblox GuiObject 를 생성하고 테마 기본값과 UICorner/UIStroke를 적용합니다.
]=]

local Instance = require("../Instance")
local reactive = require("../Reactive")

local Props = require("../Utils/Props")
local Theme = require("../Contexts/Theme")

local create = Instance.create
local read = reactive.read

type Prop<T> = T | (() -> T)

local OWN_PROPS_SCHEMA = {
	Class = Props.optional<<string>>(),
	CornerRadius = Props.optional<<number | UDim>>(),
	Transparency = Props.optional<<number>>(),
	StrokeColor = Props.optional<<Color3>>(),
	StrokeEnabled = Props.optional<<boolean>>(),
	StrokeThickness = Props.optional<<number>>(),
	StrokeTransparency = Props.optional<<number>>(),
}

export type FrameOwnProps = typeof(OWN_PROPS_SCHEMA)

type FrameBaseProps = {
	Attach: any?,
	Size: Prop<UDim2>?,
	Position: Prop<UDim2>?,
	AnchorPoint: Prop<Vector2>?,
	BackgroundColor3: Prop<Color3>?,
	BackgroundTransparency: Prop<number>?,
	LayoutOrder: Prop<number>?,
	ZIndex: Prop<number>?,
	Rotation: Prop<number>?,
	AutomaticSize: Prop<Enum.AutomaticSize>?,
	SizeConstraint: Prop<Enum.SizeConstraint>?,
	Visible: Prop<boolean>?,
	ClipsDescendants: Prop<boolean>?,
	Name: string?,
}

export type FrameProps = FrameOwnProps & FrameBaseProps

local function createUICorner(cornerRadius: number | UDim): Instance
	local radius: UDim
	if typeof(cornerRadius) == "number" then
		if cornerRadius >= 0 and cornerRadius <= 1 then
			radius = UDim.new(cornerRadius, 0)
		else
			radius = UDim.new(0, cornerRadius)
		end
	else
		radius = cornerRadius
	end
	return create "UICorner" { CornerRadius = radius }
end

local function Frame(props: FrameProps): GuiBase2d
	local ownProps, forwardProps, children = Props.splitProps(props :: any, OWN_PROPS_SCHEMA)
	local class = (read(ownProps.Class) :: string?) or "Frame"
	local themeContext = reactive.useContext(Theme)
	local getTheme = themeContext.Get

	if forwardProps.BorderSizePixel == nil then
		forwardProps.BorderSizePixel = 0
	end
	if forwardProps.BackgroundColor3 == nil then
		forwardProps.BackgroundColor3 = function()
			return getTheme().Background
		end
	end
	if forwardProps.BackgroundTransparency == nil and ownProps.Transparency ~= nil then
		forwardProps.BackgroundTransparency = ownProps.Transparency
	end
	if forwardProps.Size == nil then
		forwardProps.Size = UDim2.fromScale(1, 1)
	end

	local function getStrokeTransparency()
		local strokeEnabled = read(ownProps.StrokeEnabled)
		local transparency = read(ownProps.StrokeTransparency)
		if strokeEnabled == nil or strokeEnabled == true then
			return transparency or 0
		end
		return 1
	end

	table.insert(
		children,
		create "UIStroke" {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = function()
				return read(ownProps.StrokeColor) or getTheme().Stroke
			end,
			Thickness = function()
				return read(ownProps.StrokeThickness) or 1
			end,
			Transparency = getStrokeTransparency,
		}
	)

	local cornerRadius = read(ownProps.CornerRadius) :: (number | UDim)?
	if cornerRadius ~= nil and cornerRadius ~= 0 then
		table.insert(children, createUICorner(cornerRadius))
	end

	if #children > 0 then
		table.move(children, 1, #children, #forwardProps + 1, forwardProps)
	end

	return create(class)(forwardProps)
end

return Frame
