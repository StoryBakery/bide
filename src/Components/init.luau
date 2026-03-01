--[=[
	Components 묶음 모듈입니다.
]=]

local AnimationFrame = require("@self/AnimationFrame")
local Button = require("@self/Button")
local CircularFrame = require("@self/CircularFrame")
local Frame = require("@self/Frame")
local ImageLabel = require("@self/ImageLabel")
local Portal = require("@self/Portal")
local ScrollingFrame = require("@self/ScrollingFrame")
local TextLabel = require("@self/TextLabel")

-- 폴더 기반 컴포넌트 (서브모듈 보유)
local CullingListFrame = require("@self/CullingListFrame")
local PageStepper = require("@self/PageStepper")

return {
	AnimationFrame = AnimationFrame,
	Button = Button,
	CircularFrame = CircularFrame,
	CullingListFrame = CullingListFrame,
	Frame = Frame,
	ImageLabel = ImageLabel,
	PageStepper = PageStepper,
	Portal = Portal,
	ScrollingFrame = ScrollingFrame,
	TextLabel = TextLabel,
}
