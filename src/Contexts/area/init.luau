local PluginGuiService = game:GetService("PluginGuiService")
local RunService = game:GetService("RunService")

local DynamicTimer = require("../../roblox_packages/DynamicTimer")
local ExtendedTranslator = require("../../roblox_packages/ExtendedTranslator")
local UILabs = require("../../roblox_packages/ui-labs")
local UserInputManager = require("../../roblox_packages/UserInputManager")

local reactive = require("../Reactive")

local defaultUserInputManager = UserInputManager.GlobalUserInputManager
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

local DEFAULT_AREA_VALUE = table.freeze({
	UserInputManager = defaultUserInputManager,
	Translator = ExtendedTranslator.new({
		LocalizationTables = {},
	}),
	Timer = DynamicTimer.UITimer,
})

local Area = reactive.createContext(DEFAULT_AREA_VALUE)

return Area
