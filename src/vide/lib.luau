local version = { major = 0, minor = 0, patch = 0 }

local apply = require("./apply")
local batch = require("./batch")
local cleanup_module = require("./cleanup")
local context_module = require("./context")
local create = require("./create")
local derive_module = require("./derive")
local effect_module = require("./effect")
local indexes = require("./indexes")
local mount_module = require("./mount")
local read = require("./read")
local resource_module = require("./resource")
local root_module = require("./root")
local signal_module = require("./signal")
local show = require("./show")
local switch = require("./switch")
local untrack = require("./untrack")
local values = require("./values")
local spring, update_springs = require("./spring")()
local action = require("./action")()
local changed = require("./changed")
local _, update_timeouts = require("./timeout")()
local flags = require("./flags")

export type Context<T> = context_module.Context<T>
export type ResourceControl<T, E> = resource_module.ResourceControl<T, E>
export type ResourceState = resource_module.ResourceState

type SignalAccessor<T> = signal_module.SignalAccessor<T>
type SignalSetter<T> = signal_module.SignalSetter<T>
type SignalOptions<T> = signal_module.SignalOptions<T>

local warnedDeprecatedApis = {} :: { [string]: boolean }

local function warnDeprecation(apiName: string, replacementName: string)
	if warnedDeprecatedApis[apiName] then
		return
	end

	warnedDeprecatedApis[apiName] = true

	local message =
		`[vide] "{apiName}" is deprecated and will be removed in a future release. Use "{replacementName}" instead.`

	if type(warn) == "function" then
		warn(message)
	else
		print(message)
	end
end

local function signal<T>(
	initialValue: T,
	options: SignalOptions<T>?
): (SignalAccessor<T>, SignalSetter<T>)
	return signal_module(initialValue, options)
end

local function context<T>(...: T): Context<T>
	return context_module(...)
end

local function effect(callback: () -> (), initialValue: any?)
	return effect_module(callback, initialValue)
end

local function memo<T>(callback: () -> T): () -> T
	return derive_module(callback)
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

local function onCleanup(value: unknown)
	return cleanup(value)
end

local function root<T...>(fn: (destroy: () -> ()) -> T...): T...
	return root_module(fn)
end

local function mount<T>(component: () -> T, target: Instance?): () -> ()
	return mount_module(component, target)
end

local function render<T>(component: () -> T, target: Instance?): () -> ()
	return mount(component, target)
end

local function derive<T>(callback: () -> T): () -> T
	warnDeprecation("vide.derive", "vide.memo")
	return derive_module(callback)
end

local function step(dt: number)
	if game then
		debug.profilebegin("VIDE STEP")
	end

	if game then
		debug.profilebegin("VIDE SPRING")
	end
	update_springs(dt)
	if game then
		debug.profileend()
	end

	if game then
		debug.profilebegin("VIDE SCHEDULER")
	end
	update_timeouts(dt)
	if game then
		debug.profileend()
	end

	if game then
		debug.profileend()
	end
end

local stepped: RBXScriptConnection? = if game
	then game:GetService("RunService").Heartbeat:Connect(function(dt: number)
		task.defer(step, dt)
	end)
	else nil

local vide = {
	version = version,

	-- core
	create = create,
	effect = effect,
	memo = memo,
	mount = mount,
	render = render,
	resource = resource,
	root = root,
	signal = signal,
	context = context,
	cleanup = cleanup,
	onCleanup = onCleanup,

	-- deprecated
	derive = derive,

	-- dynamic scopes
	switch = switch,
	show = show,
	indexes = indexes,
	values = values,

	-- util
	untrack = untrack,
	read = read,
	batch = batch,

	-- animations
	spring = spring,

	-- actions
	action = action,
	changed = changed,

	-- flags
	strict = (nil :: any) :: boolean,
	defaults = (nil :: any) :: boolean,
	defer_nested_properties = (nil :: any) :: boolean,

	-- temporary
	apply = function(instance: Instance)
		return function(props: { [any]: any })
			apply(instance, props)
			return instance
		end
	end,

	-- runtime
	step = function(dt: number)
		if stepped then
			stepped:Disconnect()
			stepped = nil
		end
		step(dt)
	end,
}

setmetatable(vide :: any, {
	__index = function(_, index: unknown)
		if (flags :: any)[index] == nil then
			error(`{tostring(index)} is not a valid member of vide`, 0)
		else
			return (flags :: any)[index]
		end
	end,

	__newindex = function(_, index: unknown, value: unknown)
		if (flags :: any)[index] == nil then
			error(`{tostring(index)} is not a valid member of vide`, 0)
		else
			(flags :: any)[index] = value
		end
	end,
})

return vide
