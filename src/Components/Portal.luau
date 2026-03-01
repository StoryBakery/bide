--[=[
	@class LayerCollectorPortal

	LayerCollector 기준으로 포탈을 생성하는 컴포넌트입니다.
]=]

local vide = require("../vide")

local Props = require("../Utils/Props")

local cleanup = vide.cleanup
local create = vide.create
local effect = vide.effect
local source = vide.source

export type LayerCollectorPortalProps = {
	Position: UDim2?,
	Size: UDim2?,
	ZIndex: number?,
}

local OWNED_KEY_SET = Props.keySet({
	"Position",
	"Size",
	"ZIndex",
})

local function LayerCollectorPortal(props: LayerCollectorPortalProps)
	local ownedProps, forwardProps, children = Props.extract(props :: any, OWNED_KEY_SET)
	local instanceToFindAncestor = source(nil :: Instance?)
	local gui2d = source(nil :: GuiBase2d?)
	local layerCollector = source(nil :: LayerCollector?)

	effect(function()
		local target = instanceToFindAncestor()
		if target == nil then
			layerCollector(nil)
			gui2d(nil)
			return
		end

		layerCollector(target:FindFirstAncestorWhichIsA("LayerCollector"))
		gui2d(target:FindFirstAncestorWhichIsA("GuiBase2d"))
	end)

	local size = source(UDim2.new())
	local position = source(UDim2.new())
	local propSize = ownedProps.Size or UDim2.new()
	local propPosition = ownedProps.Position or UDim2.new()

	effect(function()
		local currentLayerCollector = layerCollector()
		local currentGui = gui2d()

		if currentLayerCollector == nil or currentGui == nil then
			size(UDim2.new())
			position(UDim2.new())
			return
		end

		local function update()
			local currentSize = currentGui.AbsoluteSize
			local currentPosition = currentGui.AbsolutePosition
				- currentLayerCollector.AbsolutePosition
			size(
				UDim2.fromOffset(
					currentSize.X * propSize.X.Scale + propSize.X.Offset,
					currentSize.Y * propSize.Y.Scale + propSize.Y.Offset
				)
			)
			position(
				UDim2.fromOffset(
					currentPosition.X + currentSize.X * propPosition.X.Scale + propPosition.X.Offset,
					currentPosition.Y + currentSize.Y * propPosition.Y.Scale + propPosition.Y.Offset
				)
			)
		end

		update()
		local sizeConn = currentGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(update)
		local positionConn = currentGui:GetPropertyChangedSignal("AbsolutePosition"):Connect(update)

		cleanup(sizeConn)
		cleanup(positionConn)
	end)

	local portalFrameProps: { [any]: any } = {
		Name = "LayerCollectorPortal",
		BackgroundTransparency = 1,
		Size = function()
			return size()
		end,
		Position = function()
			return position()
		end,
		ZIndex = ownedProps.ZIndex,
		Parent = function()
			return layerCollector()
		end,
	}
	for key, value in forwardProps do
		portalFrameProps[key] = value
	end
	Props.appendChildren(portalFrameProps, children)

	return create "Folder" {
		ref = function(inst)
			instanceToFindAncestor(inst)
		end,
		Name = "LayerCollectorPortal",
		PortalFrame = create "Frame"(portalFrameProps),
	}
end

return LayerCollectorPortal
