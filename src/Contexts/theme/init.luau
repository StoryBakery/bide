local reactive = require("../Reactive")

local Dark = require("@self/BuiltInThemes/Dark")
local DeepGrey = require("@self/BuiltInThemes/DeepGrey")
local Light = require("@self/BuiltInThemes/Light")

type ThemeName = "Dark" | "DeepGrey" | "Light"
type ThemeValue = typeof(Dark)
type ThemeAccessor = () -> ThemeValue
type ThemeSetter = (ThemeValue | ((ThemeValue) -> ThemeValue)) -> ThemeValue

local BUILT_IN_THEMES = table.freeze({
	Dark = Dark,
	DeepGrey = DeepGrey,
	Light = Light,
})

local function getDefaultTheme(): ThemeValue
	return BUILT_IN_THEMES.Dark
end

local function setDefaultTheme(_: ThemeValue | ((ThemeValue) -> ThemeValue)): ThemeValue
	return BUILT_IN_THEMES.Dark
end

local DEFAULT_THEME_CONTEXT_VALUE = {
	Get = getDefaultTheme,
	Set = setDefaultTheme,
}

local Theme = reactive.createContext(DEFAULT_THEME_CONTEXT_VALUE)

function Theme.CreateValue(initialTheme: ThemeValue?)
	local getTheme, setTheme = reactive.signal(initialTheme or BUILT_IN_THEMES.Dark)

	return {
		Get = getTheme,
		Set = setTheme,
	}
end

Theme.BUILT_IN_THEMES = BUILT_IN_THEMES

return Theme
