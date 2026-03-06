--[=[
	@class LayerCollectorPortal

	LayerCollector 기준으로 포탈을 생성하는 컴포넌트입니다.
]=]

local Instance = require("../Instance")
local reactive = require("../Reactive")

local Props = require("../Utils/Props")

local create = Instance.create
local effect = reactive.effect
local signal = reactive.signal
local cleanup = reactive.cleanup
local read = reactive.read

local OWN_PROPS_SCHEMA = {
	Position = Props.optional<<UDim2>>(),
	Size = Props.optional<<UDim2>>(),
	ZIndex = Props.optional<<number>>(),
}

export type LayerCollectorPortalOwnProps = typeof(OWN_PROPS_SCHEMA)

export type LayerCollectorPortalProps = LayerCollectorPortalOwnProps

local function LayerCollectorPortal(props: LayerCollectorPortalProps)
	local ownProps, forwardProps, children = Props.splitProps(props :: any, OWN_PROPS_SCHEMA)
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

	effect(function()
		local currentLayerCollector = layerCollector()
		local currentGui = gui2d()
		local propSize = (read(ownProps.Size) :: UDim2?) or UDim2.new()
		local propPosition = (read(ownProps.Position) :: UDim2?) or UDim2.new()

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
		ZIndex = ownProps.ZIndex,
		Parent = function()
			return layerCollector()
		end,
	}
	for key, value in forwardProps do
		portalFrameProps[key] = value
	end
	if #children > 0 then
		table.move(children, 1, #children, #portalFrameProps + 1, portalFrameProps)
	end

	return create "Folder" {
		ref = function(inst)
			setInstanceToFindAncestor(inst)
		end,
		Name = "LayerCollectorPortal",
		PortalFrame = create "Frame"(portalFrameProps),
	}
end

return LayerCollectorPortal
