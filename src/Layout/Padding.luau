--[=[
	@class Padding

	UIPadding 래퍼입니다.
]=]

local reactive = require("../Reactive")
local Instance = require("../Instance")

local create = Instance.create
local read = reactive.read

type Prop<T> = T | (() -> T)

export type PaddingProps = {
	Padding: Prop<number>?,
	PaddingLeft: Prop<UDim | number>?,
	PaddingRight: Prop<UDim | number>?,
	PaddingTop: Prop<UDim | number>?,
	PaddingBottom: Prop<UDim | number>?,
}

local function toUDim(value: UDim | number | nil, fallback: number?): UDim
	if value == nil then
		return UDim.new(0, fallback or 0)
	end
	if typeof(value) == "UDim" then
		return value
	end
	return UDim.new(0, value :: number)
end

local function Padding(props: PaddingProps?): Instance
	local p = props or {} :: PaddingProps
	local defaultPadding = read(p.Padding) :: number?

	return create "UIPadding" {
		PaddingLeft = function()
			return toUDim(read(p.PaddingLeft), defaultPadding)
		end,
		PaddingRight = function()
			return toUDim(read(p.PaddingRight), defaultPadding)
		end,
		PaddingTop = function()
			return toUDim(read(p.PaddingTop), defaultPadding)
		end,
		PaddingBottom = function()
			return toUDim(read(p.PaddingBottom), defaultPadding)
		end,
	}
end

return Padding
