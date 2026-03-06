--[=[
	@class StepButton
]=]

local AspectRatioConstraint = require("../../Layout/AspectRatio")
local TableUtil = require("../../../roblox_packages/TableUtil")
local Button = require("../Button")
local Padding = require("../../Layout/Padding")

local OWN_PROPS_SCHEMA = {}

export type StepButtonOwnProps = typeof(OWN_PROPS_SCHEMA)

export type StepButtonProps = StepButtonOwnProps & Button.ButtonProps

local stepFont = Font.fromName("Zekton", Enum.FontWeight.Bold, Enum.FontStyle.Normal)

local function StepButton(props: StepButtonProps)
	local buttonProps = TableUtil.merge({
		CornerRadius = if props.CornerRadius == nil then 0.2 else props.CornerRadius,
		FontFace = props.FontFace or stepFont,
		Size = props.Size or UDim2.fromScale(0.05, 0.15),
		TextScaled = if props.TextScaled == nil then true else props.TextScaled,
		TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Center,
	}, props :: any) :: { [any]: any }

	table.insert(
		buttonProps,
		Padding({
			PaddingLeft = UDim.new(0.2, 0),
			PaddingRight = UDim.new(0.2, 0),
			PaddingTop = UDim.new(0.2, 0),
			PaddingBottom = UDim.new(0.2, 0),
		})
	)
	table.insert(
		buttonProps,
		AspectRatioConstraint({
			AspectRatio = 0.2,
		})
	)

	return Button(buttonProps :: any)
end

return StepButton
