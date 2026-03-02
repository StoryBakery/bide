--[=[
	@class LayerCollectorPortal

	LayerCollector 기준으로 포탈을 생성하는 컴포넌트입니다.
]=]

local vide = require("../vide")

local Props = require("../Utils/Props")

local create = vide.create
local effect = vide.effect
local signal = vide.signal
local onCleanup = vide.onCleanup

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
	local instanceToFindAncestor, setInstanceToFindAncestor = signal(nil :: Instance?)
	local gui2d, setGui2d = signal(nil :: GuiBase2d?)
	local layerCollector, setLayerCollector = signal(nil :: LayerCollector?)

	effect(function()
		local target = instanceToFindAncestor()
		if target == nil then
			setLayerCollector(nil)
			setGui2d(nil)
			return
		end

		setLayerCollector(target:FindFirstAncestorWhichIsA("LayerCollector"))
		setGui2d(target:FindFirstAncestorWhichIsA("GuiBase2d"))
	end)

	local size, setSize = signal(UDim2.new())
	local position, setPosition = signal(UDim2.new())
	local propSize = ownedProps.Size or UDim2.new()
	local propPosition = ownedProps.Position or UDim2.new()

	effect(function()
		local currentLayerCollector = layerCollector()
		local currentGui = gui2d()

		if currentLayerCollector == nil or currentGui == nil then
			setSize(UDim2.new())
			setPosition(UDim2.new())
			return
		end

		local function update()
			local currentSize = currentGui.AbsoluteSize
			local currentPosition = currentGui.AbsolutePosition
				- currentLayerCollector.AbsolutePosition
			setSize(
				UDim2.fromOffset(
					currentSize.X * propSize.X.Scale + propSize.X.Offset,
					currentSize.Y * propSize.Y.Scale + propSize.Y.Offset
				)
			)
			setPosition(
				UDim2.fromOffset(
					currentPosition.X + currentSize.X * propPosition.X.Scale + propPosition.X.Offset,
					currentPosition.Y + currentSize.Y * propPosition.Y.Scale + propPosition.Y.Offset
				)
			)
		end

		update()
		local sizeConn = currentGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(update)
		local positionConn = currentGui:GetPropertyChangedSignal("AbsolutePosition"):Connect(update)

		onCleanup(sizeConn)
		onCleanup(positionConn)
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
			setInstanceToFindAncestor(inst)
		end,
		Name = "LayerCollectorPortal",
		PortalFrame = create "Frame"(portalFrameProps),
	}
end

return LayerCollectorPortal
