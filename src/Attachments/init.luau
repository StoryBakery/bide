--[[
	Attachments 묶음 모듈입니다.
]]

export type Attachment<T> = (instance: T) -> unknown

local changedModule: any
local clickableModule: any
local dragAxisModule: any
local highlightModule: any
local hoverDelayModule: any
local pressScaleModule: any
local rippleModule: any
local tooltipModule: any

local function Changed(...)
	if changedModule == nil then
		changedModule = require("@self/Changed")
	end

	return changedModule(...)
end

local function Clickable(...)
	if clickableModule == nil then
		clickableModule = require("@self/Clickable")
	end

	return clickableModule(...)
end

local function DragAxis(...)
	if dragAxisModule == nil then
		dragAxisModule = require("@self/DragAxis")
	end

	return dragAxisModule(...)
end

local function Highlight(...)
	if highlightModule == nil then
		highlightModule = require("@self/Highlight")
	end

	return highlightModule(...)
end

local function HoverDelay(...)
	if hoverDelayModule == nil then
		hoverDelayModule = require("@self/HoverDelay")
	end

	return hoverDelayModule(...)
end

local function PressScale(...)
	if pressScaleModule == nil then
		pressScaleModule = require("@self/PressScale")
	end

	return pressScaleModule(...)
end

local function Ripple(...)
	if rippleModule == nil then
		rippleModule = require("@self/Ripple")
	end

	return rippleModule(...)
end

local function Tooltip(...)
	if tooltipModule == nil then
		tooltipModule = require("@self/Tooltip")
	end

	return tooltipModule(...)
end

return {
	Changed = Changed,
	Clickable = Clickable,
	DragAxis = DragAxis,
	Highlight = Highlight,
	HoverDelay = HoverDelay,
	PressScale = PressScale,
	Ripple = Ripple,
	Tooltip = Tooltip,
}
