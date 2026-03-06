--[=[
	@class bide
	bide UI 라이브러리 메인 진입점입니다.

	```luau
	local bide = require("bide")

	bide.Components.Button({ Text = "확인", OnClick = fn })
	bide.Components.Frame({
		Attach = {
			bide.Attachments.Highlight(),
			bide.Attachments.Clickable({ OnClick = fn }),
		},
	})
	bide.Components.Frame({ Size = ... })
	```
]=]

local Attachments = require("@self/Attachments")
local Components = require("@self/Components")
local Contexts = require("@self/Contexts")
local Layout = require("@self/Layout")

local Instance = require("@self/Instance")
local Renderer = require("@self/Renderer")

local Props = require("@self/Utils/Props")

local bide = {
	Attachments = Attachments,
	Components = Components,
	Contexts = Contexts,
	Layout = Layout,

	Instance = Instance,
	Renderer = Renderer,
	Props = Props,
}

return bide
