--[=[
	@class bide
	bide UI 라이브러리 메인 진입점입니다.

	```luau
	local bide = require("bide")

	bide.Components.Button({ Text = "확인", OnClick = fn })
	bide.Core.Interactive({
		bide.Behaviors.Highlight(), 
		bide.Behaviors.Clickable({ OnClick = fn }) 
	})
	bide.Core.Element({ Class = "Frame", Size = ... })
	```
]=]

local vide = require("@self/vide")

local Core = require("@self/Core")

local Behaviors = require("@self/Behaviors")
local Components = require("@self/Components")
local Layout = require("@self/Layout")

local Modifier = require("@self/Modifier")

local Props = require("@self/Utils/Props")

local bide = {
	Core = Core,

	Behaviors = Behaviors,
	Components = Components,
	Layout = Layout,

	Modifier = Modifier,
	Props = Props,
}

return bide
