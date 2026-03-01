--[[
	Behaviors 묶음 모듈입니다.
]]

local Clickable = require("@self/Clickable")
local DragAxis = require("@self/DragAxis")
local Highlight = require("@self/Highlight")
local HoverDelay = require("@self/HoverDelay")
local PressScale = require("@self/PressScale")
local Ripple = require("@self/Ripple")
local Tooltip = require("@self/Tooltip")

return {
	Clickable = Clickable,
	DragAxis = DragAxis,
	Highlight = Highlight,
	HoverDelay = HoverDelay,
	PressScale = PressScale,
	Ripple = Ripple,
	Tooltip = Tooltip,
}
