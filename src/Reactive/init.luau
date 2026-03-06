local version = { major = 0, minor = 0, patch = 0 }

local batch = require("@self/batch")
local cleanup_module = require("@self/cleanup")
local context_module = require("@self/context")
local derive_module = require("@self/derive")
local effect_module = require("@self/effect")
local indexes = require("@self/indexes")
local read = require("@self/read")
local resource_module = require("@self/resource")
local root_module = require("@self/root")
local show = require("@self/show")
local signal_module = require("@self/signal")
local switch = require("@self/switch")
local untrack = require("@self/untrack")
local values = require("@self/values")
local flags = require("@self/flags")

export type Context<T> = context_module.Context<T>
export type ContextProviderProps<T> = context_module.ContextProviderProps<T>
export type ResourceControl<T, E> = resource_module.ResourceControl<T, E>
export type ResourceState = resource_module.ResourceState

type SignalAccessor<T> = signal_module.SignalAccessor<T>
type SignalSetter<T> = signal_module.SignalSetter<T>
type SignalOptions<T> = signal_module.SignalOptions<T>

local function signal<T>(
	initialValue: T,
	options: SignalOptions<T>?
): (SignalAccessor<T>, SignalSetter<T>)
	return signal_module(initialValue, options)
end

local function createContext<T>(defaultValue: T?): Context<T?>
	return context_module.createContext(defaultValue)
end

local function useContext<T>(context: Context<T>): T
	return context_module.useContext(context)
end

local function effect(callback: () -> ())
	return effect_module(callback)
end

local function memo<T>(
	callback: (T?) -> T,
	initialValue: T?,
	options: derive_module.MemoOptions<T>?
): () -> T
	return derive_module(callback, initialValue, options)
end

local function resource<TSignal, TValue, TError>(
	signalOrFetcher: any,
	fetcherOrOptions: any?,
	optionsOrNil: any?
): (() -> TValue?, ResourceControl<TValue, TError>)
	return resource_module(signalOrFetcher, fetcherOrOptions, optionsOrNil)
end

local function cleanup(value: unknown)
	return cleanup_module(value)
end

local function root<T...>(fn: (destroy: () -> ()) -> T...): T...
	return root_module(fn)
end

local reactive = {
	version = version,

	-- core
	effect = effect,
	memo = memo,
	resource = resource,
	root = root,
	signal = signal,
	createContext = createContext,
	useContext = useContext,
	cleanup = cleanup,

	-- dynamic scopes
	switch = switch,
	show = show,
	indexes = indexes,
	values = values,

	-- util
	untrack = untrack,
	read = read,
	batch = batch,

	-- flags
	strict = (nil :: any) :: boolean,
	defaults = (nil :: any) :: boolean,
	defer_nested_properties = (nil :: any) :: boolean,
}

setmetatable(reactive :: any, {
	__index = function(_, index: unknown)
		if (flags :: any)[index] == nil then
			error(`{tostring(index)} is not a valid member of reactive`, 0)
		else
			return (flags :: any)[index]
		end
	end,

	__newindex = function(_, index: unknown, value: unknown)
		if (flags :: any)[index] == nil then
			error(`{tostring(index)} is not a valid member of reactive`, 0)
		else
			(flags :: any)[index] = value
		end
	end,
})

return reactive
