--[=[
	@class Interactive

	Behavior 조합을 자유롭게 구성하는 인터랙티브 프리미티브입니다.
	InteractionState를 자동 생성하고 각 BehaviorFactory의 apply에 주입합니다.

	```luau
	Interactive({
		Size = UDim2.fromScale(1, 1),

		Highlight({ NormalColor = ..., HighlightColor = ... }),
		PressScale(),
		Ripple({ Color = ... }),
		Clickable({ OnClick = ... }),
		TextLabel({ Text = "Click me" }),
	})
	```
]=]

local vide = require("../vide")

local Element = require("./Element")
local Props = require("../Utils/Props")
local createInteractionState = require("./InteractionState")

local action = vide.action
local cleanup = vide.cleanup

export type BehaviorFactory = {
	apply: (instance: GuiObject, state: any?) -> { Destroy: (() -> ())? }?,
}

export type InteractiveProps = Element.ElementProps

local function isBehaviorFactory(value: any): boolean
	return type(value) == "table" and type(value.apply) == "function"
end

local function Interactive(props: InteractiveProps): GuiBase2d
	local _, forward, children = Props.extract(props :: any, {})

	if forward.Class == nil then
		forward.Class = "ImageButton"
	end

	-- BehaviorFactory와 일반 children을 분리
	local behaviorFactories: { BehaviorFactory } = {}
	local contentChildren: { any } = {}

	for _, child in children do
		if isBehaviorFactory(child) then
			behaviorFactories[#behaviorFactories + 1] = child
		else
			contentChildren[#contentChildren + 1] = child
		end
	end

	-- element props 조립
	local elementProps: { [any]: any } = table.clone(forward)
	Props.appendChildren(elementProps, contentChildren)

	-- Behavior 적용 action
	if #behaviorFactories > 0 then
		Props.appendChild(
			elementProps,
			action(function(instance: Instance)
				local guiObject = instance :: GuiObject
				local interactionState = createInteractionState(guiObject)

				for _, factory in behaviorFactories do
					local result = factory.apply(guiObject, interactionState)
					if result and result.Destroy then
						cleanup(result.Destroy)
					end
				end
			end)
		)
	end

	return Element(elementProps :: any)
end

return Interactive
