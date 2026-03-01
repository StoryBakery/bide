local PluginGuiService = game:GetService("PluginGuiService")
local RunService = game:GetService("RunService")

local DynamicTimer = require("../../roblox_packages/DynamicTimer") :: any
local ExtendedTranslator = require("../../roblox_packages/ExtendedTranslator") :: any
local UILabs = require("../../roblox_packages/ui-labs") :: any
local UserInputManager = require("../../roblox_packages/UserInputManager") :: any
local vide = require("../vide")

local defaultUserInputManager = UserInputManager.GlobalUserInputManager :: any
if RunService:IsStudio() and UILabs.Environment.IsStory() then
	pcall(function()
		for i, pluginGui in PluginGuiService:GetChildren() do
			pcall(function()
				for j, frame in pluginGui:GetChildren() do
					if frame:IsA("GuiObject") then
						defaultUserInputManager:AddHost(frame)
					end
				end
			end)
		end
	end)
	local janitor = UILabs.Environment.GetJanitor()
	if janitor then
		janitor:Add(function()
			defaultUserInputManager:Destroy()
			UserInputManager.ClearEveryGlobalHosts()
		end)
	end
end

local area = vide.context({
	ResolutionScale = 1 :: number,
	UserInputManager = defaultUserInputManager,
	Translator = ExtendedTranslator.new({
		LocalizationTables = {},
	}),
	Timer = DynamicTimer.UITimer,
})

return area

